public without sharing class yc_EventListController {
    
    @AuraEnabled(cacheable=true)
    public static List<PVS_Event__c> getUpcomingEvents() {
        try {
            // Build the list of permissible school IDs
            Set<Id> permissibleSchoolIds = new Set<Id>();
            User currentUser;

            // Get current user's Contact information including school lookup and household
            List<User> currentUserQuery = [ SELECT Id, ContactId, Contact.ycadmissions__InitialSchool__c, Contact.AccountId
                                            FROM User WHERE Id = :UserInfo.getUserId() ];
            if (currentUserQuery.size() > 0) {
                currentUser = currentUserQuery[0];
                
                // Add schools from Applications related to the Contact's Household
                if (currentUser.ContactId != null && currentUser.Contact.AccountId != null) {
                    // Query for Applications where Household matches Contact's Account (Household)
                    List<hed__Application__c> householdApplications = [
                        SELECT Id, hed__Applying_To__c
                        FROM hed__Application__c
                        WHERE Household__c = :currentUser.Contact.AccountId
                        AND hed__Applying_To__c != NULL AND hed__Application_Status__c != 'Archived'
                        AND RECORDTYPE.DeveloperName != 'Intent_to_Return'
                    ];
                    
                    // Add all the school IDs from these applications
                    for (hed__Application__c app : householdApplications) {
                        permissibleSchoolIds.add(app.hed__Applying_To__c);
                        System.debug('Added Application School: ' + app.hed__Applying_To__c);
                    }
                }
            }  // end currentUserQuery

            // Build dynamic SOQL query with school filtering
            DateTime currentDateTime = System.now();
            String query = 'SELECT Id, Event_Title__c, Event_Date__c, Event_Start_Time_Web_F__c, ' +
                          'Event_Type__c, Event_Description__c, School_Abbreviation__c, School__c, ' + 
                          'Zoom_Event_ID__c, Channel_Type__c ' + 
                          'FROM PVS_Event__c ' +
                          'WHERE Event_Start_DateTime_F__c >= :currentDateTime AND Event_Status__c = \'Active\'';

            // Add school filtering
            if (!permissibleSchoolIds.isEmpty()) {
                query += 'AND (School__c = NULL OR School__c IN :permissibleSchoolIds OR School__r.Name IN (\'National Event Hosts\', \'Enrollment Event\')) ';
            } else {
                // If no permissible schools, only show events with NULL school
                query += 'AND (School__c = NULL OR School__r.Name IN (\'National Event Hosts\', \'Enrollment Event\'))';
            }
            
            query += 'ORDER BY Event_Start_DateTime_F__c ASC LIMIT 50';
            
            System.debug('Executing query: ' + query);
            System.debug('Permissible School IDs: ' + permissibleSchoolIds);
            if (currentUser != NULL) { System.debug('Contact AccountId (Household): ' + currentUser.Contact.AccountId); }
            
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
                SELECT Id, ContactId, Contact.Email, Contact.FirstName, Contact.Caretaker_Status__c, 
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
                SELECT Id,Name, School_Abbreviation__c, Event_Title__c, Event_Duration_F__c, Event_Start_DateTime_F__c, Zoom_Event_ID__c, Zoom_Ticket_Type_ID__c, Channel_Type__c 
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

            // Additional check of Task sObjects
            List<Task > existingEventRegistrations = [
                SELECT Id 
                FROM Task  
                WHERE PVS_Event__c = :eventId 
                AND WhoId = :currentUser.ContactId 
                LIMIT 1
            ];
            
            if (!existingEventRegistrations.isEmpty()) {
                return 'ALREADY_REGISTERED';
            }

            /*
            // Create the registration record (Event)
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
            */

            // Find the Task Record Type
            List<RecordType> taskRT = [SELECT Id FROM RecordType WHERE DeveloperName='Form_Submission'];

            Task regEvent = new Task();
            regEvent.PVS_Event__c = selectedEvent.Id;
            regEvent.Event_ID__c = selectedEvent.Name;
            regEvent.WhoId = currentUser.ContactId;
            regEvent.WhatId = selectedEvent.Id;
            // regEvent.Stage__c = currentUser.Contact.Caretaker_Status__c;
            regEvent.Zoom_Event_ID__c = selectedEvent.Zoom_Event_ID__c;
            regEvent.Subject = selectedEvent.Event_Title__c;
            regEvent.Email__c = currentUser.Contact.Email;
            regEvent.First_Name__c = currentUser.Contact.firstName;
            regEvent.Last_Name__c = currentUser.Contact.lastName;
            regEvent.Phone__c = currentUser.Contact.Phone;
            regEvent.UTM_Campaign__c = 'enrollmentportal';
            regEvent.Event_Attendance_Status__c = 'Registered';
            regEvent.Event_Registration_from_EP__c = true;
            regEvent.Zoom_Ticket_Type_ID__c = selectedEvent.Zoom_Ticket_Type_ID__c;
            regEvent.Channel_Type__c = selectedEvent.Channel_Type__c;
            if (taskRT.size() > 0) { regEvent.RecordTypeId = taskRT[0].Id; }
            regEvent.ActivityDate = system.today();
            regEvent.Zoom_Ticket_Type_ID__c = selectedEvent.Zoom_Ticket_Type_ID__c;
            insert regEvent;
            
            System.debug('Successfully registered user for event: ' + selectedEvent.Event_Title__c);
            return 'SUCCESS';
            
        } catch (Exception e) {
            System.debug('Error registering for event: ' + e.getMessage());
            throw new AuraHandledException('Registration failed: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String createLeadAndRegister(Map<String, String> leadData, String eventId) {
        try {
            // Get the event details
            PVS_Event__c selectedEvent = [
                SELECT Id, Name, School_Abbreviation__c, Event_Title__c, Event_Duration_F__c, 
                       Event_Start_DateTime_F__c, Zoom_Event_ID__c, Zoom_Ticket_Type_ID__c, Channel_Type__c 
                FROM PVS_Event__c 
                WHERE Id = :eventId 
                LIMIT 1
            ];
            
            // Check if a Lead already exists with this email
            List<Lead> existingLeads = [
                SELECT Id, Email, FirstName, LastName, Phone
                FROM Lead 
                WHERE Email = : leadData.get('email')
                LIMIT 1
            ];
            
            Lead eventLead;
            Boolean isNewLead = false;
            
            if (! existingLeads.isEmpty()) {
                // Use existing lead
                eventLead = existingLeads[0];
                System.debug('Found existing Lead: ' + eventLead.Id);
            } else {
                // Create new Lead
                eventLead = new Lead();
                eventLead.FirstName = leadData.get('firstName');
                eventLead.LastName = leadData.get('lastName');
                eventLead.Email = leadData.get('email');
                eventLead.Phone = leadData.get('phone');
                eventLead.PostalCode = leadData.get('zipCode');
                eventLead.Status = 'New';
                eventLead.Company = 'Unknown'; // Required field
                
                // Add SMS Opt-in if provided
                String smsOptIn = leadData.get('smsOptIn');
                if (smsOptIn != null && smsOptIn.equalsIgnoreCase('true')) {
                    // Set SMS opt-in field
                    eventLead.hed__SMS_Opt_Out__c = true;
                }
                
                insert eventLead;
                isNewLead = true;
                System.debug('Created new Lead: ' + eventLead.Id);
            }  // end if/else Lead
            
            // Check if already registered for this event
            List<PVS_Event_Registration__c> existingRegistrations = [
                SELECT Id 
                FROM PVS_Event_Registration__c 
                WHERE PVS_Event__c = :eventId 
                AND Email__c = :eventLead.Email
                LIMIT 1
            ];
            
            if (!existingRegistrations.isEmpty()) {
                return 'ALREADY_REGISTERED';
            }

            // Additional check of Task sObjects
            List<Task > existingEventRegistrations = [
                SELECT Id 
                FROM Task  
                WHERE PVS_Event__c = :eventId 
                AND WhoId = : eventLead.Id
                LIMIT 1
            ];
            
            if (!existingEventRegistrations.isEmpty()) {
                return 'ALREADY_REGISTERED';
            }
                       
            // Create Task Registration
            List<RecordType> taskRT = [SELECT Id FROM RecordType WHERE DeveloperName='Form_Submission'];
            
            Task regEvent = new Task();
            regEvent.PVS_Event__c = selectedEvent.Id;
            regEvent.Event_ID__c = selectedEvent.Name;
            regEvent.WhoId = eventLead.Id;
            // regEvent.WhatId = selectedEvent.Id;  @TODO: Find alternate way to record event Id
            regEvent.Zoom_Event_ID__c = selectedEvent.Zoom_Event_ID__c;
            regEvent.Subject = selectedEvent.Event_Title__c;
            regEvent.Email__c = eventLead.Email;
            regEvent.First_Name__c = eventLead.FirstName;
            regEvent.Last_Name__c = eventLead.LastName;
            regEvent.Phone__c = eventLead.Phone;
            regEvent.UTM_Campaign__c = 'enrollmentportal';
            regEvent.Event_Attendance_Status__c = 'Registered';
            regEvent.Event_Registration_from_EP__c = true;
            regEvent.Zoom_Ticket_Type_ID__c = selectedEvent.Zoom_Ticket_Type_ID__c;
            regEvent.Channel_Type__c = selectedEvent.Channel_Type__c;
            regEvent.ActivityDate = System.today();
            if (taskRT.size() > 0) { 
                regEvent.RecordTypeId = taskRT[0].Id; 
            }
            
            insert regEvent;
            
            System.debug('Successfully registered Lead for event: ' + selectedEvent.Event_Title__c);
            return 'SUCCESS';
        } catch (Exception e) {
            System.debug('Error in createLeadAndRegister: ' + e.getMessage());
            throw new AuraHandledException('Registration failed: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getUserRegisteredEventIds() {
        try {
            User currentUser = [
                SELECT Id, ContactId, Contact.Email, Contact.Caretaker_Status__c 
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
            
            Set<String> registeredEventIds = new Set<String>();
            for (PVS_Event_Registration__c reg : registrations) {
                registeredEventIds.add(reg.PVS_Event__c);
            }

            // Also query for existing Events
            for (Task registeredEvent : [SELECT Id, PVS_Event__c, WhoId FROM Task WHERE WhoId =: currentUser.ContactId]) {
                registeredEventIds.add(registeredEvent.PVS_Event__c);
            }  // end registered Event query

            List<String> filteredEventIds = new List<String>();
            filteredEventIds.addAll(registeredEventIds);
            return filteredEventIds;
            
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