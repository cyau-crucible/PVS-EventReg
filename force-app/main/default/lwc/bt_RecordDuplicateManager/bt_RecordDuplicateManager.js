import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import LightningConfirm from 'lightning/confirm';

import getDuplicateSets from '@salesforce/apex/ContactDuplicateSetsController.getDuplicateSets';
import getContactFieldSet from '@salesforce/apex/ContactDuplicateSetsController.getContactFieldSet';
import approveContactFromSet from '@salesforce/apex/ContactDuplicateSetsController.approveContactFromSet';
import getRecordComparison from '@salesforce/apex/ContactDuplicateSetsController.getRecordComparison';
import mergeContactsWithSelections from '@salesforce/apex/ContactDuplicateSetsController.mergeContactsNew';

export default class ContactDuplicateManager extends NavigationMixin(LightningElement) {
    /** Record page injects this automatically */
    @api recordId;

    /** Configurable in App Builder */
    @api fieldSetName = 'Duplicate_Review';
    @api fieldSetMergeName = 'Duplicate_Review';
    @api maxSets = 25;

    @track fieldDescriptors = [];
    @track sets = [];
    @track setsWithMeta = [];  // Enhanced sets with metadata for template
    isLoading = true;
    isMerging = false;  // tracks if a merge is in progress

    // NEW: Modal and merge field selection state (using universal wrappers)
    isQuickMergeModalOpen = false;
    isMergeLoading = false;
    targetContactId = null;  // Will be set when Quick Merge button is clicked
    comparisonData = null;    // UniversalRecordComparison from Apex
    mergeFieldList = [];      // Built from comparisonData.fields
    mergeFieldSelections = {};
    hasChanges = false;

    // store wire results for refresh
    _dupWireResult;
    _fieldWireResult;

    get hasSets() {
        return (this.sets && this.sets.length > 0);
    }
    get _fieldSetName() {
        return this.fieldSetName;
    }

    // NEW: Computed properties for modal
    get hasMergeFields() {
        return this.mergeFieldList && this.mergeFieldList.length > 0;
    }

    get mergeButtonDisabled() {
        return this.isMergeLoading || !this.hasMergeFields;
    }

    get masterContactName() {
        return this.comparisonData?.masterName || 'Master Contact';
    }

    get targetContactName() {
        return this.comparisonData?.targetName || 'Target Contact';
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
            
            // Create enhanced version with metadata for template
            this.setsWithMeta = this.sets.map(s => ({
                ...s,
                duplicateContactsWithMeta: (s.duplicateContactIds || []).map(contactId => ({
                    contactId: contactId,
                    isCurrentRecord: contactId === this.recordId
                }))
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
        const setId = event.currentTarget.dataset.setId;
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
        try {
            // Find this set in local state
            const s = (this.sets || []).find(x => x.setId === setId);
            if (!s) return;

            // Build up to 3 contact IDs: current record + first two duplicates
            const ids = [this.recordId, ...(s.duplicateContactIds || []).slice(0, 2)];

            if (ids.length >= 2) {
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

    // NEW: Open merge modal instead of immediate merge
    async handleOpenMergeModal(event) {
        const clickedContactId = event.currentTarget.dataset.contactId;
        const recordPageContactId = this.recordId;
        
        console.log('=== Opening Merge Modal ===');
        console.log('Master Contact ID:', recordPageContactId);
        console.log('Target Contact ID:', clickedContactId);
        
        // Validation
        if (!recordPageContactId || !clickedContactId) {
            console.error('Missing contact IDs - cannot proceed');
            return;
        }
        if (recordPageContactId === clickedContactId) {
            console.warn('Cannot merge a contact with itself');
            return;
        }
        
        // Store the target contact ID
        this.targetContactId = clickedContactId;
        
        // Open modal and load data
        this.isQuickMergeModalOpen = true;
        await this.loadMergeFieldsAndContacts();
    }

    // NEW: Load field set and contact data for merge using universal wrapper
    async loadMergeFieldsAndContacts() {
        this.isMergeLoading = true;
        
        try {
            // Call universal comparison method
            const comparison = await getRecordComparison({
                masterId: this.recordId,
                targetId: this.targetContactId,
                fieldSetName: this.fieldSetMergeName,
                objectType: 'Contact'  // For now, hardcoded - can be made dynamic later
            });
            
            if (!comparison) {
                throw new Error('Failed to retrieve record comparison data');
            }
            
            console.log('Universal comparison received:', comparison);
            
            // Store comparison data
            this.comparisonData = comparison;
            
            // Build field list for display from universal field data
            this.mergeFieldList = (comparison.fields || []).map(field => {
                return {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    fieldType: field.fieldType,
                    isUpdateable: field.isUpdateable,
                    masterValue: field.masterValue,
                    targetValue: field.targetValue,
                    selection: 'master',  // Default to master
                    // Computed properties for template
                    isMasterSelected: true,
                    isTargetSelected: false,
                    selectedClass: 'selected-value',
                    targetSelectedClass: '',
                    // Unique IDs for radio buttons
                    masterRadioId: field.fieldName + '_master',
                    targetRadioId: field.fieldName + '_target'
                };
            });

            // Initialize field selections (only for updateable fields)
            this.mergeFieldSelections = {};
            this.mergeFieldList.forEach(field => {
                if (field.isUpdateable) {
                    this.mergeFieldSelections[field.fieldName] = 'master';
                }
            });
            
        } catch (error) {
            console.error('Error loading merge data:', error);
            this._toast(
                'Error',
                error.body?.message || error.message || 'Failed to load merge data',
                'error'
            );
            this.handleCloseMergeModal();
        } finally {
            this.isMergeLoading = false;
        }
    }

    // NEW: Handle field selection change in modal
    handleFieldSelectionChange(event) {
        const fieldName = event.target.dataset.fieldname;
        const selection = event.target.value;
        
        console.log('Field selection changed:', fieldName, '=', selection);
        
        // Update selection in mergeFieldSelections
        this.mergeFieldSelections[fieldName] = selection;
        
        // Update selection in mergeFieldList for UI
        this.mergeFieldList = this.mergeFieldList.map(field => {
            if (field.fieldName === fieldName) {
                return {
                    ...field,
                    selection: selection,
                    isMasterSelected: selection === 'master',
                    isTargetSelected: selection === 'target',
                    selectedClass: selection === 'master' ? 'selected-value' : '',
                    targetSelectedClass: selection === 'target' ? 'selected-value' : ''
                };
            }
            return field;
        });
        
        this.hasChanges = true;
    }

    // NEW: Execute merge with field selections
    async handleExecuteMerge() {
        this.isMergeLoading = true;
        this.isMerging = true;  // Also set the global merging flag
        
        try {
            // Validate we have selections
            if (!this.mergeFieldSelections || Object.keys(this.mergeFieldSelections).length === 0) {
                throw new Error('No field selections found');
            }
            
            console.log('Executing merge with selections:', this.mergeFieldSelections);

            // Filter selections to only include updateable fields
            const updateableSelections = {};
            Object.keys(this.mergeFieldSelections).forEach(fieldName => {
                const field = this.mergeFieldList.find(f => f.fieldName === fieldName);
                if (field && field.isUpdateable) {
                    updateableSelections[fieldName] = this.mergeFieldSelections[fieldName];
                }
            });

            // Call the new Apex merge method with field selections
            const mergeResult = await mergeContactsWithSelections({
                masterId: this.recordId,
                targetId: this.targetContactId,
                fieldSelections: updateableSelections
            });
            
            if (mergeResult.success) {
                // Show success message
                this._toast(
                    'Success',
                    'Contacts merged successfully. Refreshing page...',
                    'success'
                );
                
                // Reset component state
                this.resetMergeState();
                
                // Close modal
                this.isQuickMergeModalOpen = false;
                
                // Refresh the page after a short delay
                setTimeout(() => {
                    window.location.reload();
                }, 2000);
                
            } else {
                // Show error message
                this._toast(
                    'Merge Failed',
                    mergeResult.message || 'An error occurred during merge',
                    'error'
                );
                this.isMerging = false;
            }
            
        } catch (error) {
            console.error('Error during merge:', error);
            this._toast(
                'Error',
                error.body?.message || error.message || 'Failed to merge contacts',
                'error'
            );
            this.isMerging = false;
        } finally {
            this.isMergeLoading = false;
        }
    }

    // NEW: Close merge modal
    handleCloseMergeModal() {
        if (this.hasChanges) {
            // Optionally show confirmation dialog
            if (confirm('You have unsaved changes. Are you sure you want to cancel?')) {
                this.isQuickMergeModalOpen = false;
                this.resetMergeState();
            }
        } else {
            this.isQuickMergeModalOpen = false;
            this.resetMergeState();
        }
    }

    // NEW: Reset merge state
    resetMergeState() {
        this.targetContactId = null;
        this.comparisonData = null;
        this.mergeFieldList = [];
        this.mergeFieldSelections = {};
        this.isMergeLoading = false;
        this.hasChanges = false;
    }

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