import { LightningElement, track } from 'lwc';

export default class EventListing extends LightningElement {
    // Array of events with placeholder data
    @track events = [
        {
            id: 'event-001',
            day: '28',
            monthYear: 'Jul 2025',
            title: 'Parent-to-Parent Panel',
            time: '9:00 PM EDT',
            type: 'Virtual Event',
            description: 'Hear directly from real Connections Academy® parents from across the country, who will share their personal experiences with how online learning works, including key tips and tricks.'
        },
        {
            id: 'event-002',
            day: '28',
            monthYear: 'Jul 2025',
            title: 'Parent-to-Parent Panel',
            time: '9:00 PM EDT',
            type: 'Virtual Event',
            description: 'Hear directly from real Connections Academy® parents from across the country, who will share their personal experiences with how online learning works, including key tips and tricks.'
        },
        {
            id: 'event-003',
            day: '28',
            monthYear: 'Jul 2025',
            title: 'Parent-to-Parent Panel',
            time: '9:00 PM EDT',
            type: 'Virtual Event',
            description: 'Hear directly from real Connections Academy® parents from across the country, who will share their personal experiences with how online learning works, including key tips and tricks.'
        }
    ];

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
}