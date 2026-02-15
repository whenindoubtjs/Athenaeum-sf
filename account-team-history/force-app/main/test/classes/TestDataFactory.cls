/**
 * Test Data Factory class for creating test data used across multiple test classes.
 */
@isTest
public class TestDataFactory {

    /**
     * Generates a fake Id for the specified SObjectType.
     * Useful for creating in-memory records without performing DML operations.
     * @param sObjectType The SObjectType for which to generate a fake Id.
     * @param randomize Boolean flag to determine if the unique part of the Id should be randomized. Default is false (deterministic).
     * @return Id A fake Id corresponding to the specified SObjectType.
     */
    public static Id generateFakeId(Schema.SObjectType sObjectType, Boolean randomize) {
        // Fetch the proper prefix for the ID for the passed sObject
        String keyPrefix = sObjectType.getDescribe().getKeyPrefix();
        String uniquePart;

        // If randomize is true, generate a random unique part; otherwise, use a deterministic unique part
        if(randomize) {
            // Set our sample characters to pick from whe choosing random characters
            String chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
            uniquePart = '';
            // Generate a 8-character random string one char at a time by picking random characters from our sample set
            for(Integer i = 0; i < 8; i++) {
                // Randomizer uses Crypto.getRandomInteger to get a random integer, take its absolute value, and use Math.mod to ensure it falls within the bounds of our chars string
                Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
                uniquePart += chars.substring(randomIndex, randomIndex + 1);
            }
        } else {
            // Deterministic approach (default)
            uniquePart = '00000AAA';
        }
        // Return the fake compound key, constructed of the 3-char prefix, four "control" chars (pod and reserve chars) and eight unique chars
        return Id.valueOf(keyPrefix + '0000' + uniquePart);
    }

    /**
     * Generates a list of fake Ids for the specified SObjectType with deterministic unique parts.
     * @param sObjectType The SObjectType for which to generate fake Ids.
     * @param count The number of fake Ids to generate.
     * @return List<Id> A list of fake Ids corresponding to the specified SObjectType.
     */
    public static List<Id> generateFakeIds(Schema.SObjectType sObjectType, Integer count) {
        String keyPrefix = sObjectType.getDescribe().getKeyPrefix();
        List<Id> fakeIds = new List<Id>();
        
        for(Integer i = 0; i < count; i++) {
            // Use sequential counter to ensure uniqueness
            String suffix = String.valueOf(i).leftPad(12, '0');
            fakeIds.add(Id.valueOf(keyPrefix + suffix));
        }
        
        return fakeIds;
    }

    /**
     * Creates and returns a User record with the specified username and last name to be inserted by the invoking test method.
     * @param username The username for the new User record; should always be in the form of an email address.
     * @param lastName The last name for the new User record.
     * @return User The newly instantiated User record.
     */
    public static User createStandardProfileUser(String username, String lastName) {
        // Fetch the Standard User Profile. All Salesforce orgs have a profile named "Standard User", 
        // making this a reliable way to get a profile for test users
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        
        return new User(
            Username = username + Url.getOrgDomainUrl().getHost(),  // Ensure username is unique by appending org hostName
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
        // Instantiate list to hold users to be returned to the calling method
        List<User> users = new List<User>();
        // Iterate 'count' times, creating a new user each time with a unique username and last name, using the createStandardProfileUser 
        // method defined in this data factory class. The usernames must be unique across the org, so we append the org domain to ensure uniqueness
        for (Integer i = 0; i < count; i++) {
            users.add(createStandardProfileUser(
                'test' + i + '@example.com',
                'TestUser' + i
            ));
        }
        // Return the list of users to the calling method for insertion
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

    /**
     * Creates and returns an AccountTeamMember record with the specified parameters to be inserted by the invoking test method
     * @param userId The UserId to associate with the AccountTeamMember record
     * @param accountId The AccountId to associate with the AccountTeamMember record
     * @param role The TeamMemberRole to assign to the AccountTeamMember record
     * @return AccountTeamMember The newly instantiated AccountTeamMember record
     */
    public static AccountTeamMember createAccountTeamMember(Id mockSalesforceId, Id userId, Id accountId, String role) {
        return new AccountTeamMember(
            Id = mockSalesforceId,
            UserId = userId,
            AccountId = accountId,
            TeamMemberRole = role,
            AccountAccessLevel = 'Read',
            CaseAccessLevel = 'Read',
            OpportunityAccessLevel = 'Read',
            ContactAccessLevel = 'Read'
        );
    }
}