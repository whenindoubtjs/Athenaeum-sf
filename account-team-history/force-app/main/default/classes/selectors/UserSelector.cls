/*
    Selector class for User-related queries that can be included in any service or trigger handler classes
    This class is virtual to allow for easy mocking during unit tests of classes that depend on it

    Field Selection:
    This selector uses a single field set for simplicity. For most use cases (querying specific users by ID),
    the performance difference is negligible.
    
    If you need to optimize for large datasets (1,000+ records), large volume of fields to retrieve
    or have distinct use cases requiring different field sets, consider refactoring to use multiple
    field sets (base fields + extended fields pattern).
*/
public virtual with sharing class UserSelector {

    //Default constructor
    public UserSelector() {}

    //Field set defining which User fields to retrieve in queries. Can be modified to add/remove fields as needed
    private static final List<Schema.SObjectField> USER_FIELDS = new List<Schema.SObjectField>{
        User.Id,
        User.Name,
        User.Email
    };

    /**
     * Helper method to convert the USER_FIELDS list into a comma-separated string for use in dynamic SOQL queries
     * @return String Comma-separated string of User field names
     */
    private static String getFieldString() {
        List<String> fieldNames = new List<String>();
        for (Schema.SObjectField field : USER_FIELDS) {
            fieldNames.add(field.getDescribe().getName());
        }
        return String.join(fieldNames, ', ');
    }

    /** 
     * Fetches User records for the given set of User IDs.
     * 
     * @param userIds Set of User IDs for which to fetch User records
     * @return Map<Id, User> Map of User records keyed by their IDs
    */
    public virtual Map<Id, User> getUsersByIds(Set<Id> userIds) {
        //Defensive check - if userId is null or empty, return empty list
        if (userIds == null || userIds.isEmpty()) {
            return new Map<Id, User>();
        }
        
        //Otherwise, build queryString from defined list of fields and run query fetching User record for the given userId
        //This will either return a map of User records, a empty map if no records found, or a QueryException if an error occurs
        //Database.query() returns a list of sObjects. To send it to a map, we have to explicitly cast it to List<User> and then to Map<Id, User>
        String query = 'SELECT ' + getFieldString() + ' FROM User WHERE Id IN :userIds';
        return new Map<Id, User>((List<User>)Database.query(query));
    }
}