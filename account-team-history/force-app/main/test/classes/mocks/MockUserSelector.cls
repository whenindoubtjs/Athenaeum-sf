/*
    Mock implementation of UserSelector for testing purposes.
    This class allows setting a predefined return value for the getUsersByIds method.
*/
@isTest
public with sharing class MockUserSelector extends UserSelector {
    //Private variable to hold mock return value; this is set by the setReturnValue method
    private Map<Id, User> mockReturnValue;

    //Constructor
    public MockUserSelector() {}
    
    //getUsersByIds override; returns the mockReturnValue if set, otherwise returns an empty map
    public override Map<Id, User> getUsersByIds(Set<Id> userIds) {
        return mockReturnValue != null ? mockReturnValue : new Map<Id, User>();
    }
    
    //Helper method to set what the mock getUsersByIds() method should return
    public void setReturnValue(Map<Id, User> users) {
        this.mockReturnValue = users;
    }
}