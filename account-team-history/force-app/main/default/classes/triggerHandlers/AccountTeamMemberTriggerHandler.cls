public with sharing class AccountTeamMemberTriggerHandler {
    private boolean triggerIsExecuting;
    private integer triggerSize;
    public AccountTeamMemberHistoryService atmServices;


    public AccountTeamMemberTriggerHandler(boolean triggerIsExecuting, integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
        this.atmServices = new AccountTeamMemberHistoryService();
    }

    public void beforeDelete(List<AccountTeamMember> oldRecords, Map<ID, SObject> oldRecordMap) {
        // helper.doTask5();
        // helper.doTask1();
    }
    public void afterInsert(List<AccountTeamMember> newRecords, Map<ID, SObject> newRecordsMap) {
        atmServices.createHistoryRecords(newRecords);
    }
}