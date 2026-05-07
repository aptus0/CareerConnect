import { LightningElement, api, track, wire } from 'lwc';
import getJobById from '@salesforce/apex/JobController.getJobById';
import hasAlreadyApplied from '@salesforce/apex/JobController.hasAlreadyApplied';

export default class JobDetailCard extends LightningElement {

    @api jobId;
    @track job;
    @track isLoading = true;
    @track alreadyApplied = false;
    @track showApplicationForm = false;
    @track error;

    connectedCallback() {
        this.fetchJob();
        this.checkExistingApplication();
    }

    fetchJob() {
        getJobById({ jobId: this.jobId })
            .then(data => {
                this.job = data;
                this.isLoading = false;
            })
            .catch(err => {
                this.error = err;
                this.isLoading = false;
            });
    }

    checkExistingApplication() {
        hasAlreadyApplied({ jobPositionId: this.jobId })
            .then(result => { this.alreadyApplied = result; })
            .catch(() => { /* silently fail */ });
    }

    get formattedDeadline() {
        if (!this.job || !this.job.Deadline__c) return 'Open until filled';
        const d = new Date(this.job.Deadline__c);
        return d.toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });
    }

    handleApplyClick() {
        this.showApplicationForm = true;
    }

    handleFormCancel() {
        this.showApplicationForm = false;
    }

    handleFormSubmitted() {
        this.showApplicationForm = false;
        this.alreadyApplied = true;
        this.dispatchEvent(new CustomEvent('applied'));
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleOverlayClick() {
        this.handleClose();
    }

    stopPropagation(event) {
        event.stopPropagation();
    }
}
