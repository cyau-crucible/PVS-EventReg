import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUpcomingEvents from '@salesforce/apex/yc_EventListController.getUpcomingEvents';
import registerForEvent from '@salesforce/apex/yc_EventListController.registerForEvent';
import getUserRegisteredEventIds from '@salesforce/apex/yc_EventListController.getUserRegisteredEventIds';

export default class EventListing extends LightningElement {
    @track events = [];
    @track error;
    @track isLoading = true;
    @track registeredEventIds = [];
    @track registeringEventId = null;
    
    // Modal and timer properties
    @track showInactivityModal = false;
    @track featuredEvent = null;
    @track modalPermanentlyDismissed = false;
    inactivityTimer = null;
    inactivityTimeoutMs = 60000; // 60 seconds

    connectedCallback() {
        this.startInactivityTimer();
        this.addEventListeners();
    }

    disconnectedCallback() {
        this.clearInactivityTimer();
        this.removeEventListeners();
    }

    // Activity tracking methods
    addEventListeners() {
        // Listen for user activity on the component
        this.template.addEventListener('click', this.resetInactivityTimer.bind(this));
        this.template.addEventListener('scroll', this.resetInactivityTimer.bind(this));
        this.template.addEventListener('mousemove', this.resetInactivityTimer.bind(this));
        this.template.addEventListener('keydown', this.resetInactivityTimer.bind(this));
        
        // Also listen on document for broader activity detection
        document.addEventListener('click', this.resetInactivityTimer.bind(this));
        document.addEventListener('scroll', this.resetInactivityTimer.bind(this));
        document.addEventListener('mousemove', this.resetInactivityTimer.bind(this));
        document.addEventListener('keydown', this.resetInactivityTimer.bind(this));
    }

    removeEventListeners() {
        document.removeEventListener('click', this.resetInactivityTimer.bind(this));
        document.removeEventListener('scroll', this.resetInactivityTimer.bind(this));
        document.removeEventListener('mousemove', this.resetInactivityTimer.bind(this));
        document.removeEventListener('keydown', this.resetInactivityTimer.bind(this));
    }

    startInactivityTimer() {
        this.clearInactivityTimer();
        this.inactivityTimer = setTimeout(() => {
            this.showInactivityPrompt();
        }, this.inactivityTimeoutMs);
    }

    resetInactivityTimer() {
        if (this.showInactivityModal) {
            return; // Don't reset timer while modal is open
        }
        this.startInactivityTimer();
    }

    clearInactivityTimer() {
        if (this.inactivityTimer) {
            clearTimeout(this.inactivityTimer);
            this.inactivityTimer = null;
        }
    }

    showInactivityPrompt() {
        // Don't show modal if permanently dismissed
        if (this.modalPermanentlyDismissed) {
            return;
        }
        
        // Find the first event that user hasn't registered for
        const availableEvent = this.events.find(event => 
            !this.isUserRegistered(event.id) && !this.isRegistering(event.id)
        );

        if (availableEvent) {
            this.featuredEvent = availableEvent;
            this.showInactivityModal = true;
            console.log('Showing inactivity modal for event:', availableEvent.title);
        } else {
            console.log('No available events for inactivity modal');
            // Restart timer if no events available
            this.startInactivityTimer();
        }
    }

    // Modal control methods
    closeInactivityModal() {
        this.showInactivityModal = false;
        this.featuredEvent = null;
        this.modalPermanentlyDismissed = true; // Permanently disable modal
        // Modal will not appear again for this session
    }

    // Handle register from modal
    handleModalRegister() {
        if (this.featuredEvent) {
            // Create a mock event with the featured event ID
            const mockEvent = {
                target: {
                    dataset: {
                        eventId: this.featuredEvent.id
                    }
                }
            };
            
            // Close modal and permanently disable
            this.showInactivityModal = false;
            this.featuredEvent = null;
            this.modalPermanentlyDismissed = true;
            
            // Call the existing register handler
            this.handleRegister(mockEvent);
        }
    }

    // Wire the Apex method to get events
    @wire(getUpcomingEvents)
    wiredEvents({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.loadRegisteredEvents().then(() => {
                this.events = this.transformEventData(data);
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.events = [];
            console.error('Error loading events:', error);
        }
    }

    // Load registered events separately to avoid wire conflicts
    async loadRegisteredEvents() {
        try {
            this.registeredEventIds = await getUserRegisteredEventIds();
        } catch (error) {
            console.error('Error loading user registrations:', error);
            this.registeredEventIds = [];
        }
    }

    // Transform Salesforce data to component format
    transformEventData(salesforceEvents) {
        return salesforceEvents.map(event => {
            const eventDate = this.parseEventDate(event.Event_Date__c);
            const isDisabled = this.isButtonDisabled(event.Id);
            
            return {
                id: event.Id,
                day: eventDate.day,
                monthYear: eventDate.monthYear,
                title: event.Event_Title__c || 'Event Title Not Available',
                time: event.Event_Start_Time_Web_F__c || 'Time TBD',
                type: event.Event_Type__c || 'Virtual Event',
                description: event.Event_Description__c || 'Event description not available.',
                buttonLabel: this.getButtonLabel(event.Id),
                buttonVariant: this.getButtonVariant(event.Id),
                isButtonDisabled: isDisabled,
                isRegistering: this.isRegistering(event.Id),
                buttonClass: isDisabled ? 'custom-register-button custom-register-button-disabled' : 'custom-register-button'
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
    async handleRegister(event) {
        const eventId = event.target.dataset.eventId;
        const selectedEvent = this.events.find(evt => evt.id === eventId);
        
        console.log('Registration clicked for event ID:', eventId);
        console.log('Selected event:', selectedEvent);
        
        // Prevent multiple registrations
        if (this.registeringEventId === eventId) {
            console.log('Registration already in progress for this event');
            return;
        }
        
        if (!eventId) {
            console.error('No event ID found');
            return;
        }
        
        this.registeringEventId = eventId;
        
        // Update button state immediately
        this.refreshEventData();
        
        try {
            console.log('Calling registerForEvent with eventId:', eventId);
            const result = await registerForEvent({ eventId: eventId });
            console.log('Registration result:', result);
            
            if (result === 'SUCCESS') {
                // Show success message
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Registration Successful',
                    message: `You have been registered for "${selectedEvent.title}"`,
                    variant: 'success'
                }));
                
                // Add to registered events list and refresh the events display
                this.registeredEventIds = [...this.registeredEventIds, eventId];
                
                // Refresh the events to update button states
                this.refreshEventData();
                
            } else if (result === 'ALREADY_REGISTERED') {
                // Show info message
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Already Registered',
                    message: `You are already registered for "${selectedEvent.title}"`,
                    variant: 'info'
                }));
                
                // Add to registered list since they're already registered
                this.registeredEventIds = [...this.registeredEventIds, eventId];
                this.refreshEventData();
            }
            
        } catch (error) {
            console.error('Registration error:', error);
            console.error('Error details:', JSON.stringify(error));
            
            let errorMessage = 'An error occurred during registration. Please try again.';
            if (error.body && error.body.message) {
                errorMessage = error.body.message;
            } else if (error.message) {
                errorMessage = error.message;
            }
            
            // Show error message
            this.dispatchEvent(new ShowToastEvent({
                title: 'Registration Failed',
                message: errorMessage,
                variant: 'error'
            }));
            
        } finally {
            this.registeringEventId = null;
            this.refreshEventData();
        }
    }

    // Check if user is registered for an event
    isUserRegistered(eventId) {
        return this.registeredEventIds.includes(eventId);
    }

    // Check if registration is in progress for an event
    isRegistering(eventId) {
        return this.registeringEventId === eventId;
    }

    // Get button label based on registration status
    getButtonLabel(eventId) {
        if (this.isRegistering(eventId)) {
            return 'Registering...';
        } else if (this.isUserRegistered(eventId)) {
            return 'Already Registered';
        } else {
            return 'Register';
        }
    }

    // Get button variant based on registration status
    getButtonVariant(eventId) {
        if (this.isUserRegistered(eventId)) {
            return 'success';
        } else {
            return 'brand';
        }
    }

    // Check if button should be disabled
    isButtonDisabled(eventId) {
        return this.isUserRegistered(eventId) || this.isRegistering(eventId);
    }

    // Getter for template conditional rendering
    get hasEvents() {
        // During loading, we don't know if we have events yet, so return true to hide "no events" message
        if (this.isLoading) {
            return true;
        }
        return this.events && this.events.length > 0;
    }

    get hasError() {
        return this.error && this.error.body && this.error.body.message;
    }

    get errorMessage() {
        return this.error?.body?.message || 'An error occurred while loading events.';
    }

    // Refresh event data to update button states
    refreshEventData() {
        if (this.events && this.events.length > 0) {
            this.events = this.events.map(event => {
                const isDisabled = this.isButtonDisabled(event.id);
                return {
                    ...event,
                    buttonLabel: this.getButtonLabel(event.id),
                    buttonVariant: this.getButtonVariant(event.id),
                    isButtonDisabled: isDisabled,
                    isRegistering: this.isRegistering(event.id),
                    buttonClass: isDisabled ? 'custom-register-button custom-register-button-disabled' : 'custom-register-button'
                };
            });
        }
    }

    
}