import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAllApplications from '@salesforce/apex/JobController.getAllApplications';
import updateApplicationStatus from '@salesforce/apex/JobController.updateApplicationStatus';
import getDashboardStats from '@salesforce/apex/JobController.getDashboardStats';
import getOpenJobs from '@salesforce/apex/JobController.getOpenJobs';

export default class AdminDashboard extends LightningElement {

    @track applications   = [];
    @track stats          = { openJobs: 0, totalApplications: 0, pendingReview: 0, hiredThisMonth: 0 };
    @track jobOptions     = [{ label: 'All Positions', value: '' }];
    @track filterStatus   = '';
    @track filterJobId    = '';
    @track showStatusModal = false;
    @track selectedApp    = null;
    @track newStatus      = '';
    @track newScore       = null;
    @track rejectionReason = '';
    @track sortedBy       = 'Submitted_Date__c';
    @track sortedDirection = 'desc';

    statusOptions = [
        { label: 'All',                value: '' },
        { label: 'Submitted',          value: 'Submitted' },
        { label: 'Under Review',       value: 'Under Review' },
        { label: 'Interview Scheduled',value: 'Interview Scheduled' },
        { label: 'Technical Assessment', value: 'Technical Assessment' },
        { label: 'Offer Extended',     value: 'Offer Extended' },
        { label: 'Hired',              value: 'Hired' },
        { label: 'Rejected',           value: 'Rejected' },
        { label: 'Withdrawn',          value: 'Withdrawn' }
    ];

    columns = [
        { label: 'Ref #',      fieldName: 'Name',              type: 'text', sortable: true },
        { label: 'Position',   fieldName: 'jobTitle',          type: 'text', sortable: true },
        { label: 'Email',      fieldName: 'Applicant_Email__c',type: 'email' },
        { label: 'Status',     fieldName: 'Status__c',         type: 'text', sortable: true },
        { label: 'Score',      fieldName: 'Score__c',          type: 'number' },
        { label: 'Experience', fieldName: 'Years_of_Experience__c', type: 'number' },
        { label: 'Submitted',  fieldName: 'Submitted_Date__c', type: 'date', sortable: true },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Update Status', name: 'update_status' },
                    { label: 'View LinkedIn',  name: 'view_linkedin' },
                    { label: 'Download CV',   name: 'download_cv' }
                ]
            }
        }
    ];

    connectedCallback() {
        this.loadStats();
        this.loadJobs();
        this.loadApplications();
    }

    loadStats() {
        getDashboardStats()
            .then(data => { this.stats = data; })
            .catch(() => {});
    }

    loadJobs() {
        getOpenJobs({ department: null, employmentType: null, remoteOnly: false, searchTerm: null })
            .then(data => {
                const opts = data.map(j => ({ label: j.Name, value: j.Id }));
                this.jobOptions = [{ label: 'All Positions', value: '' }, ...opts];
            })
            .catch(() => {});
    }

    loadApplications() {
        getAllApplications({
            jobPositionId: this.filterJobId || null,
            status:        this.filterStatus || null
        })
        .then(data => {
            this.applications = data.map(app => ({
                ...app,
                jobTitle: app.Job_Position__r ? app.Job_Position__r.Name : ''
            }));
        })
        .catch(() => {});
    }

    handleStatusFilter(event) {
        this.filterStatus = event.detail.value;
        this.loadApplications();
    }

    handleJobFilter(event) {
        this.filterJobId = event.detail.value;
        this.loadApplications();
    }

    handleSort(event) {
        this.sortedBy        = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.applications = [...this.applications].sort((a, b) => {
            const aVal = a[this.sortedBy] || '';
            const bVal = b[this.sortedBy] || '';
            return this.sortedDirection === 'asc'
                ? (aVal > bVal ? 1 : -1)
                : (aVal < bVal ? 1 : -1);
        });
    }

    handleRowAction(event) {
        const action = event.detail.action.name;
        const row    = event.detail.row;

        if (action === 'update_status') {
            this.selectedApp     = row;
            this.newStatus       = row.Status__c;
            this.showStatusModal = true;
        } else if (action === 'view_linkedin' && row.LinkedIn_URL__c) {
            window.open(row.LinkedIn_URL__c, '_blank');
        } else if (action === 'download_cv' && row.CV_File_Id__c) {
            window.open('/sfc/servlet.shepherd/document/download/' + row.CV_File_Id__c, '_blank');
        }
    }

    handleNewStatusChange(event) { this.newStatus      = event.detail.value; }
    handleScoreChange(event)     { this.newScore       = event.target.value; }
    handleReasonChange(event)    { this.rejectionReason = event.target.value; }

    submitStatusUpdate() {
        if (!this.newStatus) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: 'Please select a status.', variant: 'error' }));
            return;
        }

        updateApplicationStatus({
            applicationId:    this.selectedApp.Id,
            newStatus:        this.newStatus,
            rejectionReason:  this.rejectionReason,
            score:            this.newScore ? parseFloat(this.newScore) : null
        })
        .then(() => {
            this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Application updated.', variant: 'success' }));
            this.closeStatusModal();
            this.loadApplications();
            this.loadStats();
        })
        .catch(err => {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err.body?.message, variant: 'error' }));
        });
    }

    closeStatusModal() {
        this.showStatusModal  = false;
        this.selectedApp      = null;
        this.newStatus        = '';
        this.newScore         = null;
        this.rejectionReason  = '';
    }
}
