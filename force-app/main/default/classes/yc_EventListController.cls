public with sharing class yc_EventListController {
    
    @AuraEnabled(cacheable=true)
    public static List<PVS_Event__c> getUpcomingEvents() {
        try {
            // Get current user's Contact information including school lookup
            User currentUser = [
                SELECT Id, ContactId, Contact.ycadmissions__InitialSchool__c
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                LIMIT 1
            ];
            
            // Build the list of permissible school IDs
            Set<Id> permissibleSchoolIds = new Set<Id>();
            
            // Add user's associated school if it exists
            if (currentUser.ContactId != null && currentUser.Contact.ycadmissions__InitialSchool__c != null) {
                permissibleSchoolIds.add(currentUser.Contact.ycadmissions__InitialSchool__c);
            }
            
            // Build dynamic SOQL query with school filtering
            String query = 'SELECT Id, Event_Title__c, Event_Date__c, Event_Start_Time_Web_F__c, ' +
                          'Event_Type__c, Event_Description__c, School_Abbreviation__c, School__c ' +
                          'FROM PVS_Event__c ' +
                          'WHERE Event_Start_DateTime_F__c >= TODAY ';
            
            // Add school filtering
            if (!permissibleSchoolIds.isEmpty()) {
                query += 'AND (School__c = NULL OR School__c IN :permissibleSchoolIds) ';
            } else {
                // If no permissible schools, only show events with NULL school
                query += 'AND School__c = NULL ';
            }
            
            query += 'ORDER BY Event_Start_DateTime_F__c ASC LIMIT 50';
            
            System.debug('Executing query: ' + query);
            System.debug('Permissible School IDs: ' + permissibleSchoolIds);
            
            return Database.query(query);
            
        } catch (Exception e) {
            System.debug('Error retrieving events: ' + e.getMessage());
            throw new AuraHandledException('Unable to retrieve events: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String registerForEvent(String eventId) {
        try {
            // Get current user's Contact information
            User currentUser = [
                SELECT Id, ContactId, Contact.Email, Contact.FirstName, 
                       Contact.LastName, Contact.Phone
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                LIMIT 1
            ];
            
            if (currentUser.ContactId == null) {
                throw new AuraHandledException('User must have an associated Contact to register for events.');
            }
            
            // Get the event details for School_Abbreviation__c
            PVS_Event__c selectedEvent = [
                SELECT Id, School_Abbreviation__c, Event_Title__c
                FROM PVS_Event__c 
                WHERE Id = :eventId 
                LIMIT 1
            ];
            
            // Check if user is already registered for this event
            List<PVS_Event_Registration__c> existingRegistrations = [
                SELECT Id 
                FROM PVS_Event_Registration__c 
                WHERE PVS_Event__c = :eventId 
                AND Email__c = :currentUser.Contact.Email
                LIMIT 1
            ];
            
            if (!existingRegistrations.isEmpty()) {
                return 'ALREADY_REGISTERED';
            }
            
            // Create the registration record
            PVS_Event_Registration__c registration = new PVS_Event_Registration__c(
                Email__c = currentUser.Contact.Email,
                First_Name__c = currentUser.Contact.FirstName,
                Last_Name__c = currentUser.Contact.LastName,
                Phone__c = currentUser.Contact.Phone,
                PVS_Event__c = selectedEvent.Id,
                School_Abbreviation__c = selectedEvent.School_Abbreviation__c,
                Stage__c = 'Prospect'
            );
            
            insert registration;
            
            System.debug('Successfully registered user for event: ' + selectedEvent.Event_Title__c);
            return 'SUCCESS';
            
        } catch (Exception e) {
            System.debug('Error registering for event: ' + e.getMessage());
            throw new AuraHandledException('Registration failed: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getUserRegisteredEventIds() {
        try {
            User currentUser = [
                SELECT Id, ContactId, Contact.Email
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                LIMIT 1
            ];
            
            if (currentUser.ContactId == null) {
                return new List<String>();
            }
            
            List<PVS_Event_Registration__c> registrations = [
                SELECT PVS_Event__c
                FROM PVS_Event_Registration__c 
                WHERE Email__c = :currentUser.Contact.Email
            ];
            
            List<String> registeredEventIds = new List<String>();
            for (PVS_Event_Registration__c reg : registrations) {
                registeredEventIds.add(reg.PVS_Event__c);
            }
            
            return registeredEventIds;
            
        } catch (Exception e) {
            System.debug('Error getting user registrations: ' + e.getMessage());
            return new List<String>();
        }
    }
    
    // Helper method to format date for display (optional, can be done in JS)
    @AuraEnabled(cacheable=true)
    public static String formatEventDate(Date eventDate) {
        if (eventDate == null) return '';
        
        DateTime dt = DateTime.newInstance(eventDate, Time.newInstance(0, 0, 0, 0));
        String dayOfMonth = String.valueOf(dt.day());
        String monthYear = dt.format('MMM yyyy');
        
        return JSON.serialize(new Map<String, String>{
            'day' => dayOfMonth,
            'monthYear' => monthYear
        });
    }
}