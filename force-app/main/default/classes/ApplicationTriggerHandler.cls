/**
 * @description Handler class for ApplicationTrigger
 * Implements: Duplicate prevention, email notifications, position auto-close,
 *             application count rollup, score validation
 * @author CareerConnect Project
 * @date 2024
 */
public with sharing class ApplicationTriggerHandler {

    // ─────────────────────────────────────────
    // BEFORE INSERT
    // ─────────────────────────────────────────
    public void onBeforeInsert(List<Application__c> newList) {
        preventDuplicateApplications(newList, null);
        stampSubmittedDate(newList);
        validateDeadline(newList);
    }

    // ─────────────────────────────────────────
    // BEFORE UPDATE
    // ─────────────────────────────────────────
    public void onBeforeUpdate(List<Application__c> newList, Map<Id, Application__c> oldMap) {
        validateScoreRange(newList);
    }

    // ─────────────────────────────────────────
    // BEFORE DELETE
    // ─────────────────────────────────────────
    public void onBeforeDelete(List<Application__c> oldList) {
        preventDeleteOnHiredApplications(oldList);
    }

    // ─────────────────────────────────────────
    // AFTER INSERT
    // ─────────────────────────────────────────
    public void onAfterInsert(List<Application__c> newList) {
        updateJobPositionCount(newList, 'increment');
        updateCandidateTotalApplications(newList, 'increment');
        sendSubmissionConfirmationEmail(newList);
        autoCloseFullPositions(newList);
    }

    // ─────────────────────────────────────────
    // AFTER UPDATE
    // ─────────────────────────────────────────
    public void onAfterUpdate(List<Application__c> newList, Map<Id, Application__c> oldMap) {
        List<Application__c> statusChanged = new List<Application__c>();
        for (Application__c app : newList) {
            if (app.Status__c != oldMap.get(app.Id).Status__c) {
                statusChanged.add(app);
            }
        }
        if (!statusChanged.isEmpty()) {
            sendStatusChangeEmail(statusChanged, oldMap);
        }
    }

    // ─────────────────────────────────────────
    // PRIVATE METHODS
    // ─────────────────────────────────────────

    /**
     * @description Prevents a candidate from applying to the same position twice
     */
    private void preventDuplicateApplications(List<Application__c> newList, Map<Id, Application__c> oldMap) {
        Set<Id> jobIds = new Set<Id>();
        Set<Id> candidateIds = new Set<Id>();

        for (Application__c app : newList) {
            if (app.Job_Position__c != null && app.Candidate_Profile__c != null) {
                jobIds.add(app.Job_Position__c);
                candidateIds.add(app.Candidate_Profile__c);
            }
        }

        if (jobIds.isEmpty()) return;

        List<Application__c> existingApps = [
            SELECT Id, Job_Position__c, Candidate_Profile__c
            FROM Application__c
            WHERE Job_Position__c IN :jobIds
            AND Candidate_Profile__c IN :candidateIds
            WITH SECURITY_ENFORCED
        ];

        Map<String, Boolean> existingKey = new Map<String, Boolean>();
        for (Application__c existing : existingApps) {
            existingKey.put(existing.Job_Position__c + '_' + existing.Candidate_Profile__c, true);
        }

        for (Application__c app : newList) {
            String key = app.Job_Position__c + '_' + app.Candidate_Profile__c;
            if (existingKey.containsKey(key)) {
                app.addError('You have already applied for this position. Duplicate applications are not allowed.');
            }
        }
    }

    /**
     * @description Stamps current datetime as submitted date
     */
    private void stampSubmittedDate(List<Application__c> newList) {
        for (Application__c app : newList) {
            if (app.Submitted_Date__c == null) {
                app.Submitted_Date__c = System.now();
            }
        }
    }

    /**
     * @description Validates application is submitted before deadline
     */
    private void validateDeadline(List<Application__c> newList) {
        Set<Id> jobIds = new Set<Id>();
        for (Application__c app : newList) {
            jobIds.add(app.Job_Position__c);
        }

        Map<Id, Job_Position__c> jobMap = new Map<Id, Job_Position__c>([
            SELECT Id, Deadline__c, Status__c
            FROM Job_Position__c
            WHERE Id IN :jobIds
            WITH SECURITY_ENFORCED
        ]);

        for (Application__c app : newList) {
            Job_Position__c job = jobMap.get(app.Job_Position__c);
            if (job != null) {
                if (job.Status__c != 'Open') {
                    app.addError('This position is no longer accepting applications (Status: ' + job.Status__c + ').');
                }
                if (job.Deadline__c != null && job.Deadline__c < Date.today()) {
                    app.addError('The application deadline for this position has passed (' + job.Deadline__c.format() + ').');
                }
            }
        }
    }

    /**
     * @description Validates score is between 0 and 100
     */
    private void validateScoreRange(List<Application__c> newList) {
        for (Application__c app : newList) {
            if (app.Score__c != null && (app.Score__c < 0 || app.Score__c > 100)) {
                app.Score__c.addError('Score must be between 0 and 100.');
            }
        }
    }

    /**
     * @description Prevents deletion of Hired applications for audit trail
     */
    private void preventDeleteOnHiredApplications(List<Application__c> oldList) {
        for (Application__c app : oldList) {
            if (app.Status__c == 'Hired') {
                app.addError('Hired applications cannot be deleted. Please archive instead.');
            }
        }
    }

    /**
     * @description Rollup: updates Application_Count__c on Job_Position__c
     */
    private void updateJobPositionCount(List<Application__c> apps, String operation) {
        Set<Id> jobIds = new Set<Id>();
        for (Application__c app : apps) {
            jobIds.add(app.Job_Position__c);
        }

        Map<Id, Integer> countMap = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Job_Position__c, COUNT(Id) cnt
            FROM Application__c
            WHERE Job_Position__c IN :jobIds
            GROUP BY Job_Position__c
        ]) {
            countMap.put((Id) ar.get('Job_Position__c'), (Integer) ar.get('cnt'));
        }

        List<Job_Position__c> jobsToUpdate = new List<Job_Position__c>();
        for (Id jobId : jobIds) {
            jobsToUpdate.add(new Job_Position__c(
                Id = jobId,
                Application_Count__c = countMap.containsKey(jobId) ? countMap.get(jobId) : 0
            ));
        }

        if (!jobsToUpdate.isEmpty()) {
            update jobsToUpdate;
        }
    }

    /**
     * @description Rollup: updates Total_Applications__c on Candidate_Profile__c
     */
    private void updateCandidateTotalApplications(List<Application__c> apps, String operation) {
        Set<Id> candidateIds = new Set<Id>();
        for (Application__c app : apps) {
            if (app.Candidate_Profile__c != null) {
                candidateIds.add(app.Candidate_Profile__c);
            }
        }
        if (candidateIds.isEmpty()) return;

        Map<Id, Integer> countMap = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Candidate_Profile__c, COUNT(Id) cnt
            FROM Application__c
            WHERE Candidate_Profile__c IN :candidateIds
            GROUP BY Candidate_Profile__c
        ]) {
            countMap.put((Id) ar.get('Candidate_Profile__c'), (Integer) ar.get('cnt'));
        }

        List<Candidate_Profile__c> toUpdate = new List<Candidate_Profile__c>();
        for (Id cid : candidateIds) {
            toUpdate.add(new Candidate_Profile__c(
                Id = cid,
                Total_Applications__c = countMap.containsKey(cid) ? countMap.get(cid) : 0
            ));
        }
        update toUpdate;
    }

    /**
     * @description Auto-closes a Job Position when Max_Applicants__c is reached
     */
    private void autoCloseFullPositions(List<Application__c> newApps) {
        Set<Id> jobIds = new Set<Id>();
        for (Application__c app : newApps) {
            jobIds.add(app.Job_Position__c);
        }

        List<Job_Position__c> jobs = [
            SELECT Id, Max_Applicants__c, Application_Count__c, Status__c
            FROM Job_Position__c
            WHERE Id IN :jobIds
            WITH SECURITY_ENFORCED
        ];

        List<Job_Position__c> toClose = new List<Job_Position__c>();
        for (Job_Position__c job : jobs) {
            if (job.Max_Applicants__c != null &&
                job.Application_Count__c >= job.Max_Applicants__c &&
                job.Status__c == 'Open') {
                toClose.add(new Job_Position__c(Id = job.Id, Status__c = 'Filled'));
            }
        }
        if (!toClose.isEmpty()) {
            update toClose;
        }
    }

    /**
     * @description Sends confirmation email upon successful application submission
     */
    private void sendSubmissionConfirmationEmail(List<Application__c> newApps) {
        Set<Id> jobIds = new Set<Id>();
        for (Application__c app : newApps) jobIds.add(app.Job_Position__c);

        Map<Id, Job_Position__c> jobMap = new Map<Id, Job_Position__c>([
            SELECT Id, Name FROM Job_Position__c WHERE Id IN :jobIds
        ]);

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Application__c app : newApps) {
            if (String.isNotBlank(app.Applicant_Email__c)) {
                Job_Position__c job = jobMap.get(app.Job_Position__c);
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{ app.Applicant_Email__c });
                email.setSubject('Application Submitted – ' + (job != null ? job.Name : 'Position'));
                email.setHtmlBody(
                    '<h2>Thank you for applying!</h2>' +
                    '<p>Your application (<strong>' + app.Name + '</strong>) for <strong>' +
                    (job != null ? job.Name : 'the position') +
                    '</strong> has been successfully submitted.</p>' +
                    '<p>We will review your application and be in touch. Good luck!</p>' +
                    '<br/><p>CareerConnect Team</p>'
                );
                email.setSaveAsActivity(false);
                emails.add(email);
            }
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    /**
     * @description Sends status change notification email to applicant
     */
    private void sendStatusChangeEmail(List<Application__c> changedApps, Map<Id, Application__c> oldMap) {
        Set<Id> jobIds = new Set<Id>();
        for (Application__c app : changedApps) jobIds.add(app.Job_Position__c);

        Map<Id, Job_Position__c> jobMap = new Map<Id, Job_Position__c>([
            SELECT Id, Name FROM Job_Position__c WHERE Id IN :jobIds
        ]);

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Application__c app : changedApps) {
            if (String.isNotBlank(app.Applicant_Email__c)) {
                String jobName = jobMap.containsKey(app.Job_Position__c)
                    ? jobMap.get(app.Job_Position__c).Name
                    : 'your position';

                String statusMsg = buildStatusMessage(app.Status__c, jobName, app.Rejection_Reason__c);

                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{ app.Applicant_Email__c });
                email.setSubject('Application Update: ' + app.Status__c + ' – ' + jobName);
                email.setHtmlBody(statusMsg);
                email.setSaveAsActivity(false);
                emails.add(email);
            }
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    private String buildStatusMessage(String status, String jobName, String rejectionReason) {
        String body = '<h2>Your Application Status Has Changed</h2>';
        body += '<p>Your application for <strong>' + jobName + '</strong> is now: <strong>' + status + '</strong></p>';

        switch on status {
            when 'Under Review' {
                body += '<p>Our hiring team is currently reviewing your application. We will be in touch shortly.</p>';
            }
            when 'Interview Scheduled' {
                body += '<p>Congratulations! We would like to schedule an interview. Please check your calendar invitation or contact us for details.</p>';
            }
            when 'Offer Extended' {
                body += '<p>🎉 Congratulations! We are pleased to extend an offer. Please review the details and respond within 5 business days.</p>';
            }
            when 'Hired' {
                body += '<p>🎊 Welcome aboard! We are thrilled to have you join the team. Onboarding details will follow shortly.</p>';
            }
            when 'Rejected' {
                body += '<p>Thank you for your interest and time. After careful consideration, we have decided to move forward with other candidates.</p>';
                if (String.isNotBlank(rejectionReason)) {
                    body += '<p><em>Feedback: ' + rejectionReason + '</em></p>';
                }
            }
        }

        body += '<br/><p>CareerConnect Team</p>';
        return body;
    }
}
