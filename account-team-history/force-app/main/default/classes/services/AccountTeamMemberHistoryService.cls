//Primary processing class for the Account Team Member History custom object. Handles all logic relating to the creation and update of
//the Account Team Member History records. These methods are invoked from the AccountTeamMemberTriggerHandler class, which in turn is
//invoked from the AccountTeamMemberTrigger trigger.
public with sharing class AccountTeamMemberHistoryService {
    //Dependency injection of UserSelector to allow for easier unit testing and mocking
    private UserSelector userSelector;

    //CONSTRUCTORS\\
    
    /**
        Base constructor for use in production code; initializes UserSelector dependency
    */
    public AccountTeamMemberHistoryService() {
        this.userSelector = new UserSelector();
    }

    /**
     * Constructor with dependency injection for testing - only visible in testing context
     * @param selector Mock selector to be used in place of the real UserSelector
     */
    @TestVisible
    private AccountTeamMemberHistoryService(UserSelector selector) {
        this.userSelector = selector;
    }

    /** 
     * Creates Account Team Member History records for each AccountTeamMember record that was inserted as part of the trigger context.
     * 
     * @see AccountTeamMemberTriggerHandler.afterInsert()
     * @param newRecords List of newly inserted AccountTeamMember records, passed from AccountTeamMemberTriggerHandler
    */
    public void createHistoryRecords(List<AccountTeamMember> newRecords) {
        //Instantiate set of UserIds, iterate over each AccountTeamMember record and pull out the User ID for that record
        //Duplicate IDs will not be added to the set (Sets are unique). These ids will be used to fetch user records
        //which will in turn be used during the creation of the Account Team Member records to set context-specific names
        Set<Id> userIds = new Set<Id>();
        for(AccountTeamMember atm : newRecords) userIds.add(atm.UserId);
        //Fetch user records associated with the triggering AccountTeamMember record via selector
        Map<Id, User> userMap = UserSelector.getUsersByIds(userIds);

        //Init list of AccountTeamMemberHistory (atmHistory for short) records to be created
        List<Account_Team_Member_History__c> atmHistoryRecordsToInsert = new List<Account_Team_Member_History__c>();
        //Iterate over each AccountTeamMember record in the trigger context and set up a new atmHistory record using its data
        for(AccountTeamMember atm : newRecords) {
            //Init empty atmHistory record
            Account_Team_Member_History__c atmHistoryRecord = new Account_Team_Member_History__c();
            
            //Get the User Name of the User associated with the AccountTeamMember record from the previously fetched userMap
            String userName = userMap.containsKey(atm.UserId) ? userMap.get(atm.UserId).Name : 'Unknown User';

            //Populate atmHistory record fields\\
            atmHistoryRecord.Name = userName + ' - ' + atm.TeamMemberRole;
            atmHistoryRecord.Account__c = atm.AccountId;
            atmHistoryRecord.Team_Member__c = atm.UserId;
            atmHistoryRecord.Team_Member_Role__c = atm.TeamMemberRole;
            atmHistoryRecord.Status__c = 'Active';
            atmHistoryRecord.Active_From__c = System.today();
            atmHistoryRecord.Account_Access__c = atm.AccountAccessLevel;
            atmHistoryRecord.Case_Access__c = atm.CaseAccessLevel;
            atmHistoryRecord.Opportunity_Access__c = atm.OpportunityAccessLevel;
            atmHistoryRecord.Contact_Access__c = atm.ContactAccessLevel;
            atmHistoryRecord.Added_By__c = atm.CreatedById;

            //Add instantiated atmHistory record to the list of records to be inserted
            atmHistoryRecordsToInsert.add(atmHistoryRecord);
        }

        //Defensive check: only attempt to insert if there are records to insert
        if(!atmHistoryRecordsToInsert.isEmpty()) {
            insert atmHistoryRecordsToInsert;
        }
    }
}