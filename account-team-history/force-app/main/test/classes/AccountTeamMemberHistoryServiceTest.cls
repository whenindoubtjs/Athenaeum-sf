@isTest
public with sharing class AccountTeamMemberHistoryServiceTest {
    /**
     * Tests successful creation and inactivation of Account Team Member History records via the AccountTeamMemberHistoryService methods.
     * This test uses mock selector classes to avoid querying real User and Account Team Member History records.
     * It verifies that the created records have the expected field values and that the inactivation process
     * correctly updates the relevant fields.
     */
    @isTest
    static void successfulCreateAndInactivate() {
        // ============================================
        // Setup Test Data
        // ============================================
        //Create fake AccountTeamMember Id for testing without DML operation. To ensure org-agnostic IDs, derive prefix from SObjectType using TestDataFactory
        Id fakeAtmId = TestDataFactory.generateFakeId(AccountTeamMember.SObjectType, true);
        // Get current user and create test Account to associate with the ATM
        Id testUserId = UserInfo.getUserId();
        // Insert test Account; we need a true DML operation for this because AccountTeamMember requires a valid, DML-ified AccountId
        Id testAccountId = Database.insert(TestDataFactory.createAccount('Test')).getId();
        AccountTeamMember atm = TestDataFactory.createAccountTeamMember( fakeAtmId, testUserId,testAccountId, 'Sales Rep');
        
        // Create mock UserSelector to avoid querying real User records. Set the return value to a new user record using the ID of the running user
        MockUserSelector mockUserSelector = new MockUserSelector();
        mockUserSelector.setReturnValue(new Map<Id, User>{
            testUserId => new User(Id = testUserId, LastName = 'Test User')
        });
        // Create mock AccountTeamMemberHistorySelector; we'll set its return value after the service method creating the record is called
        MockAccountTeamMemberHistorySelector mockAtmHistorySelector = new MockAccountTeamMemberHistorySelector();
        // Instantiate service with mock selectors
        AccountTeamMemberHistoryService service = new AccountTeamMemberHistoryService(mockUserSelector,mockAtmHistorySelector);
        
        // ============================================
        // Begin Test Context
        // ============================================
        Test.startTest();
        // Test creating history record using service method
        List<Account_Team_Member_History__c> createdRecords = service.createHistoryRecords(new List<AccountTeamMember>{atm});     
        // Verify creation
        System.assertEquals(1, createdRecords.size());
        System.assertEquals('Active', createdRecords[0].Status__c);
        System.assertEquals(fakeAtmId, createdRecords[0].AccountTeamMemberId__c);
        
        // Init new map for atmHistory records and populate it by iterating over the return list of created history records from the service class above.
        // Then set the return value of the mock selector to this map so that when the inactivate method is called, it returns the correct records
        Map<Id, Account_Team_Member_History__c> mockHistoryMap = new Map<Id, Account_Team_Member_History__c>();
        for(Account_Team_Member_History__c record : createdRecords) { 
            mockHistoryMap.put(record.AccountTeamMemberId__c, record); 
        }
        mockAtmHistorySelector.setReturnValue(mockHistoryMap);
        
        // Test inactivating history record using service method
        service.inactivateHistoryRecords(new List<AccountTeamMember>{atm});
        Test.stopTest();
        
        // Fetch and verify inactivation of records was successful by querying the updated records and checking their fields
        AccountTeamMemberHistorySelector atmHistorySelector = new AccountTeamMemberHistorySelector();
        List<Account_Team_Member_History__c> updatedRecords = new List<Account_Team_Member_History__c>(atmHistorySelector.getAccountTeamMemberHistoryByAtmIds(new Set<Id>{fakeAtmId}).values());
        
        System.assertEquals(1, updatedRecords.size());
        System.assertEquals('Inactive', updatedRecords[0].Status__c);
        System.assertNotEquals(null, updatedRecords[0].Active_To__c);
        System.assertEquals(UserInfo.getUserId(), updatedRecords[0].Removed_By__c);
    }

    /**
     * Tests creation of Account Team Member History records when the UserSelector returns an empty map.
     * This simulates a scenario where no User records are found for the given User IDs.
     * The test verifies that the history record is still created with 'Unknown User' in the Name field.
     */
    @isTest
    static void successfulCreateWithEmptyUser() {
        // ============================================
        // Setup Test Data
        // ============================================
        //Create fake AccountTeamMember Id for testing without DML operation. To ensure org-agnostic IDs, derive prefix from SObjectType using TestDataFactory
        Id fakeAtmId = TestDataFactory.generateFakeId(AccountTeamMember.SObjectType, true);
        // Get current user and create test Account to associate with the ATM
        Id testUserId = UserInfo.getUserId();
        // Insert test Account; we need a true DML operation for this because AccountTeamMember requires a valid, DML-ified AccountId
        Id testAccountId = Database.insert(TestDataFactory.createAccount('Test')).getId();
        // Create ATM in memory with fake ID
        AccountTeamMember atm = TestDataFactory.createAccountTeamMember( fakeAtmId, testUserId,testAccountId, 'Sales Rep');
        
        // Create mock UserSelector to avoid querying real User records and set the return value to an empty map
        MockUserSelector mockUserSelector = new MockUserSelector();
        mockUserSelector.setReturnValue(new Map<Id, User>());
        // Create mock AccountTeamMemberHistorySelector; we won't need to set its return value for this test, but need it to invoke the overloaded service constructor
        MockAccountTeamMemberHistorySelector mockAtmHistorySelector = new MockAccountTeamMemberHistorySelector();
        // Instantiate service with mock selectors
        AccountTeamMemberHistoryService service = new AccountTeamMemberHistoryService(mockUserSelector,mockAtmHistorySelector);

        // ============================================
        // Begin Test Context
        // ============================================
        Test.startTest();
        // Test creating history record using service method
        List<Account_Team_Member_History__c> createdRecords = service.createHistoryRecords(new List<AccountTeamMember>{atm});     
        Test.stopTest();

        // Verify creation; we expect the Name field to contain 'Unknown User' since the UserSelector returned an empty map
        System.assertEquals(1, createdRecords.size());
        System.assertEquals('Active', createdRecords[0].Status__c);
        System.assertEquals('Unknown User - Sales Rep', createdRecords[0].Name);
    }

    /**
     * Tests successful creation of a large volume (200) of Account Team Member History records via the AccountTeamMemberHistoryService method.
     * This test uses mock selector classes to avoid querying real User and Account Team Member History records.
     * It verifies that all records are created successfully without hitting governor limits or performance issues.
     */
    @isTest
    static void successfulLargeVolumeCreate() {
        // ============================================
        // Setup Test Data
        // ============================================

        // Insert test Account; we need a true DML operation for this because AccountTeamMember requires a valid, DML-ified AccountId
        Id testAccountId = Database.insert(TestDataFactory.createAccount('Test Account')).getId();
        // Get current user and create test Account to associate with the ATM
        Id testUserId = UserInfo.getUserId();
        // Generate 200 fake id for AccountTeamMember records to be inserted; doing this outside of the loop to ensure we have a unique ID for each record 
        // and to avoid calling the generateFakeId method 200 times within the loop which could impact test performance
        List<Id> fakeAtmIds = TestDataFactory.generateFakeIds(AccountTeamMember.SObjectType, 200);
        
        // Create 200 AccountTeamMember records in memory with fake IDs
        List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        for(Integer i=0; i < 200; i++) {
            //Create fake AccountTeamMember Id for testing without DML operation. To ensure org-agnostic IDs, derive prefix from SObjectType using TestDataFactory
            Id fakeAtmId = fakeAtmIds[i];
            AccountTeamMember atm = TestDataFactory.createAccountTeamMember( fakeAtmId, testUserId,testAccountId, 'Sales Rep');
            atmList.add(atm);
        }

        // Create mock UserSelector to avoid querying real User records and set the return value to an empty map
        MockUserSelector mockUserSelector = new MockUserSelector();
        mockUserSelector.setReturnValue(new Map<Id, User>());
        // Create mock AccountTeamMemberHistorySelector; we won't need to set its return value for this test, but need it to invoke the overloaded service constructor
        MockAccountTeamMemberHistorySelector mockAtmHistorySelector = new MockAccountTeamMemberHistorySelector();
        // Instantiate service with mock selectors
        AccountTeamMemberHistoryService service = new AccountTeamMemberHistoryService(mockUserSelector,mockAtmHistorySelector);

        // ============================================
        // Begin Test Context
        // ============================================
        Test.startTest();
        // Test creating history record using service method
        List<Account_Team_Member_History__c> createdRecords = service.createHistoryRecords(atmList);     
        Test.stopTest();

        // Verify creation; we expect 200 records to have been created successfully
        System.assertEquals(200, createdRecords.size());
    }    
}