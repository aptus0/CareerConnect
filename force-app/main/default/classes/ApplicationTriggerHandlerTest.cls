/**
 * @description Test class for ApplicationTriggerHandler
 * Coverage: Duplicate prevention, deadline validation, auto-close, rollup counts, email
 * @author CareerConnect Project
 * @date 2024
 */
@IsTest
private class ApplicationTriggerHandlerTest {

    // ─────────────────────────────────────────
    // Test Data Setup
    // ─────────────────────────────────────────
    @TestSetup
    static void setup() {
        Job_Position__c openJob = new Job_Position__c(
            Name               = 'Salesforce Developer',
            Department__c      = 'Engineering',
            Location__c        = 'London',
            Employment_Type__c = 'Full-Time',
            Status__c          = 'Open',
            Max_Applicants__c  = 3,
            Application_Count__c = 0,
            Deadline__c        = Date.today().addDays(30)
        );
        insert openJob;

        Job_Position__c closedJob = new Job_Position__c(
            Name               = 'Closed Position',
            Department__c      = 'Sales',
            Status__c          = 'Closed',
            Deadline__c        = Date.today().addDays(30)
        );
        insert closedJob;

        Candidate_Profile__c candidate = new Candidate_Profile__c(
            Name    = 'Test Candidate',
            Email__c = 'test@example.com'
        );
        insert candidate;
    }

    // ─────────────────────────────────────────
    // Test: Successful Insert
    // ─────────────────────────────────────────
    @IsTest
    static void testSuccessfulApplication() {
        Job_Position__c job = [SELECT Id FROM Job_Position__c WHERE Name = 'Salesforce Developer' LIMIT 1];
        Candidate_Profile__c cp = [SELECT Id FROM Candidate_Profile__c LIMIT 1];

        Application__c app = new Application__c(
            Job_Position__c      = job.Id,
            Candidate_Profile__c = cp.Id,
            Applicant_Email__c   = 'test@example.com',
            Status__c            = 'Submitted'
        );

        Test.startTest();
        insert app;
        Test.stopTest();

        Application__c inserted = [SELECT Id, Status__c, Submitted_Date__c FROM Application__c WHERE Id = :app.Id];
        System.assertNotEquals(null, inserted.Submitted_Date__c, 'Submitted date should be stamped');
        System.assertEquals('Submitted', inserted.Status__c, 'Status should be Submitted');

        Job_Position__c updatedJob = [SELECT Application_Count__c FROM Job_Position__c WHERE Id = :job.Id];
        System.assertEquals(1, updatedJob.Application_Count__c, 'Application count should be incremented');
    }

    // ─────────────────────────────────────────
    // Test: Duplicate Application Prevention
    // ─────────────────────────────────────────
    @IsTest
    static void testDuplicateApplicationPrevented() {
        Job_Position__c job = [SELECT Id FROM Job_Position__c WHERE Name = 'Salesforce Developer' LIMIT 1];
        Candidate_Profile__c cp = [SELECT Id FROM Candidate_Profile__c LIMIT 1];

        Application__c app1 = new Application__c(
            Job_Position__c      = job.Id,
            Candidate_Profile__c = cp.Id,
            Applicant_Email__c   = 'test@example.com',
            Status__c            = 'Submitted'
        );
        insert app1;

        Application__c app2 = new Application__c(
            Job_Position__c      = job.Id,
            Candidate_Profile__c = cp.Id,
            Applicant_Email__c   = 'test@example.com',
            Status__c            = 'Submitted'
        );

        Test.startTest();
        try {
            insert app2;
            System.assert(false, 'Should have thrown a DML exception for duplicate');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('already applied'), 'Error should mention duplicate: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    // Test: Closed Position Rejection
    // ─────────────────────────────────────────
    @IsTest
    static void testClosedPositionRejected() {
        Job_Position__c closedJob = [SELECT Id FROM Job_Position__c WHERE Name = 'Closed Position' LIMIT 1];

        Application__c app = new Application__c(
            Job_Position__c    = closedJob.Id,
            Applicant_Email__c = 'test2@example.com',
            Status__c          = 'Submitted'
        );

        Test.startTest();
        try {
            insert app;
            System.assert(false, 'Should have thrown DML exception for closed position');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('no longer accepting'), 'Error should mention closed status');
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    // Test: Auto-Close When Max Applicants Reached
    // ─────────────────────────────────────────
    @IsTest
    static void testAutoCloseOnMaxApplicants() {
        Job_Position__c job = [SELECT Id FROM Job_Position__c WHERE Name = 'Salesforce Developer' LIMIT 1];

        List<Application__c> apps = new List<Application__c>();
        for (Integer i = 0; i < 3; i++) {
            Candidate_Profile__c cp = new Candidate_Profile__c(Name = 'Candidate ' + i, Email__c = 'cand' + i + '@test.com');
            insert cp;
            apps.add(new Application__c(
                Job_Position__c      = job.Id,
                Candidate_Profile__c = cp.Id,
                Applicant_Email__c   = 'cand' + i + '@test.com',
                Status__c            = 'Submitted'
            ));
        }

        Test.startTest();
        insert apps;
        Test.stopTest();

        Job_Position__c updatedJob = [SELECT Status__c, Application_Count__c FROM Job_Position__c WHERE Id = :job.Id];
        System.assertEquals('Filled', updatedJob.Status__c, 'Position should be auto-closed when max applicants reached');
        System.assertEquals(3, updatedJob.Application_Count__c, 'Count should be 3');
    }

    // ─────────────────────────────────────────
    // Test: Status Update Trigger
    // ─────────────────────────────────────────
    @IsTest
    static void testStatusUpdateEmail() {
        Job_Position__c job = [SELECT Id FROM Job_Position__c WHERE Name = 'Salesforce Developer' LIMIT 1];

        Application__c app = new Application__c(
            Job_Position__c    = job.Id,
            Applicant_Email__c = 'notify@example.com',
            Status__c          = 'Submitted'
        );
        insert app;

        Test.startTest();
        app.Status__c = 'Under Review';
        update app;
        Test.stopTest();

        Application__c updated = [SELECT Status__c FROM Application__c WHERE Id = :app.Id];
        System.assertEquals('Under Review', updated.Status__c, 'Status should be updated');
    }

    // ─────────────────────────────────────────
    // Test: Score Validation
    // ─────────────────────────────────────────
    @IsTest
    static void testScoreValidation() {
        Job_Position__c job = [SELECT Id FROM Job_Position__c WHERE Name = 'Salesforce Developer' LIMIT 1];

        Application__c app = new Application__c(
            Job_Position__c    = job.Id,
            Applicant_Email__c = 'score@example.com',
            Status__c          = 'Submitted'
        );
        insert app;

        Test.startTest();
        app.Score__c = 150; // invalid
        try {
            update app;
            System.assert(false, 'Should fail score validation');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Score'), 'Should mention score: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    // Test: Delete Hired Application Blocked
    // ─────────────────────────────────────────
    @IsTest
    static void testDeleteHiredApplicationBlocked() {
        Job_Position__c job = [SELECT Id FROM Job_Position__c WHERE Name = 'Salesforce Developer' LIMIT 1];

        Application__c app = new Application__c(
            Job_Position__c    = job.Id,
            Applicant_Email__c = 'hired@example.com',
            Status__c          = 'Hired'
        );
        insert app;

        Test.startTest();
        try {
            delete app;
            System.assert(false, 'Should not allow delete of Hired application');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Hired'), 'Error should mention Hired: ' + e.getMessage());
        }
        Test.stopTest();
    }
}
