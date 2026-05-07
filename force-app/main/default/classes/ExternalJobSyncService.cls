/**
 * @description Service class to sync jobs from an external Job Board API
 * Demonstrates: Named Credentials, HTTP Callouts, JSON parsing, Upsert by external ID
 *
 * External API: Reed.co.uk Jobs API (or configurable via Custom Metadata)
 * Scheduled via: ExternalJobSyncScheduler
 *
 * @author CareerConnect Project
 * @date 2024
 */
public with sharing class ExternalJobSyncService {

    private static final String NAMED_CREDENTIAL = 'callout:ExternalJobAPI';
    private static final Integer MAX_RESULTS = 100;

    // ─────────────────────────────────────────
    // External API Response Models
    // ─────────────────────────────────────────
    public class ExternalJobResponse {
        public List<ExternalJob> results;
        public Integer totalResults;
    }

    public class ExternalJob {
        public String jobId;
        public String jobTitle;
        public String employerName;
        public String locationName;
        public String minimumSalary;
        public String maximumSalary;
        public String jobDescription;
        public String jobUrl;
        public String contractType;
        public String postedDate;
    }

    // ─────────────────────────────────────────
    // Main Sync Method
    // ─────────────────────────────────────────
    public static Map<String, Integer> syncJobsFromExternalAPI(String keywords, String location) {
        Map<String, Integer> result = new Map<String, Integer>{
            'inserted' => 0, 'updated' => 0, 'errors' => 0
        };

        try {
            List<ExternalJob> externalJobs = fetchFromExternalAPI(keywords, location);
            if (externalJobs == null || externalJobs.isEmpty()) return result;

            List<Job_Position__c> upsertList = new List<Job_Position__c>();

            for (ExternalJob ext : externalJobs) {
                Job_Position__c job = new Job_Position__c();
                job.External_Job_Id__c  = ext.jobId;
                job.Name                = ext.jobTitle;
                job.Location__c         = ext.locationName;
                job.Description__c      = ext.jobDescription;
                job.Status__c           = 'Open';
                job.Employment_Type__c  = mapContractType(ext.contractType);
                job.Salary_Range__c     = buildSalaryRange(ext.minimumSalary, ext.maximumSalary);
                job.Posted_Date__c      = parseDate(ext.postedDate);
                upsertList.add(job);
            }

            Schema.SObjectField extIdField = Job_Position__c.Fields.External_Job_Id__c;
            List<Database.UpsertResult> upsertResults = Database.upsert(upsertList, extIdField, false);

            for (Database.UpsertResult ur : upsertResults) {
                if (ur.isSuccess()) {
                    if (ur.isCreated()) result.put('inserted', result.get('inserted') + 1);
                    else                result.put('updated',  result.get('updated')  + 1);
                } else {
                    result.put('errors', result.get('errors') + 1);
                    System.debug('Upsert error: ' + ur.getErrors()[0].getMessage());
                }
            }

        } catch (Exception e) {
            System.debug('ExternalJobSyncService error: ' + e.getMessage());
            result.put('errors', result.get('errors') + 1);
        }

        return result;
    }

    // ─────────────────────────────────────────
    // HTTP Callout
    // ─────────────────────────────────────────
    @TestVisible
    private static List<ExternalJob> fetchFromExternalAPI(String keywords, String location) {
        String endpoint = NAMED_CREDENTIAL + '/api/1.0/search?' +
            'keywords=' + EncodingUtil.urlEncode(keywords != null ? keywords : 'software', 'UTF-8') +
            '&locationName=' + EncodingUtil.urlEncode(location != null ? location : 'London', 'UTF-8') +
            '&resultsToTake=' + MAX_RESULTS;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(10000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            ExternalJobResponse parsed = (ExternalJobResponse) JSON.deserialize(
                res.getBody(), ExternalJobResponse.class
            );
            return parsed.results;
        } else {
            throw new CalloutException('External API returned: ' + res.getStatusCode() + ' ' + res.getStatus());
        }
    }

    // ─────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────
    private static String mapContractType(String contractType) {
        if (contractType == null) return 'Full-Time';
        switch on contractType.toLowerCase() {
            when 'permanent'  { return 'Full-Time'; }
            when 'contract'   { return 'Contract'; }
            when 'part time'  { return 'Part-Time'; }
            when 'internship' { return 'Internship'; }
            when else         { return 'Full-Time'; }
        }
    }

    private static String buildSalaryRange(String min, String max) {
        if (String.isBlank(min) && String.isBlank(max)) return 'Competitive';
        if (String.isBlank(max)) return '£' + min + '+';
        return '£' + min + ' – £' + max;
    }

    private static Date parseDate(String dateStr) {
        try {
            return Date.valueOf(dateStr.substring(0, 10));
        } catch (Exception ex) {
            return Date.today();
        }
    }
}
