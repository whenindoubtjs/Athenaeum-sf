//Basic trigger for Account Team Member object. This trigger is meant to be easily merged or rebuilt into your existing
//trigger framework. All processing logic is executed by the Trigger Handler, which invokes a service layer class to perform the work.
trigger AccountTeamMemberTrigger on AccountTeamMember (after insert, before delete, after update) {
    //Instantiate trigger handler to facilitate in invoking the service layer logic
    AccountTeamMemberTriggerHandler handler = new AccountTeamMemberTriggerHandler(Trigger.isExecuting, Trigger.size);

    // This object triggers on after insert, after update, and before delete events
    if (Trigger.isAfter && Trigger.isInsert) {
        handler.afterInsert(Trigger.new, Trigger.newMap);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        handler.afterUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
    }
    if (Trigger.isBefore && Trigger.isDelete) {
        handler.beforeDelete(Trigger.old);
    }
}