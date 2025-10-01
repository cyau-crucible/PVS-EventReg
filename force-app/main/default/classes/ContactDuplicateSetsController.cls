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
        @AuraEnabled public List<Id> duplicateContactIds; // NOW includes the anchor Contact FIRST
    }
    public class DuplicateSetsResponse {
        @AuraEnabled public List<DuplicateSetDTO> sets;
        @AuraEnabled public Integer totalSets;
    }

    // -------- NEW: Universal Wrappers --------
    
    // Wrapper for a single field's data across master and target records
    public class UniversalFieldData {
        @AuraEnabled public String fieldName { get; set; }
        @AuraEnabled public String fieldLabel { get; set; }
        @AuraEnabled public String fieldType { get; set; }
        @AuraEnabled public Boolean isUpdateable { get; set; }
        @AuraEnabled public String masterValue { get; set; }  // String representation
        @AuraEnabled public String targetValue { get; set; }  // String representation
        
        public UniversalFieldData(String fieldName, String fieldLabel, String fieldType, 
                                 Boolean isUpdateable, String masterValue, String targetValue) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
            this.isUpdateable = isUpdateable;
            this.masterValue = masterValue != null ? masterValue : '';
            this.targetValue = targetValue != null ? targetValue : '';
        }
    }
    
    // Wrapper for comparison data between two records
    public class UniversalRecordComparison {
        @AuraEnabled public Id masterId { get; set; }
        @AuraEnabled public Id targetId { get; set; }
        @AuraEnabled public String masterName { get; set; }
        @AuraEnabled public String targetName { get; set; }
        @AuraEnabled public String objectType { get; set; }  // 'Contact' or 'Lead'
        @AuraEnabled public List<UniversalFieldData> fields { get; set; }
        
        public UniversalRecordComparison(Id masterId, Id targetId, String masterName, 
                                        String targetName, String objectType) {
            this.masterId = masterId;
            this.targetId = targetId;
            this.masterName = masterName;
            this.targetName = targetName;
            this.objectType = objectType;
            this.fields = new List<UniversalFieldData>();
        }
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
            // Add the current record (master) as the FIRST element
            dto.duplicateContactIds.add(contactId);
            setIdToDto.put(dto.setId, dto);
        }

        // 2) For each DRS, find the *other* items (the duplicates) - they come AFTER the master
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
        for (DuplicateSetDTO d : ordered) d.totalItems = d.duplicateContactIds == null ? 0 : d.duplicateContactIds.size();
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

        // Find this contact's linkage
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

    // New Code to handle Merges
    // Returns a list of Wrappers of Field Information from Field Set specified
    // Modify to look for read-only status on Fields   
    @AuraEnabled(cacheable=true)
    public static List<FieldInfo> getFieldSetFields(String fieldSetName, String objectName) {
        List<FieldInfo> fieldInfoList = new List<FieldInfo>();
        
        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
            if (sObjectType == null) {
                throw new AuraHandledException('Invalid object type: ' + objectName);
            }
            
            Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
            
            // Test handling (keep as is)
            if (Test.isRunningTest() && fieldSetName == 'TestFieldSet' && objectName == 'Contact') {
                fieldInfoList.add(new FieldInfo('LastName', 'Last Name', 'STRING', true));
                fieldInfoList.add(new FieldInfo('Email', 'Email', 'EMAIL', true));
                return fieldInfoList;
            }
            
            Schema.FieldSet fieldSet = sObjectType.getDescribe().fieldSets.getMap().get(fieldSetName);
            if (fieldSet == null) {
                fieldSet = sObjectType.getDescribe().fieldSets.getMap().get('c__' + fieldSetName);
                if (fieldSet == null) {
                    throw new AuraHandledException('Field Set not found: ' + fieldSetName);
                }
            }
            
            // Extract field information WITH updateability check
            for (Schema.FieldSetMember fieldMember : fieldSet.getFields()) {
                String fieldPath = fieldMember.getFieldPath();
                Schema.SObjectField fieldToken = fieldMap.get(fieldPath);
                Boolean isUpdateable = false;
                
                if (fieldToken != null) {
                    Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
                    isUpdateable = fieldDescribe.isUpdateable();
                }
                
                fieldInfoList.add(new FieldInfo(
                    fieldPath,
                    fieldMember.getLabel(),
                    String.valueOf(fieldMember.getType()),
                    isUpdateable
                ));
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving Field Set: ' + e.getMessage());
        }
        
        return fieldInfoList;
    }  // end getFieldSetFields

    // NEW: Universal method to retrieve record comparison data
    @AuraEnabled(cacheable=false)
    public static UniversalRecordComparison getRecordComparison(
        Id masterId, 
        Id targetId, 
        String fieldSetName,
        String objectType
    ) {
        try {
            // Validate inputs
            if (masterId == null || targetId == null) {
                throw new AuraHandledException('Both Master and Target record IDs are required');
            }
            if (masterId == targetId) {
                throw new AuraHandledException('Master and Target records cannot be the same');
            }
            
            // Get field set information
            List<FieldInfo> fieldInfoList = getFieldSetFields(fieldSetName, objectType);
            if (fieldInfoList.isEmpty()) {
                throw new AuraHandledException('No fields found in Field Set: ' + fieldSetName);
            }
            
            // Build dynamic SOQL query
            Set<String> fieldsToQuery = new Set<String>{'Id', 'Name'};
            for (FieldInfo fi : fieldInfoList) {
                fieldsToQuery.add(fi.fieldName);
            }
            
            String query = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ') + 
                          ' FROM ' + objectType + ' WHERE Id IN :recordIds';
            
            Set<Id> recordIds = new Set<Id>{masterId, targetId};
            List<SObject> records = Database.query(query);
            
            // Organize records
            SObject masterRecord = null;
            SObject targetRecord = null;
            
            for (SObject rec : records) {
                if (rec.Id == masterId) {
                    masterRecord = rec;
                } else if (rec.Id == targetId) {
                    targetRecord = rec;
                }
            }
            
            // Verify both records were found
            if (masterRecord == null) {
                throw new AuraHandledException('Master record not found: ' + masterId);
            }
            if (targetRecord == null) {
                throw new AuraHandledException('Target record not found: ' + targetId);
            }
            
            // Build comparison wrapper
            String masterName = (String)masterRecord.get('Name');
            String targetName = (String)targetRecord.get('Name');
            
            UniversalRecordComparison comparison = new UniversalRecordComparison(
                masterId, targetId, masterName, targetName, objectType
            );
            
            // Add field data
            for (FieldInfo fi : fieldInfoList) {
                Object masterValue = masterRecord.get(fi.fieldName);
                Object targetValue = targetRecord.get(fi.fieldName);
                
                String masterDisplay = formatFieldValue(masterValue, fi.fieldType);
                String targetDisplay = formatFieldValue(targetValue, fi.fieldType);
                
                UniversalFieldData fieldData = new UniversalFieldData(
                    fi.fieldName,
                    fi.fieldLabel,
                    fi.fieldType,
                    fi.isUpdateable,
                    masterDisplay,
                    targetDisplay
                );
                
                comparison.fields.add(fieldData);
            }
            
            return comparison;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving record comparison: ' + e.getMessage());
        }
    }
    
    // Helper to format field values as strings for display
    private static String formatFieldValue(Object value, String fieldType) {
        if (value == null) {
            return '';
        }
        
        // Handle different field types
        if (fieldType == 'BOOLEAN') {
            return String.valueOf(value);
        } else if (fieldType == 'DATE') {
            Date dateValue = (Date)value;
            return dateValue.format();
        } else if (fieldType == 'DATETIME') {
            Datetime dtValue = (Datetime)value;
            return dtValue.format();
        } else if (fieldType == 'CURRENCY' || fieldType == 'DOUBLE' || fieldType == 'PERCENT') {
            return String.valueOf(value);
        } else {
            return String.valueOf(value);
        }
    }

    // Method to retrieve Contact Wrapper of both requested Contacts, with the requested Field Names queried
    @AuraEnabled(cacheable=false)
    public static ContactWrapper getContactsWithFieldValues(Id masterId, Id targetId, List<String> fieldNames) {
        try {
            // Validate inputs
            if (masterId == null || targetId == null) {
                throw new AuraHandledException('Both Master and Target Contact IDs are required');
            }
            
            if (masterId == targetId) {
                throw new AuraHandledException('Master and Target contacts cannot be the same');
            }
            
            // Build dynamic SOQL query
            Set<String> fieldsToQuery = new Set<String>{'Id', 'Name'};
            if (fieldNames != null && !fieldNames.isEmpty()) {
                for (String field : fieldNames) {
                    // Clean and validate field names
                    String cleanField = String.escapeSingleQuotes(field.trim());
                    fieldsToQuery.add(cleanField);
                }
            }
            
            String query = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ') + 
                          ' FROM Contact WHERE Id IN :contactIds WITH SECURITY_ENFORCED';
            
            Set<Id> contactIds = new Set<Id>{masterId, targetId};
            List<Contact> contacts = Database.query(query);
            
            // Organize contacts
            Contact masterContact = null;
            Contact targetContact = null;
            
            for (Contact c : contacts) {
                if (c.Id == masterId) {
                    masterContact = c;
                } else if (c.Id == targetId) {
                    targetContact = c;
                }
            }
            
            // Verify both contacts were found
            if (masterContact == null) {
                throw new AuraHandledException('Master Contact not found: ' + masterId);
            }
            if (targetContact == null) {
                throw new AuraHandledException('Target Contact not found: ' + targetId);
            }
            
            return new ContactWrapper(masterContact, targetContact);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving contacts: ' + e.getMessage());
        }
    }  // end getContactsWithFieldValues
    
    // Merge Contact records with custom field precedence
    // Will use Apex merge to default to "Master" passed in, unless specified otherwise in the fieldSelections map
    @AuraEnabled
    public static MergeResult mergeContactsNew(Id masterId, Id targetId, Map<String, String> fieldSelections) {
        Savepoint sp = Database.setSavepoint();
        
        try {
            // Validate inputs
            if (masterId == null || targetId == null) {
                throw new AuraHandledException('Both Master and Target Contact IDs are required');
            }
            
            if (masterId == targetId) {
                throw new AuraHandledException('Master and Target contacts cannot be the same');
            }
            
            // Build list of fields to query
            Set<String> fieldsToQuery = new Set<String>{'Id'};
            if (fieldSelections != null && !fieldSelections.isEmpty()) {
                fieldsToQuery.addAll(fieldSelections.keySet());
            }
            
            // Query both contacts
            String query = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ') + 
                          ' FROM Contact WHERE Id = :masterId OR Id = :targetId';
            
            List<Contact> contacts = Database.query(query);
            
            Contact masterContact = null;
            Contact targetContact = null;
            
            for (Contact c : contacts) {
                if (c.Id == masterId) {
                    masterContact = c;
                } else if (c.Id == targetId) {
                    targetContact = c;
                }
            }
            
            // Verify both contacts exist
            if (masterContact == null) {
                throw new AuraHandledException('Master Contact not found');
            }
            if (targetContact == null) {
                throw new AuraHandledException('Target Contact not found');
            }
            
            // Apply field selections before merge
            if (fieldSelections != null && !fieldSelections.isEmpty()) {
                for (String fieldName : fieldSelections.keySet()) {
                    String selection = fieldSelections.get(fieldName);
                    
                    // If user selected target value, update master with target's value
                    if ('target'.equalsIgnoreCase(selection)) {
                        try {
                            Object targetValue = targetContact.get(fieldName);
                            masterContact.put(fieldName, targetValue);
                        } catch (Exception e) {
                            System.debug('Error setting field ' + fieldName + ': ' + e.getMessage());
                            // Continue with other fields even if one fails
                        }
                    }
                    // If 'master' is selected, no action needed as master keeps its value
                }
                
                // Update master contact with selected field values
                update masterContact;
            }
            
            // Perform the merge
            Database.merge(masterContact, targetContact);
            
            return new MergeResult(
                true, 
                'Contacts merged successfully', 
                masterContact.Id
            );
            
        } catch (DmlException e) {
            Database.rollback(sp);
            String errorMessage = 'Merge failed: ' + e.getDmlMessage(0);
            return new MergeResult(false, errorMessage, null);
        } catch (Exception e) {
            Database.rollback(sp);
            return new MergeResult(false, 'Merge failed: ' + e.getMessage(), null);
        }
    }   // end mergeContacts
    
    // Validate if current user has necessary permissions
    @AuraEnabled(cacheable=true)
    public static Boolean validateUserPermissions() {
        try {
            // Check if user can delete contacts (required for merge)
            Boolean canDelete = Schema.sObjectType.Contact.isDeletable();
            
            // Check if user can update contacts
            Boolean canUpdate = Schema.sObjectType.Contact.isUpdateable();
            
            // Check if user can access contacts
            Boolean canAccess = Schema.sObjectType.Contact.isAccessible();
            
            return canDelete && canUpdate && canAccess;
            
        } catch (Exception e) {
            return false;
        }
    }  // end validateUserPermissions


    // Wrapper Classes for Merging
    // Wrapper class for field metadata
    public class FieldInfo {
        @AuraEnabled public String fieldName { get; set; }
        @AuraEnabled public String fieldLabel { get; set; }
        @AuraEnabled public String fieldType { get; set; }
        @AuraEnabled public Boolean isUpdateable { get; set; }
        
        public FieldInfo(String fieldName, String fieldLabel, String fieldType, Boolean isUpdateable) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
            this.isUpdateable = isUpdateable;
        }
    }   // end FieldInfo
    
    // Wrapper class for Contact records with field values
    public class ContactWrapper {
        @AuraEnabled public Contact masterContact { get; set; }
        @AuraEnabled public Contact targetContact { get; set; }
        
        public ContactWrapper(Contact master, Contact target) {
            this.masterContact = master;
            this.targetContact = target;
        }
    }    // end ContactWrapper
    
    // Wrapper class for merge result
    public class MergeResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Id mergedContactId { get; set; }
        
        public MergeResult(Boolean success, String message, Id mergedContactId) {
            this.success = success;
            this.message = message;
            this.mergedContactId = mergedContactId;
        }
    }    // end MergeResult
}