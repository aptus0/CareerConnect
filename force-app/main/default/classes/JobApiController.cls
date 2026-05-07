/**
 * @description REST API Controller for CareerConnect
 * Exposes endpoints for Experience Cloud portal and external integrations
 *
 * Endpoints:
 *   GET  /services/apexrest/careers/jobs          → list open positions
 *   GET  /services/apexrest/careers/jobs/{id}     → single job detail
 *   POST /services/apexrest/careers/jobs          → create job (admin)
 *   GET  /services/apexrest/careers/applications  → candidate's applications
 *   POST /services/apexrest/careers/apply         → submit application
 *
 * @author CareerConnect Project
 * @date 2024
 */
@RestResource(urlMapping='/careers/*')
global with sharing class JobApiController {

    // ─────────────────────────────────────────
    // Response Wrappers
    // ─────────────────────────────────────────
    global class ApiResponse {
        public Boolean success;
        public String message;
        public Object data;
        public Integer statusCode;

        public ApiResponse(Boolean success, String message, Object data, Integer statusCode) {
            this.success = success;
            this.message = message;
            this.data = data;
            this.statusCode = statusCode;
        }
    }

    global class JobDTO {
        public Id id;
        public String title;
        public String department;
        public String location;
        public String employmentType;
        public String salaryRange;
        public String description;
        public String requirements;
        public String status;
        public Boolean remoteEligible;
        public Date deadline;
        public Date postedDate;
        public Integer applicationCount;
        public Integer maxApplicants;
    }

    global class ApplicationDTO {
        public Id id;
        public String applicationNumber;
        public String jobTitle;
        public String status;
        public Datetime submittedDate;
        public Decimal score;
        public String rejectionReason;
    }

    global class ApplicationRequest {
        public Id jobPositionId;
        public Id candidateProfileId;
        public String coverLetter;
        public Integer yearsOfExperience;
        public Decimal expectedSalary;
        public String cvFileId;
        public String linkedInUrl;
        public String email;
        public String phone;
    }

    // ─────────────────────────────────────────
    // GET – Jobs or Applications
    // ─────────────────────────────────────────
    @HttpGet
    global static void handleGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            List<String> parts = getCareerPathSegments();
            // Supports both /careers/jobs and /services/apexrest/careers/jobs
            String resource = parts.isEmpty() ? '' : parts[0];
            String recordId  = parts.size() > 1 ? parts[1] : null;

            if (resource == 'jobs') {
                if (String.isNotBlank(recordId)) {
                    res.responseBody = Blob.valueOf(JSON.serialize(getJobById(recordId)));
                } else {
                    String dept   = req.params.get('department');
                    String empType = req.params.get('type');
                    Boolean remote = req.params.get('remote') == 'true';
                    res.responseBody = Blob.valueOf(JSON.serialize(getOpenJobs(dept, empType, remote)));
                }
            } else if (resource == 'applications') {
                res.responseBody = Blob.valueOf(JSON.serialize(getMyApplications()));
            } else {
                res.statusCode = 404;
                res.responseBody = Blob.valueOf(JSON.serialize(
                    new ApiResponse(false, 'Resource not found', null, 404)
                ));
            }
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(
                new ApiResponse(false, e.getMessage(), null, 500)
            ));
        }
    }

    // ─────────────────────────────────────────
    // POST – Submit Application or Create Job
    // ─────────────────────────────────────────
    @HttpPost
    global static void handlePost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            List<String> parts = getCareerPathSegments();
            String resource = parts.isEmpty() ? '' : parts[0];

            if (resource == 'apply') {
                ApplicationRequest appReq = (ApplicationRequest) JSON.deserialize(
                    req.requestBody.toString(), ApplicationRequest.class
                );
                ApiResponse response = submitApplication(appReq);
                res.statusCode = response.success ? 201 : 400;
                res.responseBody = Blob.valueOf(JSON.serialize(response));

            } else if (resource == 'jobs') {
                JobDTO jobData = (JobDTO) JSON.deserialize(
                    req.requestBody.toString(), JobDTO.class
                );
                ApiResponse response = createJobPosition(jobData);
                res.statusCode = response.success ? 201 : 400;
                res.responseBody = Blob.valueOf(JSON.serialize(response));

            } else if (resource == 'sync-external-jobs') {
                Map<String, Object> body = new Map<String, Object>();
                if (req.requestBody != null && String.isNotBlank(req.requestBody.toString())) {
                    body = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
                }
                String keywords = body.containsKey('keywords') ? (String) body.get('keywords') : 'software';
                String location = body.containsKey('location') ? (String) body.get('location') : 'London';
                Map<String, Integer> syncResult = ExternalJobSyncService.syncJobsFromExternalAPI(keywords, location);
                res.statusCode = 200;
                res.responseBody = Blob.valueOf(JSON.serialize(
                    new ApiResponse(true, 'External jobs synced successfully', syncResult, 200)
                ));

            } else {
                res.statusCode = 404;
                res.responseBody = Blob.valueOf(JSON.serialize(
                    new ApiResponse(false, 'Endpoint not found', null, 404)
                ));
            }
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(
                new ApiResponse(false, 'Internal server error: ' + e.getMessage(), null, 500)
            ));
        }
    }

    // ─────────────────────────────────────────
    // PATCH – Update Application Status (HR use)
    // ─────────────────────────────────────────
    @HttpPatch
    global static void handlePatch() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(
                req.requestBody.toString()
            );
            Id appId     = (Id) body.get('id');
            String status = (String) body.get('status');
            String reason = (String) body.get('rejectionReason');
            Decimal score = body.containsKey('score') ? Decimal.valueOf(String.valueOf(body.get('score'))) : null;

            Application__c app = [SELECT Id, Status__c FROM Application__c WHERE Id = :appId WITH SECURITY_ENFORCED];
            app.Status__c = status;
            if (String.isNotBlank(reason)) app.Rejection_Reason__c = reason;
            if (score != null) app.Score__c = score;
            update app;

            res.responseBody = Blob.valueOf(JSON.serialize(
                new ApiResponse(true, 'Application updated successfully', app.Id, 200)
            ));
        } catch (Exception e) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(
                new ApiResponse(false, e.getMessage(), null, 400)
            ));
        }
    }

    // ─────────────────────────────────────────
    // PRIVATE HELPERS
    // ─────────────────────────────────────────


    private static List<String> getCareerPathSegments() {
        String uri = RestContext.request.requestURI;
        String marker = '/careers/';
        String path = '';

        Integer markerIndex = uri.indexOf(marker);
        if (markerIndex >= 0) {
            path = uri.substring(markerIndex + marker.length());
        } else if (uri.endsWith('/careers')) {
            path = '';
        } else {
            path = uri;
        }

        Integer queryIndex = path.indexOf('?');
        if (queryIndex >= 0) {
            path = path.substring(0, queryIndex);
        }

        List<String> segments = new List<String>();
        for (String piece : path.split('/')) {
            if (String.isNotBlank(piece)) {
                segments.add(EncodingUtil.urlDecode(piece, 'UTF-8'));
            }
        }
        return segments;
    }

    private static ApiResponse getOpenJobs(String department, String empType, Boolean remoteOnly) {
        String query = 'SELECT Id, Name, Department__c, Location__c, Employment_Type__c, ' +
                       'Salary_Range__c, Description__c, Requirements__c, Status__c, ' +
                       'Remote_Eligible__c, Deadline__c, Posted_Date__c, ' +
                       'Application_Count__c, Max_Applicants__c ' +
                       'FROM Job_Position__c WHERE Status__c = \'Open\'';

        if (String.isNotBlank(department)) query += ' AND Department__c = :department';
        if (String.isNotBlank(empType))    query += ' AND Employment_Type__c = :empType';
        if (remoteOnly)                    query += ' AND Remote_Eligible__c = true';
        query += ' ORDER BY Posted_Date__c DESC NULLS LAST';

        List<Job_Position__c> jobs = Database.query(query);
        List<JobDTO> result = new List<JobDTO>();
        for (Job_Position__c j : jobs) {
            result.add(toJobDTO(j));
        }
        return new ApiResponse(true, 'Success', result, 200);
    }

    private static ApiResponse getJobById(String jobId) {
        List<Job_Position__c> jobs = [
            SELECT Id, Name, Department__c, Location__c, Employment_Type__c,
                   Salary_Range__c, Description__c, Requirements__c, Status__c,
                   Remote_Eligible__c, Deadline__c, Posted_Date__c,
                   Application_Count__c, Max_Applicants__c
            FROM Job_Position__c
            WHERE Id = :jobId
            WITH SECURITY_ENFORCED
        ];
        if (jobs.isEmpty()) {
            return new ApiResponse(false, 'Job not found', null, 404);
        }
        return new ApiResponse(true, 'Success', toJobDTO(jobs[0]), 200);
    }

    private static ApiResponse getMyApplications() {
        Id userId = UserInfo.getUserId();
        List<Candidate_Profile__c> profiles = [
            SELECT Id FROM Candidate_Profile__c WHERE Contact_User__c = :userId LIMIT 1
        ];
        if (profiles.isEmpty()) {
            return new ApiResponse(false, 'No candidate profile found', null, 404);
        }
        Id profileId = profiles[0].Id;

        List<Application__c> apps = [
            SELECT Id, Name, Job_Position__r.Name, Status__c, Submitted_Date__c,
                   Score__c, Rejection_Reason__c
            FROM Application__c
            WHERE Candidate_Profile__c = :profileId
            ORDER BY Submitted_Date__c DESC
        ];

        List<ApplicationDTO> result = new List<ApplicationDTO>();
        for (Application__c a : apps) {
            ApplicationDTO dto = new ApplicationDTO();
            dto.id = a.Id;
            dto.applicationNumber = a.Name;
            dto.jobTitle = a.Job_Position__r.Name;
            dto.status = a.Status__c;
            dto.submittedDate = a.Submitted_Date__c;
            dto.score = a.Score__c;
            dto.rejectionReason = a.Rejection_Reason__c;
            result.add(dto);
        }
        return new ApiResponse(true, 'Success', result, 200);
    }

    private static ApiResponse submitApplication(ApplicationRequest appReq) {
        if (appReq.jobPositionId == null) {
            return new ApiResponse(false, 'jobPositionId is required', null, 400);
        }

        Application__c app = new Application__c();
        app.Job_Position__c     = appReq.jobPositionId;
        app.Candidate_Profile__c = appReq.candidateProfileId;
        app.Cover_Letter__c     = appReq.coverLetter;
        app.Years_of_Experience__c = appReq.yearsOfExperience;
        app.Expected_Salary__c  = appReq.expectedSalary;
        app.CV_File_Id__c       = appReq.cvFileId;
        app.LinkedIn_URL__c     = appReq.linkedInUrl;
        app.Applicant_Email__c  = appReq.email;
        app.Applicant_Phone__c  = appReq.phone;
        app.Status__c           = 'Submitted';

        try {
            insert app;
            return new ApiResponse(true, 'Application submitted successfully', app.Id, 201);
        } catch (DmlException e) {
            return new ApiResponse(false, e.getDmlMessage(0), null, 400);
        }
    }

    private static ApiResponse createJobPosition(JobDTO jobData) {
        Job_Position__c job = new Job_Position__c();
        job.Name               = jobData.title;
        job.Department__c      = jobData.department;
        job.Location__c        = jobData.location;
        job.Employment_Type__c = jobData.employmentType;
        job.Salary_Range__c    = jobData.salaryRange;
        job.Description__c     = jobData.description;
        job.Requirements__c    = jobData.requirements;
        job.Status__c          = jobData.status != null ? jobData.status : 'Open';
        job.Remote_Eligible__c = jobData.remoteEligible;
        job.Deadline__c        = jobData.deadline;
        job.Posted_Date__c     = Date.today();
        job.Max_Applicants__c  = jobData.maxApplicants;

        try {
            insert job;
            return new ApiResponse(true, 'Job position created', job.Id, 201);
        } catch (DmlException e) {
            return new ApiResponse(false, e.getDmlMessage(0), null, 400);
        }
    }

    private static JobDTO toJobDTO(Job_Position__c j) {
        JobDTO dto = new JobDTO();
        dto.id               = j.Id;
        dto.title            = j.Name;
        dto.department       = j.Department__c;
        dto.location         = j.Location__c;
        dto.employmentType   = j.Employment_Type__c;
        dto.salaryRange      = j.Salary_Range__c;
        dto.description      = j.Description__c;
        dto.requirements     = j.Requirements__c;
        dto.status           = j.Status__c;
        dto.remoteEligible   = j.Remote_Eligible__c;
        dto.deadline         = j.Deadline__c;
        dto.postedDate       = j.Posted_Date__c;
        dto.applicationCount = j.Application_Count__c != null ? Integer.valueOf(j.Application_Count__c) : 0;
        dto.maxApplicants    = j.Max_Applicants__c != null ? Integer.valueOf(j.Max_Applicants__c) : null;
        return dto;
    }
}
