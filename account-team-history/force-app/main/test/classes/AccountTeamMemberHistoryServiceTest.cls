@isTest
public with sharing class AccountTeamMemberHistoryServiceTest {
    @isTest
    static void testCreateBasicHistoryRecord() {
        //Set Up Test Data\\
        //Mock List of users to be returned by the mock selector
        Id testUserId = UserInfo.getUserId();
        Map<Id, User> mockUsers = new Map<Id, User>{
            testUserId => new User(Id = testUserId, UserName = 'Test User')
        };

        //Mock Account the History record will be associated with; we need to create this to satisfy lookup relationship
        String testAccountId = database.insert(TestDataFactory.createAccount('My Test Account')).getId();


        //Mock AccountTeamMember records to be passed into the service method
        AccountTeamMember atm = new AccountTeamMember(
            UserId = testUserId,
            AccountId = testAccountId,
            TeamMemberRole = 'Sales Rep'
        );

        //Instantiate mock selector to be used for testing service class and set the return value to the mock users map defined above
        MockUserSelector mockSelector = new MockUserSelector();
        mockSelector.setReturnValue(mockUsers);
        
        //Instantiate service class with the mock selector injected via constructor and invoke createHisotryRecords method
        //to test successul record creation. The test will use the mock selector to avoid querying real User records.
        AccountTeamMemberHistoryService service = new AccountTeamMemberHistoryService(mockSelector);
        service.createHistoryRecords(new List<AccountTeamMember>{atm});
    }     
}