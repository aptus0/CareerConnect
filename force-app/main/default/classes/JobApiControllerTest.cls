/**
 * @description Test class for JobApiController REST endpoints
 * @author CareerConnect Project
 * @date 2024
 */
@IsTest
private class JobApiControllerTest {

    @TestSetup
    static void setup() {
        Job_Position__c job = new Job_Position__c(
            Name               = 'Senior Developer',
            Department__c      = 'Engineering',
            Location__c        = 'Remote',
            Employment_Type__c = 'Full-Time',
            Status__c          = 'Open',
            Remote_Eligible__c = true,
            Deadline__c        = Date.today().addDays(30),
            Posted_Date__c     = Date.today()
        );
        insert job;
    }

    @IsTest
    static void testGetOpenJobs() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/careers/jobs';
        req.httpMethod = 'GET';
        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
        JobApiController.handleGet();
        Test.stopTest();

        System.assertEquals(200, res.statusCode == 0 ? 200 : res.statusCode);
        String body = res.responseBody.toString();
        System.assert(body.contains('Senior Developer'), 'Response should contain job title');
    }

    @IsTest
    static void testGetJobById() {
        Job_Position__c job = [SELECT Id FROM Job_Position__c LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI  = '/services/apexrest/careers/jobs/' + job.Id;
        req.httpMethod  = 'GET';
        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
        JobApiController.handleGet();
        Test.stopTest();

        String body = res.responseBody.toString();
        System.assert(body.contains('Senior Developer'), 'Should return single job');
    }

    @IsTest
    static void testSubmitApplication() {
        Job_Position__c job = [SELECT Id FROM Job_Position__c LIMIT 1];

        Map<String, Object> payload = new Map<String, Object>{
            'jobPositionId' => job.Id,
            'email'         => 'api@test.com',
            'phone'         => '07777123456',
            'coverLetter'   => 'I am a great fit for this role.',
            'yearsOfExperience' => 5
        };

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI   = '/services/apexrest/careers/apply';
        req.httpMethod   = 'POST';
        req.requestBody  = Blob.valueOf(JSON.serialize(payload));
        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
        JobApiController.handlePost();
        Test.stopTest();

        System.assertEquals(201, res.statusCode, 'Expected 201 Created');
    }

    @IsTest
    static void testPatchApplicationStatus() {
        Job_Position__c job = [SELECT Id FROM Job_Position__c LIMIT 1];
        Application__c app = new Application__c(
            Job_Position__c    = job.Id,
            Applicant_Email__c = 'patch@test.com',
            Status__c          = 'Submitted'
        );
        insert app;

        Map<String, Object> payload = new Map<String, Object>{
            'id'     => app.Id,
            'status' => 'Under Review',
            'score'  => 85
        };

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI  = '/services/apexrest/careers/applications';
        req.httpMethod  = 'PATCH';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
        JobApiController.handlePatch();
        Test.stopTest();

        Application__c updated = [SELECT Status__c, Score__c FROM Application__c WHERE Id = :app.Id];
        System.assertEquals('Under Review', updated.Status__c);
        System.assertEquals(85, updated.Score__c);
    }

    private class ReedSyncMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"results":[{"jobId":"reed-1001","jobTitle":"External Salesforce Consultant","locationName":"Remote","minimumSalary":"50000","maximumSalary":"70000","jobDescription":"External job imported from Reed API.","contractType":"permanent","postedDate":"2026-05-06T00:00:00Z"}],"totalResults":1}');
            return res;
        }
    }

    @IsTest
    static void testSyncExternalJobsEndpoint() {
        Test.setMock(HttpCalloutMock.class, new ReedSyncMock());

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/careers/sync-external-jobs';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"keywords":"salesforce","location":"remote"}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        JobApiController.handlePost();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Expected sync endpoint to return 200');
        System.assert(res.responseBody.toString().contains('External jobs synced successfully'));
    }

}
