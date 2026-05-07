/**
 * @description Trigger for Application__c object
 * Handles: duplicate prevention, status notifications, position auto-close, count updates
 * @author CareerConnect Project
 * @date 2024
 */
trigger ApplicationTrigger on Application__c (
    before insert,
    before update,
    after insert,
    after update,
    before delete
) {
    ApplicationTriggerHandler handler = new ApplicationTriggerHandler();

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.onBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            handler.onBeforeDelete(Trigger.old);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handler.onAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
