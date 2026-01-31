/**
 * Test Data Factory class for creating test data used across multiple test classes.
 */
@isTest
public class TestDataFactory {
    /**
     * Creates and returns a User record with the specified username and last name to be inserted by the invoking test method
     * @param username The username for the new User record; should always be in the form of an email address
     * @param lastName The last name for the new User record
     * @return User The newly instantiated User record
     */
    public static User createStandardProfileUser(String username, String lastName) {
        //Fetch the Standard User Profile. All Salesforce orgs have a profile named "Standard User", 
        //making this a reliable way to get a profile for test users
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        
        return new User(
            Username = username + Url.getOrgDomainUrl().getHost(),  //Ensure username is unique by appending org hostName
            LastName = lastName,
            ProfileId = standardProfile.Id,
            Alias = lastName.left(8),
            Email = username,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
    }
    
    /**
     * Creates and returns a list of User records with the specified count to be inserted by the invoking test method
     * @param count The number of User records to create
     * @return List<User> The list of newly instantiated User records
     * @see TestDataFactory.createStandardProfileUser
     */
    public static List<User> createUsers(Integer count) {
        //Instantiate list to hold users to be returned to the calling method
        List<User> users = new List<User>();
        //Iterate 'count' times, creating a new user each time with a unique username and last name, using the createStandardProfileUser 
        //method defined in this data factory class. The usernames must be unique across the org, so we append the org domain to ensure uniqueness
        for (Integer i = 0; i < count; i++) {
            users.add(createStandardProfileUser(
                'test' + i + '@example.com',
                'TestUser' + i
            ));
        }
        //Return the list of users to the calling method for insertion
        return users;
    }

    /**
     * Creates and returns an Account record with the specified name to be inserted by the invoking test method
     * @param accountName The name for the new Account record
     * @return Account The newly instantiated Account record
     */
    public static Account createAccount(String accountName) {
        return new Account(
            Name = accountName
        );
    }

    /**
     * Creates and returns a list of Account records with the specified count to be inserted by the invoking test method
     * @param count The number of Account records to create
     * @return List<Account> The list of newly instantiated Account records
     */
    public static List<Account> createAccounts(Integer count) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(createAccount('Test Account ' + i));
        }
        return accounts;
    }
}