public with sharing class AccountTeamMemberTriggerHandler {
    private boolean triggerIsExecuting;
    private integer triggerSize;
    public AccountTeamMemberHistoryService atmServices;

    // List of tracked fields the handler listens for when an update happens; updates to these fields case the inactivation and creation of a new
    // AccountTeamMemberHistory record to be created
    private List<String> trackedFields = new List<String>{
        'TeamMemberRole'
    };

    // Constructor
    public AccountTeamMemberTriggerHandler(boolean triggerIsExecuting, integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
        this.atmServices = new AccountTeamMemberHistoryService();
    }

    // beforeDelete method - invoked when an AccountTeamMember record is deleted
    public void beforeDelete(List<AccountTeamMember> oldRecords) {
        atmServices.inactivateHistoryRecords(oldRecords);
    }   

    // afterUpdate method - invoked when an AccountTeamMember record is updated
    public void afterUpdate(List<AccountTeamMember> newRecords, Map<ID, SObject> newRecordsMap, List<AccountTeamMember> oldRecords, Map<ID, SObject> oldRecordsMap) {
        // Check if updated fields included changes to fields we care about, and if they did, call service methods to inactivate the existing history record
        // and create a new one for the updated record for audit trail
        List<AccountTeamMember> changedRecords = getRecordsWithFieldChanges(newRecords, oldRecordsMap, trackedFields);
        if(!changedRecords.isEmpty()) {
            atmServices.inactivateHistoryRecords(changedRecords);
            atmServices.createHistoryRecords(changedRecords);
        }
    }

    // afterInsert method - invoked when an AccountTeamMember record is inserted
    public void afterInsert(List<AccountTeamMember> newRecords, Map<ID, SObject> newRecordsMap) {
        atmServices.createHistoryRecords(newRecords);
    }

    /**
     * Helper method to filter records that have changes in specified fields; this just makes it a little easier to read the trigger handler code and detect
     * changes to multiple fields
     * @param newRecords List of new record values, from the triggering context
     * @param oldRecordsMap Map of old record values, from the triggering context
     * @param fieldsToCheck Set of field API names to check for changes
     * @return List of records that have changes in the specified fields
     */
    private List<AccountTeamMember> getRecordsWithFieldChanges(List<AccountTeamMember> newRecords, Map<Id, SObject> oldRecordsMap, List<String> fieldsToCheck) {
        //Init empty list of changed records
        List<AccountTeamMember> changedRecords = new List<AccountTeamMember>();     
        //Iterate over list of changed records passed from triggering context
        for(AccountTeamMember newRecord : newRecords) {
            //Fetch the older records from the oldRecordsMap that is assocaited with the new record in the loop we are checking
            AccountTeamMember oldRecord = (AccountTeamMember) oldRecordsMap.get(newRecord.Id);
            //Check each field value we care about to see if any are different, and add the record to the list of changed records if any are different
            for(String fieldName : fieldsToCheck) {
                if(newRecord.get(fieldName) != oldRecord.get(fieldName)) {
                    changedRecords.add(newRecord);
                    break;
                }
            }
        }
        return changedRecords;
    }
}