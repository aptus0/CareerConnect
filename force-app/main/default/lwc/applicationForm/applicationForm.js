import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import submitApplication from '@salesforce/apex/JobController.submitApplication';

export default class ApplicationForm extends LightningElement {

    @api jobId;
    @api jobTitle;

    @track formData = {
        email: '',
        phone: '',
        linkedInUrl: '',
        yearsOfExperience: null,
        expectedSalary: null,
        coverLetter: ''
    };

    @track uploadedFileId   = null;
    @track uploadedFileName = null;
    @track isSubmitting     = false;
    @track submitError      = null;

    get submitLabel() {
        return this.isSubmitting ? 'Submitting...' : 'Submit Application';
    }

    get coverLetterLength() {
        return this.formData.coverLetter ? this.formData.coverLetter.length : 0;
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        this.formData = { ...this.formData, [field]: event.target.value };
    }

    handleFileUpload(event) {
        const files = event.detail.files;
        if (files && files.length > 0) {
            this.uploadedFileId   = files[0].documentId;
            this.uploadedFileName = files[0].name;
        }
    }

    handleSubmit() {
        if (!this.validateForm()) return;

        this.isSubmitting = true;
        this.submitError  = null;

        submitApplication({
            jobPositionId:      this.jobId,
            coverLetter:        this.formData.coverLetter,
            yearsOfExperience:  parseInt(this.formData.yearsOfExperience, 10),
            expectedSalary:     parseFloat(this.formData.expectedSalary) || null,
            linkedInUrl:        this.formData.linkedInUrl,
            email:              this.formData.email,
            phone:              this.formData.phone,
            cvFileId:           this.uploadedFileId
        })
        .then(() => {
            this.isSubmitting = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Application Submitted!',
                message: 'We have received your application. Check your email.',
                variant: 'success'
            }));
            this.dispatchEvent(new CustomEvent('submitted'));
        })
        .catch(error => {
            this.isSubmitting = false;
            this.submitError  = error.body?.message || 'Submission failed. Please try again.';
        });
    }

    validateForm() {
        const inputs = this.template.querySelectorAll('lightning-input, lightning-textarea');
        let valid = true;
        inputs.forEach(input => {
            if (!input.reportValidity()) valid = false;
        });

        if (!this.formData.email) {
            this.submitError = 'Email is required.';
            return false;
        }
        if (!this.formData.coverLetter || this.formData.coverLetter.length < 50) {
            this.submitError = 'Cover letter must be at least 50 characters.';
            return false;
        }

        return valid;
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}
