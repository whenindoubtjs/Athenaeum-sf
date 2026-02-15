public virtual with sharing class AccountTeamMemberHistorySelector {

    //Default constructor
    public AccountTeamMemberHistorySelector() {}

    //Field set defining which Account Team Member History fields to retrieve in queries. Can be modified to add/remove fields as needed
    private static final List<Schema.SObjectField> ATM_HISTORY_FIELDS = new List<Schema.SObjectField>{
        Account_Team_Member_History__c.Id,
        Account_Team_Member_History__c.Account__c,
        Account_Team_Member_History__c.Status__c,
        Account_Team_Member_History__c.Active_To__c,
        Account_Team_Member_History__c.Removed_By__c
    };

    /**
     * Helper method to convert the ATM_HISTORY_FIELDS list into a comma-separated string for use in dynamic SOQL queries
     * @return String Comma-separated string of Account Team Member History field names
     */
    private static String getFieldString() {
        List<String> fieldNames = new List<String>();
        for (Schema.SObjectField field : ATM_HISTORY_FIELDS) {
            fieldNames.add(field.getDescribe().getName());
        }
        return String.join(fieldNames, ', ');
    }

    /** 
     * Fetches Account Team Member History records for the given set of related Account Team Member IDs.
     * 
     * @param atmHistoryIds Set of Account Team Member IDs for which to fetch records
     * @return Map<Id, Account_Team_Member_History__c> Map of Account Team Member History records keyed by their IDs
    */
    public virtual Map<Id, Account_Team_Member_History__c> getAccountTeamMemberHistoryByAtmIds(Set<Id> atmIds) {
        //Defensive check - if atmIds is null or empty, return empty list
        if (atmIds == null || atmIds.isEmpty()) {
            return new Map<Id, Account_Team_Member_History__c>();
        }
        
        //Otherwise, build queryString from defined list of fields and run query fetching Account Team Member History record for the given atmIds
        //This will either return a map of Account Team Member History records, a empty map if no records found, or a QueryException if an error occurs
        //Database.query() returns a list of sObjects. To send it to a map, we have to explicitly cast it to List and then to Map
        String query = 'SELECT ' + getFieldString() + ' FROM Account_Team_Member_History__c WHERE AccountTeamMemberId__c IN :atmIds';
        return new Map<Id, Account_Team_Member_History__c>((List<Account_Team_Member_History__c>)Database.query(query));
    }
}