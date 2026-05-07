import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpenJobs from '@salesforce/apex/JobController.getOpenJobs';

export default class JobListings extends LightningElement {

    @track searchTerm       = '';
    @track selectedDepartment = '';
    @track selectedType     = '';
    @track remoteOnly       = false;
    @track showModal        = false;
    @track selectedJobId    = null;
    @track isLoading        = false;
    @track jobs             = [];
    @track error            = null;

    // Debounce timer for search
    _searchDebounce;

    departmentOptions = [
        { label: 'All Departments', value: '' },
        { label: 'Engineering',     value: 'Engineering' },
        { label: 'Marketing',       value: 'Marketing' },
        { label: 'Sales',           value: 'Sales' },
        { label: 'HR',              value: 'HR' },
        { label: 'Finance',         value: 'Finance' },
        { label: 'Operations',      value: 'Operations' }
    ];

    typeOptions = [
        { label: 'All Types',   value: '' },
        { label: 'Full-Time',   value: 'Full-Time' },
        { label: 'Part-Time',   value: 'Part-Time' },
        { label: 'Contract',    value: 'Contract' },
        { label: 'Internship',  value: 'Internship' }
    ];

    connectedCallback() {
        this.loadJobs();
    }

    loadJobs() {
        this.isLoading = true;
        this.error = null;

        getOpenJobs({
            department:     this.selectedDepartment || null,
            employmentType: this.selectedType || null,
            remoteOnly:     this.remoteOnly,
            searchTerm:     this.searchTerm || null
        })
        .then(data => {
            this.jobs = data.map(job => ({
                ...job,
                Description__c: job.Description__c
                    ? job.Description__c.substring(0, 150) + '...'
                    : ''
            }));
            this.isLoading = false;
        })
        .catch(error => {
            this.error = error;
            this.isLoading = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error loading jobs',
                message: error.body?.message || 'Unknown error',
                variant: 'error'
            }));
        });
    }

    get hasJobs() {
        return this.jobs && this.jobs.length > 0;
    }

    handleSearchChange(event) {
        clearTimeout(this._searchDebounce);
        const value = event.target.value;
        this._searchDebounce = setTimeout(() => {
            this.searchTerm = value;
            this.loadJobs();
        }, 400);
    }

    handleDepartmentChange(event) {
        this.selectedDepartment = event.detail.value;
        this.loadJobs();
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
        this.loadJobs();
    }

    handleRemoteToggle(event) {
        this.remoteOnly = event.target.checked;
        this.loadJobs();
    }

    handleViewJob(event) {
        event.stopPropagation();
        this.selectedJobId = event.target.dataset.id;
        this.showModal = true;
    }

    handleJobClick(event) {
        this.selectedJobId = event.currentTarget.dataset.id;
        this.showModal = true;
    }

    handleCloseModal() {
        this.showModal = false;
        this.selectedJobId = null;
    }

    handleApplicationSubmitted() {
        this.showModal = false;
        this.loadJobs(); // refresh counts
        this.dispatchEvent(new ShowToastEvent({
            title: 'Application Submitted!',
            message: 'Your application has been submitted. Check your email for confirmation.',
            variant: 'success'
        }));
    }
}
