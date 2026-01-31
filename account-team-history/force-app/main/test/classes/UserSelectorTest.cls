/**
    Test class for UserSelector
*/
@isTest
public with sharing class UserSelectorTest {
    /**
     * Test the successful fetching of user records by ID via the getUsersByIds method
     */
    @isTest
    static void testGetUsersByIds() {
        //Set up and insert test user records Data using TestDataFactory
        List<User> testUserRecords = TestDataFactory.createUsers(2);
        database.insert(testUserRecords);

        //Instantiate UserSelector
        UserSelector selector = new UserSelector();
        //Invoke UserSelector.getUsersByIds method with the set of test user IDs
        Set<Id> userIds = new Set<Id>{testUserRecords[0].Id, testUserRecords[1].Id};
        Map<Id, User> result = selector.getUsersByIds(userIds);
        //Assert that the returned map contains the expected users
        System.assertEquals(2, result.size(), 'Expected 2 users to be returned');
    }

    /**
     * Test the successful defensive check by the getUsersByIds method of providing an empty set of user IDs to the selector
     */
    @isTest
    static void testGetUsersByIds_Empty() {
        //Instantiate UserSelector
        UserSelector selector = new UserSelector();
        //Invoke UserSelector.getUsersByIds method with an empty set
        Set<Id> emptyUserIds = new Set<Id>();
        Map<Id, User> result = selector.getUsersByIds(emptyUserIds);
        //Assert that the returned map is empty
        System.assertEquals(0, result.size(), 'Expected no users to be returned for empty input set');
    }
}