/*
 * OrgVersionController.cls
 * Apex controller class for fetching the latest API version of the org, with caching implemented using a custom setting (OrgVersionCache__c).
 * This class is designed to be called from a Lightning Web Component (LWC) to display the current org version in the UI, and to minimize callouts by caching the result for a specified duration (default is 7 days).
 * The class includes a wrapper class (OrgVersionWrapper) to easily store and parse the data passed back from the JSON array of the API Callout response.
 * The main method (fetchOrgVersion) checks the cache for a fresh value before making a callout, and updates the cache with the latest version information and timestamp when a new callout is made.
 * Error handling is implemented to catch callout failures and DML exceptions when updating the cache, with debug logs for troubleshooting.
 */
public with sharing class OrgVersionController {

    // Wrapper class to easily store and parse the data passed back from the JSON array of the API Callout response to the LWC
    public class OrgVersionWrapper {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String version { get; set; }
    }

    // Primary invocable method called by the LWC to fetch the latest API version of the org, with caching implemented using a custom setting (OrgVersionCache__c)
    @AuraEnabled
    public static OrgVersionWrapper fetchOrgVersion() {
        // Fetch the custom setting record that stores the cached org version information
        OrgVersionCache__c cache = OrgVersionCache__c.getOrgDefaults();
        // Check if the cached value is still considered "fresh" (usable) based on the Last Fetched Date. If it is, return the cached values
        if (isCacheFresh(cache)) {
            System.debug('Fetching Cached Value');
            OrgVersionWrapper cachedValues = new OrgVersionWrapper();
            cachedValues.label = cache.Version_Label__c;
            cachedValues.version = cache.Version_Number__c;
            return cachedValues;
        }
        // If the cache is not fresh, proceed to make the callout to fetch the latest org version, and update the cache with the new values and current timestamp before returning the result
        return fetchAndCache();
    }

    // Helper method that handles when the cached value is considered "fresh" (usable) or not based on the Last Fetched Date.
    // By default, this is set to 7 days, but can be adjusted as needed with more complex cache management logic
    private static Boolean isCacheFresh(OrgVersionCache__c cache) {
        return cache.Last_Fetched__c != null && cache.Last_Fetched__c > Date.today().addDays(-7);
    }

    // Helper method that performs the callout to fetch the latest org version, updates the cache with the new values and current timestamp, and returns the latest version information back to 
    // the calling method (fetchOrgVersion) to be passed to the LWC for display in the UI
    private static OrgVersionWrapper fetchAndCache() {
        // Set endpoint for the callout to the current org's url + /services/data/ to get the list of available API versions
        String endpoint = URL.getOrgDomainUrl().toExternalForm() + '/services/data/';

        // Make the callout to fetch the API versions
        HttpRequest calloutRequest = new HttpRequest();
        calloutRequest.setEndpoint(endpoint);
        calloutRequest.setMethod('GET');

        // Capture the response; if the status code is not 200, throw an exception, otherwise parse the response to get the latest version
        HttpResponse calloutResponse = new Http().send(calloutRequest);
        if (calloutResponse.getStatusCode() != 200) {
            throw new CalloutException('Org version callout failed. Status: ' + calloutResponse.getStatusCode());
        }

        // Deserialize the JSON response into a list of OrgVersionWrapper objects, and return the last one in the list (the latest version)
        List<OrgVersionWrapper> versions = (List<OrgVersionWrapper>) JSON.deserialize(calloutResponse.getBody(), List<OrgVersionWrapper>.class);
        if (versions == null || versions.isEmpty()) {
            throw new CalloutException('Org version response was empty or malformed.');
        }

        // The API will always return the versions in order from oldest to newest, so we can simply take the last one in the list to get the latest version
        OrgVersionWrapper latest = versions.get(versions.size() - 1);

        // Update the cache with the latest version information and current timestamp
        OrgVersionCache__c cache = OrgVersionCache__c.getOrgDefaults();
        cache.Version_Label__c = latest.label;
        cache.Version_Number__c = latest.version;
        cache.Last_Fetched__c = Date.today();
        System.debug('Inserting New Cache Value');

        // Attempt to Upsert the cache record; if it fails, catch the exception and log an error message, but still return the latest version information 
        // to be displayed in the UI (the cache will simply be updated on the next fetch attempt)
        // A more dedicated error handling reporting method can be implemented here as needed.
        try {
            upsert cache;
        } catch(DmlException e) {
            System.debug('Unable to update cache: ' + e.getMessage());
        }

        // Return the latest version information back to the calling class, which will pass it to the LWC to be displayed in the UI
        return latest;
    }
}