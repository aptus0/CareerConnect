/**
 * @description Apex Controller for LWC components
 * Used by: jobListings, jobDetailCard, applicationForm, myApplications, adminDashboard
 * @author CareerConnect Project
 * @date 2024
 */
public with sharing class JobController {

    // ─────────────────────────────────────────
    // Job Listings
    // ─────────────────────────────────────────
    @AuraEnabled(cacheable=true)
    public static List<Job_Position__c> getOpenJobs(
        String department,
        String employmentType,
        Boolean remoteOnly,
        String searchTerm
    ) {
        String query = 'SELECT Id, Name, Department__c, Location__c, Employment_Type__c, ' +
                       'Salary_Range__c, Description__c, Requirements__c, Status__c, ' +
                       'Remote_Eligible__c, Deadline__c, Posted_Date__c, Application_Count__c ' +
                       'FROM Job_Position__c WHERE Status__c = \'Open\'';

        if (String.isNotBlank(department))     query += ' AND Department__c = :department';
        if (String.isNotBlank(employmentType)) query += ' AND Employment_Type__c = :employmentType';
        if (remoteOnly == true)                query += ' AND Remote_Eligible__c = true';
        if (String.isNotBlank(searchTerm)) {
            String like1 = '%' + searchTerm + '%';
            query += ' AND (Name LIKE :like1 OR Description__c LIKE :like1)';
        }
        query += ' ORDER BY Posted_Date__c DESC NULLS LAST LIMIT 50';

        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static Job_Position__c getJobById(Id jobId) {
        return [
            SELECT Id, Name, Department__c, Location__c, Employment_Type__c,
                   Salary_Range__c, Description__c, Requirements__c, Status__c,
                   Remote_Eligible__c, Deadline__c, Posted_Date__c,
                   Application_Count__c, Max_Applicants__c
            FROM Job_Position__c
            WHERE Id = :jobId
            WITH SECURITY_ENFORCED
        ];
    }

    // ─────────────────────────────────────────
    // Applications
    // ─────────────────────────────────────────
    @AuraEnabled
    public static Id submitApplication(
        Id jobPositionId,
        String coverLetter,
        Integer yearsOfExperience,
        Decimal expectedSalary,
        String linkedInUrl,
        String email,
        String phone,
        String cvFileId
    ) {
        // Get or create candidate profile
        Id candidateId = getOrCreateCandidateProfile(email, phone);

        Application__c app = new Application__c(
            Job_Position__c      = jobPositionId,
            Candidate_Profile__c = candidateId,
            Cover_Letter__c      = coverLetter,
            Years_of_Experience__c = yearsOfExperience,
            Expected_Salary__c   = expectedSalary,
            LinkedIn_URL__c      = linkedInUrl,
            Applicant_Email__c   = email,
            Applicant_Phone__c   = phone,
            CV_File_Id__c        = cvFileId,
            Status__c            = 'Submitted'
        );

        try {
            insert app;
            return app.Id;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Application__c> getMyApplications() {
        Id userId = UserInfo.getUserId();
        List<Candidate_Profile__c> profiles = [
            SELECT Id FROM Candidate_Profile__c WHERE Contact_User__c = :userId LIMIT 1
        ];
        if (profiles.isEmpty()) return new List<Application__c>();

        return [
            SELECT Id, Name, Job_Position__r.Name, Job_Position__r.Department__c,
                   Job_Position__r.Location__c, Status__c, Submitted_Date__c,
                   Score__c, Interview_Date__c, Rejection_Reason__c
            FROM Application__c
            WHERE Candidate_Profile__c = :profiles[0].Id
            ORDER BY Submitted_Date__c DESC
        ];
    }

    @AuraEnabled
    public static Boolean hasAlreadyApplied(Id jobPositionId) {
        Id userId = UserInfo.getUserId();
        List<Candidate_Profile__c> profiles = [
            SELECT Id FROM Candidate_Profile__c WHERE Contact_User__c = :userId LIMIT 1
        ];
        if (profiles.isEmpty()) return false;

        return ![
            SELECT Id FROM Application__c
            WHERE Job_Position__c = :jobPositionId
            AND Candidate_Profile__c = :profiles[0].Id
            LIMIT 1
        ].isEmpty();
    }

    // ─────────────────────────────────────────
    // Admin Dashboard
    // ─────────────────────────────────────────
    @AuraEnabled(cacheable=true)
    public static List<Application__c> getAllApplications(Id jobPositionId, String status) {
        String query = 'SELECT Id, Name, Job_Position__r.Name, Applicant_Email__c, ' +
                       'Applicant_Phone__c, Status__c, Submitted_Date__c, Score__c, ' +
                       'Years_of_Experience__c, Expected_Salary__c, LinkedIn_URL__c, ' +
                       'Cover_Letter__c, CV_File_Id__c ' +
                       'FROM Application__c WHERE Id != null';

        if (jobPositionId != null)   query += ' AND Job_Position__c = :jobPositionId';
        if (String.isNotBlank(status)) query += ' AND Status__c = :status';
        query += ' ORDER BY Submitted_Date__c DESC LIMIT 200';

        return Database.query(query);
    }

    @AuraEnabled
    public static void updateApplicationStatus(Id applicationId, String newStatus, String rejectionReason, Decimal score) {
        Application__c app = [SELECT Id, Status__c FROM Application__c WHERE Id = :applicationId];
        app.Status__c = newStatus;
        if (String.isNotBlank(rejectionReason)) app.Rejection_Reason__c = rejectionReason;
        if (score != null) app.Score__c = score;
        update app;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getDashboardStats() {
        Map<String, Integer> stats = new Map<String, Integer>();
        stats.put('openJobs', [SELECT COUNT() FROM Job_Position__c WHERE Status__c = 'Open']);
        stats.put('totalApplications', [SELECT COUNT() FROM Application__c]);
        stats.put('pendingReview', [SELECT COUNT() FROM Application__c WHERE Status__c = 'Submitted']);
        stats.put('hiredThisMonth', [
            SELECT COUNT() FROM Application__c
            WHERE Status__c = 'Hired'
            AND Submitted_Date__c = THIS_MONTH
        ]);
        return stats;
    }

    // ─────────────────────────────────────────
    // Candidate Profile
    // ─────────────────────────────────────────
    @AuraEnabled(cacheable=true)
    public static Candidate_Profile__c getMyCandidateProfile() {
        Id userId = UserInfo.getUserId();
        List<Candidate_Profile__c> profiles = [
            SELECT Id, Name, Email__c, Phone__c, Location__c, Current_Title__c,
                   Summary__c, Skills__c, LinkedIn_URL__c, GitHub_URL__c,
                   Years_of_Experience__c, Education__c, Profile_Completed__c,
                   Total_Applications__c
            FROM Candidate_Profile__c
            WHERE Contact_User__c = :userId
            LIMIT 1
        ];
        return profiles.isEmpty() ? null : profiles[0];
    }

    @AuraEnabled
    public static Id saveCandidateProfile(
        String fullName, String email, String phone, String location,
        String currentTitle, String summary, String skills,
        String linkedInUrl, String gitHubUrl, Integer yearsOfExperience, String education
    ) {
        Id userId = UserInfo.getUserId();
        List<Candidate_Profile__c> existing = [
            SELECT Id FROM Candidate_Profile__c WHERE Contact_User__c = :userId LIMIT 1
        ];

        Candidate_Profile__c profile = existing.isEmpty()
            ? new Candidate_Profile__c(Contact_User__c = userId)
            : existing[0];

        profile.Name                  = fullName;
        profile.Email__c              = email;
        profile.Phone__c              = phone;
        profile.Location__c           = location;
        profile.Current_Title__c      = currentTitle;
        profile.Summary__c            = summary;
        profile.Skills__c             = skills;
        profile.LinkedIn_URL__c       = linkedInUrl;
        profile.GitHub_URL__c         = gitHubUrl;
        profile.Years_of_Experience__c = yearsOfExperience;
        profile.Education__c          = education;
        profile.Profile_Completed__c  = true;

        upsert profile;
        return profile.Id;
    }

    // ─────────────────────────────────────────
    // PRIVATE
    // ─────────────────────────────────────────
    private static Id getOrCreateCandidateProfile(String email, String phone) {
        Id userId = UserInfo.getUserId();
        List<Candidate_Profile__c> existing = [
            SELECT Id FROM Candidate_Profile__c WHERE Contact_User__c = :userId LIMIT 1
        ];
        if (!existing.isEmpty()) return existing[0].Id;

        Candidate_Profile__c newProfile = new Candidate_Profile__c(
            Name            = UserInfo.getName(),
            Email__c        = email,
            Phone__c        = phone,
            Contact_User__c = userId
        );
        insert newProfile;
        return newProfile.Id;
    }
}
