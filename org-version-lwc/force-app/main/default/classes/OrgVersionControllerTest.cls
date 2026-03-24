@isTest
private class OrgVersionControllerTest {

    // Mock class to simulate a successful HTTP callout response
    private class MockHttpSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('[{"label":"Spring 26","version":"66.0"},{"label":"Summer 26","version":"67.0"}]');
            return res;
        }
    }

    // Mock class to simulate a failed HTTP callout response
    private class MockHttpFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }

    // Mock class to simulate an empty response body
    private class MockHttpEmpty implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('[]');
            return res;
        }
    }

    @isTest
    // Test method to verify that when a fresh cache exists, the controller returns the cached values without making a callout
    static void testFetchOrgVersion_CacheHit() {
        // Insert a fresh cache record to simulate a recent fetch
        OrgVersionCache__c cache = new OrgVersionCache__c();
        cache.Version_Label__c = 'Spring 26';
        cache.Version_Number__c = '66.0';
        cache.Last_Fetched__c = Date.today().addDays(-1);
        upsert cache;

        // Invoke the method to fetch the org version, which should return the cached values without making a callout
        Test.startTest();
        OrgVersionController.OrgVersionWrapper result = OrgVersionController.fetchOrgVersion();
        Test.stopTest();

        // Assert
        Assert.areEqual('Spring 26', result.label, 'Label should match the cached value');
        Assert.areEqual('66.0', result.version, 'Version should match the cached value');
    }

    @isTest
    // Test method to verify that when the cache is stale (older than 7 days), the controller makes a callout to fetch the latest version and updates the cache accordingly
    static void testFetchOrgVersion_CacheMiss_StaleCache() {
        // Insert a stale cache record to force a callout
        OrgVersionCache__c cache = new OrgVersionCache__c();
        cache.Version_Label__c = 'Winter 25';
        cache.Version_Number__c = '63.0';
        cache.Last_Fetched__c = Date.today().addDays(-30);
        upsert cache;

        // Set the mock callout to return a successful response with the latest version information
        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        // Invoke the method to fetch the org version, which should make a callout due to stale cache, and return the latest version information from the mock response
        Test.startTest();
        OrgVersionController.OrgVersionWrapper result = OrgVersionController.fetchOrgVersion();
        Test.stopTest();

        // Assert - should return the last element from the mock response
        Assert.areEqual('Summer 26', result.label, 'Label should reflect the latest version from the callout');
        Assert.areEqual('67.0', result.version, 'Version should reflect the latest version from the callout');

        // Assert cache was updated
        OrgVersionCache__c updatedCache = OrgVersionCache__c.getOrgDefaults();
        Assert.areEqual('Summer 26', updatedCache.Version_Label__c, 'Cache label should be updated after callout');
        Assert.areEqual('67.0', updatedCache.Version_Number__c, 'Cache version should be updated after callout');
        Assert.isNotNull(updatedCache.Last_Fetched__c, 'Last fetched timestamp should be set after callout');
    }

    @isTest
    // Test method to verify that when no cache record exists, the controller makes a callout to fetch the latest version and creates a new cache record with the fetched values
    static void testFetchOrgVersion_CacheMiss_NoCache() {
        // Set the mock callout to return a successful response with the latest version information
        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        // Invoke the method to fetch the org version, which should make a callout due to no existing cache, and return the latest version information from the mock response
        Test.startTest();
        OrgVersionController.OrgVersionWrapper result = OrgVersionController.fetchOrgVersion();
        Test.stopTest();

        // Assert
        Assert.areEqual('Summer 26', result.label, 'Label should reflect the latest version from the callout');
        Assert.areEqual('67.0', result.version, 'Version should reflect the latest version from the callout');
    }

    @isTest
    // Test method to verify that when the callout fails (e.g., returns a 500 status), the controller throws a CalloutException and does not update the cache
    static void testFetchOrgVersion_CalloutFailure() {
        // Set the mock callout to simulate a failure response
        Test.setMock(HttpCalloutMock.class, new MockHttpFailure());

        // Invoke the method to fetch the org version, which should throw a CalloutException due to the simulated failure, and assert that the exception message contains the expected status code
        Test.startTest();
        try {
            OrgVersionController.fetchOrgVersion();
            Assert.fail('Expected a CalloutException to be thrown');
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains('500'), 'Exception message should contain the status code');
        }
        Test.stopTest();
    }

    @isTest
    // Test method to verify that when the callout returns an empty response, the controller throws a CalloutException indicating that the response was empty or malformed
    static void testFetchOrgVersion_EmptyResponse() {
        // Set the mock callout to simulate an empty response body
        Test.setMock(HttpCalloutMock.class, new MockHttpEmpty());

        // Invoke the method to fetch the org version, which should throw a CalloutException due to the empty response, and assert that the exception message indicates that the response was empty or malformed
        Test.startTest();
        try {
            OrgVersionController.fetchOrgVersion();
            Assert.fail('Expected a CalloutException to be thrown for empty response');
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains('empty or malformed'), 'Exception message should indicate empty response');
        }
        Test.stopTest();
    }
}