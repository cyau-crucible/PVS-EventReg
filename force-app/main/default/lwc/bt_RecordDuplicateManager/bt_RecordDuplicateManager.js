import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import LightningConfirm from 'lightning/confirm';

import getDuplicateSets from '@salesforce/apex/ContactDuplicateSetsController.getDuplicateSets';
import getContactFieldSet from '@salesforce/apex/ContactDuplicateSetsController.getContactFieldSet';
import approveContactFromSet from '@salesforce/apex/ContactDuplicateSetsController.approveContactFromSet';
import mergeContacts from '@salesforce/apex/ContactDuplicateSetsController.mergeContacts';

export default class ContactDuplicateManager extends NavigationMixin(LightningElement) {
    /** Record page injects this automatically */
    @api recordId;

    /** Configurable in App Builder */
    @api fieldSetName = 'Duplicate_Review';
    @api maxSets = 25;

    @track fieldDescriptors = [];
    @track sets = [];
    isLoading = true;
    isMerging = false;  // NEW: tracks if a merge is in progress

    // store wire results for refresh
    _dupWireResult;
    _fieldWireResult;

    get hasSets() {
        return (this.sets && this.sets.length > 0);
    }
    get _fieldSetName() {
        return this.fieldSetName;
    }

    // Fetch DRS data
    @wire(getDuplicateSets, { contactId: '$recordId', maxSets: '$maxSets' })
    wiredDuplicates(value) {
        this._dupWireResult = value;
        const { data, error } = value;
        if (data) {
            this.sets = (data.sets || []).map(s => ({
                setId: s.setId,
                ruleDeveloperName: s.ruleDeveloperName,
                createdDate: s.createdDate,
                totalItems: s.totalItems,
                duplicateContactIds: s.duplicateContactIds || []
            }));
            this.isLoading = false;
        } else if (error) {
            this.isLoading = false;
            this._toast('Error loading duplicates', this._errorMessage(error), 'error');
        }
    }

    // Fetch field set
    @wire(getContactFieldSet, { fieldSetName: '$fieldSetName' })
    wiredFieldSet(value) {
        this._fieldWireResult = value;
        const { data, error } = value;
        if (data) {
            this.fieldDescriptors = data;
        } else if (error) {
            this._toast('Error loading field set', this._errorMessage(error), 'error');
        }
    }


async handleApprove(event) {
    const setId = event.currentTarget.dataset.setId;
    if (!setId) return;

    const ok = await this._confirm(
        'Approve this record as "Not a Duplicate"? This removes only this contact from the set.'
    );
    if (!ok) return;

    this.isLoading = true;
    try {
        await approveContactFromSet({ contactId: this.recordId, duplicateRecordSetId: setId });
        this._toast('Approved', 'This contact was removed from the duplicate set.', 'success');
        await refreshApex(this._dupWireResult);
    } catch (e) {
        this._toast('Couldn\'t approve', this._errorMessage(e), 'error');
    } finally {
        this.isLoading = false;
    }
}

handleMerge(event) {
    const setId = event.currentTarget.dataset.setId;   // REPLACE WITH A CONTACT ID INSTEAD
    if (!setId) return;

    // 1) Always-open path: go to the DRS record; user can click "Compare & Merge"
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: setId,
            objectApiName: 'DuplicateRecordSet',
            actionName: 'view'
        }
    });

    // 2) Also try to open the classic merge wizard in-place (best-effort fallback).
    //    We'll build a URL with the current contact + the first two duplicates
    //    (the wizard allows up to 3).
    //    NOTE: This runs after navigation, so if Lightning blocks the iframe load
    //    it still leaves the user on the DRS page where "Compare & Merge" works.
    try {
        // Find this set in local state
        const s = (this.sets || []).find(x => x.setId === setId);
        if (!s) return;

        // Build up to 3 contact IDs: current record + first two duplicates
        const ids = [this.recordId, ...(s.duplicateContactIds || []).slice(0, 2)];

        if (ids.length >= 2) {
            // Classic merge URL for Contacts uses repeated "cid" params.
            // goNext=1 jumps to the comparison page.
            // retURL returns user to the current Contact after completing/canceling.
            const retURL = encodeURIComponent(`/lightning/r/Contact/${this.recordId}/view`);
            const cidParams = ids.map(id => `cid=${encodeURIComponent(id)}`).join('&');
            const url = `/merge/merge.jsp?goNext=1&${cidParams}&retURL=${retURL}`;

            // Try to open in the same tab; if blocked, the DRS page is already open.
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: { url }
            });
        }
    } catch (e) {
        // Ignore; user still lands on DRS where "Compare & Merge" works.
    }
}

    // Pass two Contact Ids, including the record Id, to Apex to merge
    async handleContactMerge(event) {
        const clickedContactId = event.currentTarget.dataset.contactId;
        const recordPageContactId = this.recordId;
        
        console.log('=== Contact Merge Debug ===');
        console.log('Record Page Contact ID (original):', recordPageContactId);
        console.log('Clicked Contact ID (to merge):', clickedContactId);
        
        // Validation
        if (!recordPageContactId || !clickedContactId) {
            console.error('Missing contact IDs - cannot proceed with merge');
            return;
        }
        if (recordPageContactId === clickedContactId) {
            console.warn('Cannot merge a contact with itself');
            return;
        }
        
        // Set merging flag to disable all buttons and show spinner
        this.isMerging = true;
        
        try {
            // Call Apex merge method
            const result = await mergeContacts({
                masterContactId: recordPageContactId,
                duplicateContactId: clickedContactId
            });
            
            console.log('Merge successful:', result);
            
            // Show success toast
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Contact merged successfully. Refreshing page...',
                variant: 'success'
            }));
            
            // Refresh the page after a short delay
            setTimeout(() => {
                window.location.reload();
            }, 2000);
            
        } catch (error) {
            console.error('Merge failed:', error);
            
            // Clear the merging flag on error so buttons are re-enabled
            this.isMerging = false;
            
            // Show error toast
            this.dispatchEvent(new ShowToastEvent({
                title: 'Merge Failed',
                message: error.body?.message || 'An error occurred while merging contacts',
                variant: 'error',
                mode: 'sticky'
            }));
        }  // end try/catch
    }  // end handleContactMerge

    handleViewSet(event) {
        const setId = event.currentTarget.dataset.setId;
        if (!setId) return;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: setId,
                objectApiName: 'DuplicateRecordSet',
                actionName: 'view'
            }
        });
    }

    handleOpenContact(event) {
        const cid = event.currentTarget.dataset.contactId;
        if (!cid) return;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: cid,
                objectApiName: 'Contact',
                actionName: 'view'
            }
        });
    }

    async handleRefresh() {
        this.isLoading = true;
        try {
            await Promise.all([
                refreshApex(this._dupWireResult),
                refreshApex(this._fieldWireResult)
            ]);
        } finally {
            this.isLoading = false;
        }
    }

    // ----- Utilities -----

    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    _errorMessage(error) {
        if (!error) return 'Unknown error';
        if (typeof error === 'string') return error;
        if (error.body && typeof error.body.message === 'string') return error.body.message;
        try {
            return JSON.stringify(error);
        } catch {
            return 'Unexpected error';
        }
    }

    async _confirm(message) {
        try {
            return await LightningConfirm.open({
                message,
                variant: 'headerless',
                label: 'Confirm'
            });
        } catch {
            // Fallback if LightningConfirm isn't available in some contexts
            // eslint-disable-next-line no-alert
            return window.confirm(message);
        }
    }
}