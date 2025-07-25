import { LightningElement, wire, track } from 'lwc';
import getUpcomingEvents from '@salesforce/apex/yc_EventListController.getUpcomingEvents';

export default class EventListing extends LightningElement {
    @track events = [];
    @track error;
    @track isLoading = true;

    // Wire the Apex method to get events
    @wire(getUpcomingEvents)
    wiredEvents({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.events = this.transformEventData(data);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.events = [];
            console.error('Error loading events:', error);
        }
    }

    // Transform Salesforce data to component format
    transformEventData(salesforceEvents) {
        return salesforceEvents.map(event => {
            const eventDate = this.parseEventDate(event.Event_Date__c);
            
            return {
                id: event.Id,
                day: eventDate.day,
                monthYear: eventDate.monthYear,
                title: event.Event_Title__c || 'Event Title Not Available',
                time: event.Event_Start_Time_Web_F__c || 'Time TBD',
                type: event.Event_Type__c || 'Event Type',
                description: event.Event_Description__c || 'Event description not available.'
            };
        });
    }

    // Parse Event_Date__c field and format for display
    parseEventDate(eventDateString) {
        if (!eventDateString) {
            return { day: '??', monthYear: 'Date TBD' };
        }

        try {
            // Parse the date string (format: YYYY-MM-DD)
            const eventDate = new Date(eventDateString);
            
            // Format day
            const day = eventDate.getDate().toString();
            
            // Format month and year
            const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
            const month = monthNames[eventDate.getMonth()];
            const year = eventDate.getFullYear();
            const monthYear = `${month} ${year}`;

            return { day, monthYear };
        } catch (error) {
            console.error('Error parsing date:', eventDateString, error);
            return { day: '??', monthYear: 'Date Error' };
        }
    }

    // Handle register button click
    handleRegister(event) {
        const eventId = event.target.dataset.eventId;
        const selectedEvent = this.events.find(evt => evt.id === eventId);
        
        console.log('Registration clicked for event:', selectedEvent);
        
        // Dispatch custom event for parent component to handle
        const registerEvent = new CustomEvent('register', {
            detail: {
                eventId: selectedEvent.id,
                eventTitle: selectedEvent.title,
                eventTime: selectedEvent.time,
                eventDate: `${selectedEvent.day} ${selectedEvent.monthYear}`
            }
        });
        this.dispatchEvent(registerEvent);
    }

    // Getter for template conditional rendering
    get hasEvents() {
        return this.events && this.events.length > 0;
    }

    get hasError() {
        return this.error && this.error.body && this.error.body.message;
    }

    get errorMessage() {
        return this.error?.body?.message || 'An error occurred while loading events.';
    }
}