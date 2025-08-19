// Execute Anonymous script to extract object metadata and sample data
// Run this and copy the debug output to provide the JSON data

Map<String, Object> allData = new Map<String, Object>();

// 1. Get User object fields (focusing on Contact relationship)
Map<String, Object> userFields = new Map<String, Object>();
for (Schema.SObjectField field : Schema.User.SObjectType.getDescribe().fields.getMap().values()) {
    Schema.DescribeFieldResult fieldDesc = field.getDescribe();
    if (fieldDesc.getName().contains('Contact') || fieldDesc.getName() == 'Id') {
        userFields.put(fieldDesc.getName(), new Map<String, Object>{
            'type' => fieldDesc.getType().name(),
            'label' => fieldDesc.getLabel(),
            'required' => !fieldDesc.isNillable()
        });
    }
}
allData.put('User_Fields', userFields);

// 2. Get Contact object fields (especially custom ones referenced)
Map<String, Object> contactFields = new Map<String, Object>();
for (Schema.SObjectField field : Schema.Contact.SObjectType.getDescribe().fields.getMap().values()) {
    Schema.DescribeFieldResult fieldDesc = field.getDescribe();
    String fieldName = fieldDesc.getName();
    // Focus on fields referenced in code plus standard required ones
    if (fieldName.contains('ycadmissions__InitialSchool__c') || 
        fieldName.contains('Caretaker_Status__c') ||
        fieldName == 'AccountId' || fieldName == 'Email' || 
        fieldName == 'FirstName' || fieldName == 'LastName' || 
        fieldName == 'Phone' || fieldName == 'Id') {
        contactFields.put(fieldName, new Map<String, Object>{
            'type' => fieldDesc.getType().name(),
            'label' => fieldDesc.getLabel(),
            'required' => !fieldDesc.isNillable(),
            'referenceTo' => fieldDesc.getReferenceTo()
        });
    }
}
allData.put('Contact_Fields', contactFields);

// 3. Get PVS_Event__c object metadata
Map<String, Object> eventFields = new Map<String, Object>();
try {
    Schema.SObjectType eventSObjectType = Schema.getGlobalDescribe().get('PVS_Event__c');
    if (eventSObjectType != null) {
        for (Schema.SObjectField field : eventSObjectType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult fieldDesc = field.getDescribe();
            eventFields.put(fieldDesc.getName(), new Map<String, Object>{
                'type' => fieldDesc.getType().name(),
                'label' => fieldDesc.getLabel(),
                'required' => !fieldDesc.isNillable(),
                'referenceTo' => fieldDesc.getReferenceTo()
            });
        }
    }
} catch (Exception e) {
    eventFields.put('error', 'PVS_Event__c not accessible: ' + e.getMessage());
}
allData.put('PVS_Event_Fields', eventFields);

// 4. Get PVS_Event_Registration__c object metadata
Map<String, Object> regFields = new Map<String, Object>();
try {
    Schema.SObjectType regSObjectType = Schema.getGlobalDescribe().get('PVS_Event_Registration__c');
    if (regSObjectType != null) {
        for (Schema.SObjectField field : regSObjectType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult fieldDesc = field.getDescribe();
            regFields.put(fieldDesc.getName(), new Map<String, Object>{
                'type' => fieldDesc.getType().name(),
                'label' => fieldDesc.getLabel(),
                'required' => !fieldDesc.isNillable(),
                'referenceTo' => fieldDesc.getReferenceTo()
            });
        }
    }
} catch (Exception e) {
    regFields.put('error', 'PVS_Event_Registration__c not accessible: ' + e.getMessage());
}
allData.put('PVS_Event_Registration_Fields', regFields);

// 5. Get hed__Application__c object metadata
Map<String, Object> appFields = new Map<String, Object>();
try {
    Schema.SObjectType appSObjectType = Schema.getGlobalDescribe().get('hed__Application__c');
    if (appSObjectType != null) {
        for (Schema.SObjectField field : appSObjectType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult fieldDesc = field.getDescribe();
            String fieldName = fieldDesc.getName();
            // Focus on fields referenced in code
            if (fieldName.contains('Applying_To__c') || fieldName.contains('Household__c') || fieldName == 'Id') {
                appFields.put(fieldName, new Map<String, Object>{
                    'type' => fieldDesc.getType().name(),
                    'label' => fieldDesc.getLabel(),
                    'required' => !fieldDesc.isNillable(),
                    'referenceTo' => fieldDesc.getReferenceTo()
                });
            }
        }
    }
} catch (Exception e) {
    appFields.put('error', 'hed__Application__c not accessible: ' + e.getMessage());
}
allData.put('hed_Application_Fields', appFields);

// 6. Get Event object custom fields
Map<String, Object> stdEventFields = new Map<String, Object>();
for (Schema.SObjectField field : Schema.Event.SObjectType.getDescribe().fields.getMap().values()) {
    Schema.DescribeFieldResult fieldDesc = field.getDescribe();
    String fieldName = fieldDesc.getName();
    // Focus on custom fields referenced in code
    if (fieldName.contains('PVS_Event__c') || fieldName.contains('Stage__c') || 
        fieldName.contains('Zoom_Event_ID__c') || fieldName.contains('Zoom_Ticket_Type_ID__c') ||
        fieldName == 'WhoId' || fieldName == 'DurationInMinutes' || fieldName == 'ActivityDateTime' || fieldName == 'Id') {
        stdEventFields.put(fieldName, new Map<String, Object>{
            'type' => fieldDesc.getType().name(),
            'label' => fieldDesc.getLabel(),
            'required' => !fieldDesc.isNillable(),
            'referenceTo' => fieldDesc.getReferenceTo()
        });
    }
}
allData.put('Event_Fields', stdEventFields);

// FIX: Remove non-serializable references from field metadata
for (String objectKey : allData.keySet()) {
    if (objectKey.endsWith('_Fields')) {
        Map<String, Object> fields = (Map<String, Object>) allData.get(objectKey);
        for (String fieldKey : fields.keySet()) {
            Map<String, Object> fieldData = (Map<String, Object>) fields.get(fieldKey);
            if (fieldData.containsKey('referenceTo')) {
                List<Schema.SObjectType> refs = (List<Schema.SObjectType>) fieldData.get('referenceTo');
                List<String> refNames = new List<String>();
                if (refs != null) {
                    for (Schema.SObjectType ref : refs) {
                        refNames.add(ref.getDescribe().getName());
                    }
                }
                fieldData.put('referenceTo', refNames);
            }
        }
    }
}

// 7. PASTE YOUR ACTUAL IDs HERE:
String sampleEventId = 'a1hWE000001VGpVYAW';           // PVS_Event__c record
String sampleContactId = '003WE00000f71W2YAI';           // Contact with applications/school
String sampleUserId = '005WE00000KhummYAB';                 // User tied to the contact
String sampleAccountId = '001WE00000a2ekcYAA';           // Account (Household)
String sampleSchoolId = '001WE00000Z1sjlYAB';             // School (Account) referenced in Event/Application
String sampleApplicationId = 'a05WE00000KiRaTYAV';   // hed__Application__c record
String sampleRegistrationId = 'a28WE000001PgMrYAK'; // PVS_Event_Registration__c record
String sampleEventRecordId = '00UWE000004yY1J2AU';  // Standard Event record

// Query actual live data using your IDs
try {
    if (sampleEventId != 'PASTE_PVS_EVENT_ID_HERE') {
        // Query base fields instead of formula fields
        PVS_Event__c event = [
            SELECT Id, Event_Title__c, Event_Description__c, Event_Type__c,
                   Event_Date__c, Event_Start_Time__c, Event_End_Time__c, Event_Time_Zone__c,
                   School__c, School__r.School_Abbreviation__c,
                   Event_Status__c, Event_Attendance_Type__c, Channel_Type__c,
                   Zoom_Event_ID__c, Zoom_Ticket_Type_ID__c, Zoom_Template__c, Zoom_Hub__c,
                   Update_Event_Platform__c, Event_Geo_Target__c
            FROM PVS_Event__c 
            WHERE Id = :sampleEventId 
            LIMIT 1
        ];
        allData.put('Sample_PVS_Event_Data', event);
    }
} catch (Exception e) {
    allData.put('Sample_Event_Query_Error', e.getMessage());
}

try {
    if (sampleContactId != 'PASTE_CONTACT_ID_HERE') {
        List<String> contactFieldsList = new List<String>();
        for (String fieldName : contactFields.keySet()) {
            contactFieldsList.add(fieldName);
        }
        // Add any missing standard fields
        contactFieldsList.add('Name');
        
        List<Contact> contacts = Database.query(
            'SELECT ' + String.join(contactFieldsList, ', ') + 
            ' FROM Contact WHERE Id = \'' + sampleContactId + '\' LIMIT 1'
        );
        if (!contacts.isEmpty()) {
            allData.put('Sample_Contact_Data', contacts[0]);
        }
    }
} catch (Exception e) {
    allData.put('Sample_Contact_Query_Error', e.getMessage());
}

try {
    if (sampleUserId != 'PASTE_USER_ID_HERE') {
        User sampleUser = [
            SELECT Id, ContactId, Contact.ycadmissions__InitialSchool__c, Contact.AccountId,
                   Contact.Email, Contact.FirstName, Contact.LastName, Contact.Phone, Contact.Caretaker_Status__c
            FROM User WHERE Id = :sampleUserId LIMIT 1
        ];
        allData.put('Sample_User_Data', sampleUser);
    }
} catch (Exception e) {
    allData.put('Sample_User_Query_Error', e.getMessage());
}

try {
    if (sampleApplicationId != 'PASTE_APPLICATION_ID_HERE') {
        List<String> appFieldsList = new List<String>();
        for (String fieldName : appFields.keySet()) {
            if (fieldName != 'error') appFieldsList.add(fieldName);
        }
        
        List<hed__Application__c> applications = Database.query(
            'SELECT ' + String.join(appFieldsList, ', ') + 
            ' FROM hed__Application__c WHERE Id = \'' + sampleApplicationId + '\' LIMIT 1'
        );
        if (!applications.isEmpty()) {
            allData.put('Sample_Application_Data', applications[0]);
        }
    }
} catch (Exception e) {
    allData.put('Sample_Application_Query_Error', e.getMessage());
}

try {
    if (sampleRegistrationId != 'PASTE_REGISTRATION_ID_HERE') {
        List<String> regFieldsList = new List<String>();
        for (String fieldName : regFields.keySet()) {
            if (fieldName != 'error') regFieldsList.add(fieldName);
        }
        
        List<PVS_Event_Registration__c> registrations = Database.query(
            'SELECT ' + String.join(regFieldsList, ', ') + 
            ' FROM PVS_Event_Registration__c WHERE Id = \'' + sampleRegistrationId + '\' LIMIT 1'
        );
        if (!registrations.isEmpty()) {
            allData.put('Sample_Registration_Data', registrations[0]);
        }
    }
} catch (Exception e) {
    allData.put('Sample_Registration_Query_Error', e.getMessage());
}

try {
    if (sampleEventRecordId != 'PASTE_EVENT_RECORD_ID_HERE') {
        List<String> eventFieldsList = new List<String>();
        for (String fieldName : stdEventFields.keySet()) {
            eventFieldsList.add(fieldName);
        }
        
        List<Event> eventRecords = Database.query(
            'SELECT ' + String.join(eventFieldsList, ', ') + 
            ' FROM Event WHERE Id = \'' + sampleEventRecordId + '\' LIMIT 1'
        );
        if (!eventRecords.isEmpty()) {
            allData.put('Sample_Event_Record_Data', eventRecords[0]);
        }
    }
} catch (Exception e) {
    allData.put('Sample_Event_Record_Query_Error', e.getMessage());
}

try {
    if (sampleSchoolId != 'PASTE_SCHOOL_ID_HERE') {
        Account sampleSchool = [
            SELECT Id, Name, RecordTypeId, RecordType.Name
            FROM Account WHERE Id = :sampleSchoolId LIMIT 1
        ];
        allData.put('Sample_School_Data', sampleSchool);
    }
} catch (Exception e) {
    allData.put('Sample_School_Query_Error', e.getMessage());
}

// Output as JSON
System.debug('=== METADATA AND LIVE DATA EXTRACTION RESULTS ===');
System.debug(JSON.serializePretty(allData));
System.debug('=== END EXTRACTION RESULTS ===');