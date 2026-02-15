@isTest
public with sharing class MockAccountTeamMemberHistorySelector extends AccountTeamMemberHistorySelector {
    //Private variable to hold mock return value; this is set by the setReturnValue method
    private Map<Id, Account_Team_Member_History__c> mockReturnValue;

    //Constructor
    public MockAccountTeamMemberHistorySelector() {}

    //getAccountTeamMemberHistoryByAtmIds override; returns the mockReturnValue if set, otherwise returns an empty map
    public override Map<Id, Account_Team_Member_History__c> getAccountTeamMemberHistoryByAtmIds(Set<Id> atmIds) {
        return mockReturnValue != null ? mockReturnValue : new Map<Id, Account_Team_Member_History__c>();
    }

    //Helper method to set what the mock getAccountTeamMemberHistoryByAtmIds() method should return
    public void setReturnValue(Map<Id, Account_Team_Member_History__c> users) {
        this.mockReturnValue = users;
    }
}