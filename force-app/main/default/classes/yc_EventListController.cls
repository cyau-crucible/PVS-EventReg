public without sharing class yc_EventListController {
    
    @AuraEnabled(cacheable=true)
    public static List<PVS_Event__c> getUpcomingEvents() {
        try {
            return [
                SELECT Id, Event_Title__c, Event_Date__c, Event_Start_Time_Web_F__c, 
                       Event_Type__c, Event_Description__c 
                FROM PVS_Event__c 
                WHERE Event_Start_DateTime_F__c >= TODAY 
                ORDER BY Event_Start_DateTime_F__c ASC
                LIMIT 50
            ];
        } catch (Exception e) {
            System.debug('Error retrieving events: ' + e.getMessage());
            throw new AuraHandledException('Unable to retrieve events: ' + e.getMessage());
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