//Test class for BulkDeleteRecords
//Provides comprehensive test coverage for basic deletion scenarios and edge cases, testing of fluent interface config methods, error handling
//and dry run/hard delete functionality. This class uses the modern System.Assert class for System.Assertions
@isTest
private class BulkDeleteRecordsTest {
    //Static number of test records to create
    private static final Integer TEST_RECORD_COUNT = 50;
    
    //TestSetup: Create test data for all test methods in the class
    @testSetup
    static void setupTestData() {
        //Init list to store test contacts to be created
        List<Contact> contactsToInsert = new List<Contact>();
        //Create a contact up to TEST_RECORD_COUNT limit and init with generic information
        for(Integer i = 0; i < TEST_RECORD_COUNT; i++) {
            contactsToInsert.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact' + i,
                Email = 'test' + i + '@example.com'
            ));
        }
        //Insert the contacts
        insert contactsToInsert;
        
        //Create some accounts for multi-object testing
        List<Account> testAccounts = new List<Account>();
        for(Integer i = 0; i < 10; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i
            ));
        }
        insert testAccounts;
    }
    
    //Basic deletion test; verifies that records matching query are deleted
    @isTest
    static void testBasicDeletion() {
        //Set up query to select test contacts
        String query = 'SELECT Id FROM Contact WHERE LastName LIKE \'Contact%\'';
        
        //Execute the batch to delete the records
        Test.startTest();
        BulkDeleteRecords batch = new BulkDeleteRecords(query);
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        //Verify all contacts were deleted
        List<Contact> remainingContacts = [SELECT Id FROM Contact WHERE LastName LIKE 'Contact%'];
        System.Assert.areEqual(0, remainingContacts.size(), 'All test contacts deleted');
    }
    
    //Tests fluent interface configration methods
    @isTest
    static void testFluentInterface() {
        //Set up query to select test contacts
        String query = 'SELECT Id FROM Contact WHERE LastName LIKE \'Contact%\'';
        
        Test.startTest();
        //Test each fulent configuration method to ensure coverage and verify functionality
        BulkDeleteRecords batch = new BulkDeleteRecords(query)
            .setAllOrNone(false)
            .setHardDelete(false)
            .setSendEmail(false)
            .setDryRun(false);
        //Execute the batch to delete the records
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        //Verify all contacts were deleted
        List<Contact> remainingContacts = [SELECT Id FROM Contact WHERE LastName LIKE 'Contact%'];
        System.Assert.areEqual(0, remainingContacts.size(), 'All test contacts deleted with fluent configuration set');
    }
    
    //Test dry run functionality
    @isTest
    static void testDryRunMode() {
        //Set up query to select test contacts
        String query = 'SELECT Id FROM Contact WHERE LastName LIKE \'Contact%\'';
        
        Test.startTest();
        //Set the dry run configuration to true and execute the batch
        BulkDeleteRecords batch = new BulkDeleteRecords(query).setDryRun(true);
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        //Verify all contacts were not deleted, as expected from a dry run. System.Assert statement should confirm record count remains unchanged from
        //initiated batch of records created during the Test Setup step
        List<Contact> remainingContacts = [SELECT Id FROM Contact WHERE LastName LIKE 'Contact%'];
        System.Assert.areEqual(TEST_RECORD_COUNT, remainingContacts.size(), 'Dry run did not delete records');
    }
    
    //Test hard delete functionality; this is mildly redundant with basic deletion test, as you can't check recycle bin
    //values in testing context but included for completeness in case future Apex testing capabilities change
    @isTest
    static void testHardDelete() {
        //Set up query to select test contacts
        String query = 'SELECT Id FROM Contact WHERE LastName LIKE \'Contact%\'';
        
        Test.startTest();
        //Set hard delete configuration to true and execute the batch
        BulkDeleteRecords batch = new BulkDeleteRecords(query).setHardDelete(true);
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        //Unfortunately, there is no easy way to check recycle bin contents in test context, so we just check for deletion
        List<Contact> remainingContacts = [SELECT Id FROM Contact WHERE LastName LIKE 'Contact%'];
        System.Assert.areEqual(0, remainingContacts.size(), 'Hard delete removed all records');
    }
    
    //Test email send notification functionality with custom email address; this is also mildly redundant as email sending cannot be
    //verified in test context but included for code coverage and completeness
    @isTest
    static void testCustomNotificationEmail() {
        //Set up qiuery and custom noficiation email
        String query = 'SELECT Id FROM Contact WHERE LastName LIKE \'Contact%\'';
        String customEmail = 'custom@example.com';
        
        Test.startTest();
        //Execute with custom notification email
        BulkDeleteRecords batch = new BulkDeleteRecords(query)
            .setSendEmail(true)
            .setNotificationEmail(customEmail);
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        //Verify records were deleted; email will not actually be sent in test context, so we just verify deletion, but 
        //this does provide code coverage for the email configuration and send functionality
        List<Contact> remainingContacts = [SELECT Id FROM Contact WHERE LastName LIKE 'Contact%'];
        System.Assert.areEqual(0, remainingContacts.size(), 'Records should be deleted');
    }

    //Test defensive check when an empty query is used in the constructor. Can also use an empty string instead of a null value 
    //to check if desired
    @isTest
    static void testNullQuery() {
        //Set hard-null as our query
        String query = null;
        
        //Attempt to construct the batch with a null query and verify exception is thrown
        Test.startTest();
        try {
            BulkDeleteRecords batch = new BulkDeleteRecords(query);
            System.Assert.Fail('Expecting thrown exception for null query');
        } catch(BulkDeleteRecords.BatchMassDeleteException e) {
            //Verify the thrown exception is the correct one by checking its contents for keyword
            System.Assert.isTrue(e.getMessage().contains('null or empty'), 
                         'Exception message should mention null or empty query');
        }
        Test.stopTest();
    }
    
    
    //Test defensive check when an invalid query is used in the constructor (missing SELECT clause)
    @isTest
    static void testInvalidQueryMissingSelect() {
        //Set up malformed query missing SELECT clause
        String query = 'FROM Contact WHERE Name = \'Test\'';
        
        //Attempt to construct the batch with a malformed query and verify exception is thrown
        Test.startTest();
        try {
            BulkDeleteRecords batch = new BulkDeleteRecords(query);
            System.Assert.Fail('Expecting thrown exception for query missing SELECT');
        } catch(BulkDeleteRecords.BatchMassDeleteException e) {
            //Verify the thrown exception is the correct one by checking its contents for keyword
            System.Assert.isTrue(e.getMessage().contains('SELECT and FROM'), 
                         'Exception message should mention SELECT and FROM clauses');
        }
        Test.stopTest();
    }
    
    
    //Test defensive check when a query missing the Id field is used in the constructor; Id field is required for deletion
    @isTest
    static void testQueryMissingIdField() {
        //Set up query missing Id field
        String query = 'SELECT Name FROM Contact WHERE Name = \'Test\'';
        
        //Attempt to construct the batch with a malformed query and verify exception is thrown
        Test.startTest();
        try {
            BulkDeleteRecords batch = new BulkDeleteRecords(query);
            System.Assert.Fail('Expecting a thrown exception for query missing Id field');
        } catch(BulkDeleteRecords.BatchMassDeleteException e) {
            //Verify the thrown exception is the correct one by checking its contents for keyword
            System.Assert.isTrue(e.getMessage().contains('Id field'), 
                         'Exception message should mention Id field requirement');
        }
        Test.stopTest();
    }
}