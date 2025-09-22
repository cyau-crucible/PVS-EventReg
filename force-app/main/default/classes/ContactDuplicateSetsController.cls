public with sharing class ContactDuplicateSetsController {
 // -------- DTOs returned to LWC --------
    public class FieldDescriptor {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String dataType;
        @AuraEnabled public Boolean updateable;
        @AuraEnabled public Boolean createable;
    }
    public class DuplicateSetDTO {
        @AuraEnabled public Id setId;
        @AuraEnabled public String ruleDeveloperName;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public Integer totalItems;          // includes the anchor Contact
        @AuraEnabled public List<Id> duplicateContactIds; // excludes the anchor Contact
    }
    public class DuplicateSetsResponse {
        @AuraEnabled public List<DuplicateSetDTO> sets;
        @AuraEnabled public Integer totalSets;
    }

    // -------- Public API --------

    /**
     * Returns Duplicate Record Sets that include the given Contact.
     * Uses only IDs and metadata; LWC uses LDS to render records.
     */
    @AuraEnabled(cacheable=true)
    public static DuplicateSetsResponse getDuplicateSets(Id contactId, Integer maxSets) {
        DuplicateSetsResponse resp = new DuplicateSetsResponse();
        resp.sets = new List<DuplicateSetDTO>();
        resp.totalSets = 0;

        if (contactId == null) return resp;
        if (maxSets == null || maxSets <= 0) maxSets = 50;

        // 1) Find the DRS rows for the anchor record
        List<DuplicateRecordItem> anchorItems = [
            SELECT Id, DuplicateRecordSetId,
                   DuplicateRecordSet.CreatedDate,
                   DuplicateRecordSet.DuplicateRule.DeveloperName
            FROM DuplicateRecordItem
            WHERE RecordId = :contactId
            ORDER BY DuplicateRecordSet.CreatedDate DESC
            LIMIT :maxSets
        ];
        if (anchorItems.isEmpty()) return resp;

        // Assemble map of DRS → DTO
        Map<Id, DuplicateSetDTO> setIdToDto = new Map<Id, DuplicateSetDTO>();
        Set<Id> setIds = new Set<Id>();
        for (DuplicateRecordItem dri : anchorItems) {
            setIds.add(dri.DuplicateRecordSetId);
            DuplicateSetDTO dto = new DuplicateSetDTO();
            dto.setId = dri.DuplicateRecordSetId;
            dto.createdDate = (dri.DuplicateRecordSet != null) ? dri.DuplicateRecordSet.CreatedDate : null;
            dto.ruleDeveloperName = (dri.DuplicateRecordSet != null && dri.DuplicateRecordSet.DuplicateRule != null)
                ? dri.DuplicateRecordSet.DuplicateRule.DeveloperName : null;
            dto.duplicateContactIds = new List<Id>();
            setIdToDto.put(dto.setId, dto);
        }

        // 2) For each DRS, find the *other* items (the duplicates)
        for (DuplicateRecordItem item : [
            SELECT Id, RecordId, DuplicateRecordSetId
            FROM DuplicateRecordItem
            WHERE DuplicateRecordSetId IN :setIds
              AND RecordId != :contactId
            ORDER BY DuplicateRecordSetId
        ]) {
            DuplicateSetDTO dto = setIdToDto.get(item.DuplicateRecordSetId);
            if (dto != null) dto.duplicateContactIds.add(item.RecordId);
        }

        // Finalize counts and order (newest first)
        List<DuplicateSetDTO> ordered = new List<DuplicateSetDTO>(setIdToDto.values());
        for (DuplicateSetDTO d : ordered) d.totalItems = 1 + (d.duplicateContactIds == null ? 0 : d.duplicateContactIds.size());
        ordered.sort(new ComparatorDTO());

        resp.sets = ordered;
        resp.totalSets = ordered.size();
        return resp;
    }

    private class ComparatorDTO implements System.Comparator<DuplicateSetDTO> {
        public Integer compare(DuplicateSetDTO x, DuplicateSetDTO y) {
            if (x == null && y == null) return 0;
            if (x == null) return 1;
            if (y == null) return -1;
    
            if (x.createdDate == null && y.createdDate == null) return 0;
            if (x.createdDate == null) return 1;
            if (y.createdDate == null) return -1;
    
            // Newest first
            return (x.createdDate > y.createdDate) ? -1 :
                   (x.createdDate < y.createdDate) ? 1 : 0;
        }
    }


    /**
     * Returns the Contact field set members (fallbacks gracefully if field set is missing).
     * LWC renders these with LDS lightning-output-field.
     */
    @AuraEnabled(cacheable=true)
    public static List<FieldDescriptor> getContactFieldSet(String fieldSetName) {
        if (String.isBlank(fieldSetName)) fieldSetName = 'Duplicate_Review';
        List<FieldDescriptor> result = new List<FieldDescriptor>();

        Schema.DescribeSObjectResult describe = Contact.SObjectType.getDescribe();
        Map<String, Schema.FieldSet> fsMap = describe.fieldSets.getMap();
        Schema.FieldSet fs = fsMap.get(fieldSetName);

        if (fs == null) {
            // Fallback set that usually makes sense for dupe review
            List<String> fallback = new List<String>{
                'Title','Email','Phone','MobilePhone','Department',
                'AccountId','MailingCity','MailingState','OwnerId'
            };
            for (String api : fallback) addFieldDescriptor(describe, api, result);
            return result;
        }

        for (Schema.FieldSetMember m : fs.getFields()) {
            addFieldDescriptor(describe, m.getFieldPath(), result);
        }
        return result;
    }

    // Helper to append a field describe safely
    private static void addFieldDescriptor(Schema.DescribeSObjectResult describe, String api,
                                           List<FieldDescriptor> out) {
        Schema.SObjectField fRef = describe.fields.getMap().get(api);
        if (fRef == null) return;
        Schema.DescribeFieldResult f = fRef.getDescribe();
        FieldDescriptor fd = new FieldDescriptor();
        fd.apiName = api;
        fd.label = f.getLabel();
        fd.dataType = String.valueOf(f.getType());
        fd.updateable = f.isUpdateable();
        fd.createable = f.isCreateable();
        out.add(fd);
    }
    
@AuraEnabled
public static Boolean approveContactFromSet(Id contactId, Id duplicateRecordSetId) {
    if (contactId == null || duplicateRecordSetId == null) {
        throw new AuraHandledException('Missing contact or duplicate set id.');
    }

    // Get all items in the set
    List<DuplicateRecordItem> items = [
        SELECT Id, RecordId
        FROM DuplicateRecordItem
        WHERE DuplicateRecordSetId = :duplicateRecordSetId
        FOR UPDATE
    ];
    if (items.isEmpty()) return true; // nothing to do

    // Find this contact’s linkage
    Id linkId = null;
    for (DuplicateRecordItem i : items) {
        if (i.RecordId == contactId) { linkId = i.Id; break; }
    }
    if (linkId == null) return true; // already approved/removed

    // Remove only this link
    delete new DuplicateRecordItem(Id = linkId);

    // If ≤1 items remain, delete the set (no comparison left to review)
    Integer remaining = items.size() - 1;
    if (remaining <= 1) {
        delete new DuplicateRecordSet(Id = duplicateRecordSetId);
    }
    return true;
}    
}