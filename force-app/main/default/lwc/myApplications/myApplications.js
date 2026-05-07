import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyApplications from '@salesforce/apex/JobController.getMyApplications';

const STATUS_ORDER = [
    'Submitted', 'Under Review', 'Interview Scheduled',
    'Technical Assessment', 'Offer Extended', 'Hired'
];

const STATUS_COLORS = {
    'Submitted':            'status-submitted',
    'Under Review':         'status-review',
    'Interview Scheduled':  'status-interview',
    'Technical Assessment': 'status-assessment',
    'Offer Extended':       'status-offer',
    'Hired':                'status-hired',
    'Rejected':             'status-rejected',
    'Withdrawn':            'status-withdrawn'
};

export default class MyApplications extends NavigationMixin(LightningElement) {

    @track applications = [];
    @track isLoading = true;

    get statusSteps() {
        return STATUS_ORDER.map(s => ({ label: s, stepClass: 'step' }));
    }

    connectedCallback() {
        this.loadApplications();
    }

    loadApplications() {
        getMyApplications()
            .then(data => {
                this.applications = data.map(app => ({
                    ...app,
                    statusClass: 'status-badge ' + (STATUS_COLORS[app.Status__c] || 'status-submitted'),
                    cardClass: 'app-card' + (app.Status__c === 'Rejected' ? ' app-card-rejected' : ''),
                    formattedDate: app.Submitted_Date__c
                        ? new Date(app.Submitted_Date__c).toLocaleDateString('en-GB', {
                            day: 'numeric', month: 'short', year: 'numeric'
                          })
                        : '',
                    formattedInterview: app.Interview_Date__c
                        ? new Date(app.Interview_Date__c).toLocaleString('en-GB', {
                            day: 'numeric', month: 'short', year: 'numeric',
                            hour: '2-digit', minute: '2-digit'
                          })
                        : ''
                }));
                this.isLoading = false;
            })
            .catch(() => { this.isLoading = false; });
    }

    get hasApplications() {
        return this.applications && this.applications.length > 0;
    }

    handleBrowse() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Jobs__c' }
        });
    }
}
