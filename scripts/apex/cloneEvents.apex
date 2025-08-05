// Get the object and record ID you want to clone
String objectName = 'PVS_Event__c';  // Change this to your object
String recordId = 'a1dEa000007gUfBIAU';  // Change this to your record ID

// Get object type
Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);

// Get all accessible fields
Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
List<String> fieldNames = new List<String>();

for (String fieldName : fieldMap.keySet()) {
   Schema.DescribeFieldResult field = fieldMap.get(fieldName).getDescribe();
   if (field.isAccessible() && !field.isCalculated()) {
       fieldNames.add(fieldName);
   }
}

// Query the record with all fields
String query = 'SELECT ' + String.join(fieldNames, ',') + 
              ' FROM ' + objectName + 
              ' WHERE Id = \'' + recordId + '\' LIMIT 1';

List<SObject> records = Database.query(query);

if (!records.isEmpty()) {
   SObject cloned = records[0].clone();  
   insert cloned;
   System.debug('Original ID: ' + recordId);
   System.debug('Cloned ID: ' + cloned.Id);
} else {
   System.debug('No record found with ID: ' + recordId);
}