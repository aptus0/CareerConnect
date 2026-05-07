/**
 * @description Schedulable class to run external job sync daily
 * Schedule with: System.schedule('Daily Job Sync', '0 0 6 * * ?', new ExternalJobSyncScheduler());
 * @author CareerConnect Project
 * @date 2024
 */
global class ExternalJobSyncScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        ExternalJobSyncService.syncJobsFromExternalAPI('salesforce developer', 'London');
    }
}
