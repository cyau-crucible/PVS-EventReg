import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUpcomingEvents from '@salesforce/apex/yc_EventListController.getUpcomingEvents';
import registerForEvent from '@salesforce/apex/yc_EventListController.registerForEvent';
import getUserRegisteredEventIds from '@salesforce/apex/yc_EventListController.getUserRegisteredEventIds';
// Add these imports when you implement the backend
// import isGuest from '@salesforce/user/isGuest';
// import createLeadAndRegister from '@salesforce/apex/yc_EventListController.createLeadAndRegister';

export default class YcEventModal extends LightningElement {
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
    inactivityTimeoutMs = 20000; // 20 seconds

    // Lead Registration Modal properties
    @track showLeadRegistrationModal = false;
    @track isSubmittingLead = false;
    @track pendingEventForRegistration = null;
    @track leadFormData = {
        firstName: '',
        lastName: '',
        email: '',
        phone: '',
        state: '',
        zipCode: '',
        smsOptIn: false
    };

    // State options for dropdown
    stateOptions = [
        { label: 'Select a State', value: '' },
        { label: 'Alabama', value: 'AL' },
        { label: 'Alaska', value: 'AK' },
        { label: 'Arizona', value: 'AZ' },
        { label: 'Arkansas', value: 'AR' },
        { label: 'California', value: 'CA' },
        { label: 'Colorado', value: 'CO' },
        { label: 'Connecticut', value: 'CT' },
        { label: 'Delaware', value: 'DE' },
        { label: 'Florida', value: 'FL' },
        { label: 'Georgia', value: 'GA' },
        { label: 'Hawaii', value: 'HI' },
        { label: 'Idaho', value: 'ID' },
        { label: 'Illinois', value: 'IL' },
        { label: 'Indiana', value: 'IN' },
        { label: 'Iowa', value: 'IA' },
        { label: 'Kansas', value: 'KS' },
        { label: 'Kentucky', value: 'KY' },
        { label: 'Louisiana', value: 'LA' },
        { label: 'Maine', value: 'ME' },
        { label: 'Maryland', value: 'MD' },
        { label: 'Massachusetts', value: 'MA' },
        { label: 'Michigan', value: 'MI' },
        { label: 'Minnesota', value: 'MN' },
        { label: 'Mississippi', value: 'MS' },
        { label: 'Missouri', value: 'MO' },
        { label: 'Montana', value: 'MT' },
        { label: 'Nebraska', value: 'NE' },
        { label: 'Nevada', value: 'NV' },
        { label: 'New Hampshire', value: 'NH' },
        { label: 'New Jersey', value: 'NJ' },
        { label: 'New Mexico', value: 'NM' },
        { label: 'New York', value: 'NY' },
        { label: 'North Carolina', value: 'NC' },
        { label: 'North Dakota', value: 'ND' },
        { label: 'Ohio', value: 'OH' },
        { label: 'Oklahoma', value: 'OK' },
        { label: 'Oregon', value: 'OR' },
        { label: 'Pennsylvania', value: 'PA' },
        { label: 'Rhode Island', value: 'RI' },
        { label: 'South Carolina', value: 'SC' },
        { label: 'South Dakota', value: 'SD' },
        { label: 'Tennessee', value: 'TN' },
        { label: 'Texas', value: 'TX' },
        { label: 'Utah', value: 'UT' },
        { label: 'Vermont', value: 'VT' },
        { label: 'Virginia', value: 'VA' },
        { label: 'Washington', value: 'WA' },
        { label: 'West Virginia', value: 'WV' },
        { label: 'Wisconsin', value: 'WI' },
        { label: 'Wyoming', value: 'WY' }
    ];

    connectedCallback() {
        console.log('Component connected - starting inactivity timer');
        this.startInactivityTimer();
        this.addEventListeners();
        this.checkForRegistrationParams();
        
        // Debug: Log current state
        console.log('Initial state:', {
            modalPermanentlyDismissed: this.modalPermanentlyDismissed,
            inactivityTimeoutMs: this.inactivityTimeoutMs,
            eventsCount: this.events.length,
            events: this.events,
            isGuestUser: this.isGuestUser
        });
    }

    disconnectedCallback() {
        this.clearInactivityTimer();
        this.removeEventListeners();
    }

    // Check URL parameters to prevent modal if user just registered
    checkForRegistrationParams() {
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.get('fromEvent') === '1') {
            this.modalPermanentlyDismissed = true;
            console.log('User just registered, modal disabled');
        }
    }

    // Check if user is a guest (stub for now - uncomment when import is available)
    get isGuestUser() {
        // return isGuest === true;
        // For testing, you can toggle this
        return true; // Set to true to test guest user flow
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
        console.log('Starting inactivity timer for', this.inactivityTimeoutMs, 'ms');
        this.inactivityTimer = setTimeout(() => {
            console.log('Timer expired! Calling showInactivityPrompt()');
            this.showInactivityPrompt();
        }, this.inactivityTimeoutMs);
    }

    resetInactivityTimer() {
        if (this.showInactivityModal || this.showLeadRegistrationModal) {
            console.log('Not resetting timer - modal is open');
            return; // Don't reset timer while modal is open
        }
        console.log('Activity detected - resetting timer');
        this.startInactivityTimer();
    }

    clearInactivityTimer() {
        if (this.inactivityTimer) {
            clearTimeout(this.inactivityTimer);
            this.inactivityTimer = null;
        }
    }

    showInactivityPrompt() {
        console.log('showInactivityPrompt called!');
        console.log('Current state:', {
            modalPermanentlyDismissed: this.modalPermanentlyDismissed,
            eventsLength: this.events.length,
            events: this.events,
            registeredEventIds: this.registeredEventIds,
            isLoading: this.isLoading
        });
        
        // Don't show modal if permanently dismissed or if fromEvent=1 parameter exists
        if (this.modalPermanentlyDismissed) {
            console.log('Modal permanently dismissed - not showing');
            return;
        }
        
        // Check if events are loaded
        if (this.events.length === 0) {
            console.log('No events available. Giving up.');
            // Don't restart timer - just give up
            return;
        }
        
        // Find the first event that user hasn't registered for
        const availableEvent = this.events.find(event => 
            !this.isUserRegistered(event.id) && !this.isRegistering(event.id)
        );

        console.log('Available event found:', availableEvent);

        if (availableEvent) {
            this.featuredEvent = availableEvent;
            this.showInactivityModal = true;
            console.log('Showing inactivity modal for event:', availableEvent.title);
            console.log('Modal state:', this.showInactivityModal);
        } else {
            console.log('No available events for inactivity modal - user registered for all');
            console.log('All events:', this.events);
            console.log('Registered IDs:', this.registeredEventIds);
            // Don't restart timer - no point
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
            // Store the event for registration
            this.pendingEventForRegistration = this.featuredEvent;
            
            // Close inactivity modal
            this.showInactivityModal = false;
            this.modalPermanentlyDismissed = true;
            
            // Check if user is guest
            if (this.isGuestUser) {
                // Show lead registration form for guest users
                this.showLeadRegistrationModal = true;
            } else {
                // For authenticated users, proceed with normal registration
                const mockEvent = {
                    target: {
                        dataset: {
                            eventId: this.pendingEventForRegistration.id
                        }
                    }
                };
                this.handleRegister(mockEvent);
            }
        }
    }

    // Lead Registration Form Handlers
    handleLeadFormChange(event) {
        const field = event.target.name;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        this.leadFormData = { ...this.leadFormData, [field]: value };
    }

    closeLeadRegistrationModal() {
        this.showLeadRegistrationModal = false;
        this.resetLeadForm();
        this.pendingEventForRegistration = null;
    }

    resetLeadForm() {
        this.leadFormData = {
            firstName: '',
            lastName: '',
            email: '',
            phone: '',
            state: '',
            zipCode: '',
            smsOptIn: false
        };
    }

    validateLeadForm() {
        const required = ['firstName', 'lastName', 'email', 'phone', 'state', 'zipCode'];
        for (let field of required) {
            if (!this.leadFormData[field] || this.leadFormData[field].trim() === '') {
                return false;
            }
        }
        
        // Validate email format
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(this.leadFormData.email)) {
            return false;
        }
        
        // Validate ZIP code (5 digits)
        const zipRegex = /^\d{5}$/;
        if (!zipRegex.test(this.leadFormData.zipCode)) {
            return false;
        }
        
        return true;
    }

    async handleLeadFormSubmit() {
        // Validate form
        if (!this.validateLeadForm()) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Missing Information',
                message: 'Please fill in all required fields correctly.',
                variant: 'error'
            }));
            return;
        }

        this.isSubmittingLead = true;

        try {
            // TODO: Call Apex method to create lead and register for event
            // const result = await createLeadAndRegister({
            //     leadData: this.leadFormData,
            //     eventId: this.pendingEventForRegistration.id
            // });

            // For now, simulate success
            console.log('Lead form data:', this.leadFormData);
            console.log('Event ID:', this.pendingEventForRegistration.id);

            // Show success message
            this.dispatchEvent(new ShowToastEvent({
                title: 'Registration Successful',
                message: `Thank you for registering for "${this.pendingEventForRegistration.title}". You will receive a confirmation email shortly.`,
                variant: 'success'
            }));

            // Close modal and reset
            this.closeLeadRegistrationModal();

            // Build redirect URL with parameters
            const currentUrl = new URL(window.location.href);
            const params = new URLSearchParams(currentUrl.search);
            
            // Add registration parameters
            params.set('fn', this.leadFormData.firstName);
            params.set('ln', this.leadFormData.lastName);
            params.set('email', this.leadFormData.email);
            params.set('state', this.leadFormData.state);
            params.set('zipcode', this.leadFormData.zipCode);
            params.set('fromEvent', '1');
            
            // Redirect to the same page with parameters
            window.location.href = `${currentUrl.pathname}?${params.toString()}`;

        } catch (error) {
            console.error('Lead registration error:', error);
            
            let errorMessage = 'An error occurred during registration. Please try again.';
            if (error.body && error.body.message) {
                errorMessage = error.body.message;
            }
            
            this.dispatchEvent(new ShowToastEvent({
                title: 'Registration Failed',
                message: errorMessage,
                variant: 'error'
            }));
        } finally {
            this.isSubmittingLead = false;
        }
    }

    // Link handlers for terms, privacy, and contact
    handleTermsClick(event) {
        event.preventDefault();
        // Navigate to terms page or open in new window
        window.open('/terms-of-use', '_blank');
    }

    handlePrivacyClick(event) {
        event.preventDefault();
        // Navigate to privacy policy page or open in new window
        window.open('/privacy-policy', '_blank');
    }

    handleContactClick(event) {
        event.preventDefault();
        // Navigate to contact page or open in new window
        window.open('/contact-us', '_blank');
    }

    // Wire the Apex method to get events
    @wire(getUpcomingEvents)
    wiredEvents({ error, data }) {
        console.log('Wire method called with:', { hasData: !!data, hasError: !!error });
        if (data) {
            console.log('Events data received:', data);
            this.loadRegisteredEvents().then(() => {
                this.events = this.transformEventData(data);
                this.isLoading = false; // Set to false after data is processed
                console.log('Events loaded and transformed:', this.events);
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.events = [];
            this.isLoading = false; // Set to false after error is handled
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