# Org Release Version

A lightweight LWC that displays the current Salesforce release version and API version of the org. Built for admin dashboards and internal tooling pages where knowing the org's current release at a glance is useful.

Displays the human-readable release label (e.g. `Spring '26`) alongside the corresponding API version number (e.g. `66.0`). Auto-loads on component render with no user interaction required. Caches the result in a Hierarchy Custom Setting to avoid redundant callouts — the API is only hit when the cached value is older than 7 days.

---

## What's Included

| File | Type | Description |
|------|------|-------------|
| `OrgVersionController.cls` | Apex | `@AuraEnabled` controller; handles callout, caching read/write, and deserialization |
| `OrgVersionControllerTest.cls` | Apex | Test class with full branch coverage across cache and callout scenarios |
| `orgReleaseVersion.html` | LWC | Template with loading, error, and success states |
| `orgReleaseVersion.js` | LWC | Component controller; invokes Apex imperatively via `connectedCallback` |
| `orgReleaseVersion.js-meta.xml` | LWC | Component metadata |
| `OrgVersionCache__c.object-meta.xml` | Custom Setting | Hierarchy Custom Setting definition for version caching |

---

## How It Works

On component load, `connectedCallback` calls `OrgVersionController.fetchOrgVersion()`. The Apex method checks the `OrgVersionCache__c` Hierarchy Custom Setting:

- **Cache is fresh** (fetched within the last 7 days, but this can be modified to your liking) → returns the cached label and version, no callout made
- **Cache is stale or empty** → makes an HTTP GET to `{orgDomain}/services/data/`, deserializes the response, upserts the Custom Setting with the latest values and a new timestamp, returns the result

The `/services/data/` endpoint returns an ordered array of all API versions applied to the org. The last element in the array is always the current release.

---

## Prerequisites

### Remote Site Settings

The component makes an HTTP callout to the org's own My Domain URL. This domain must be registered as an active Remote Site before deployment.

1. Navigate to **Setup → Security → Remote Site Settings**
2. Click **New Remote Site**
3. Set **Remote Site Name** to `OrgDomain` (or any label)
4. Set **Remote Site URL** to your org's My Domain URL (e.g. `https://yourorg.my.salesforce.com`)
5. Ensure **Active** is checked
6. Save

> **Note:** The first load in any org will always make a live callout regardless of cache state, as no cached record exists yet. Subsequent loads within the 7-day TTL window will read from the Custom Setting only.

---

## Custom Setting Fields

The `OrgVersionCache__c` Hierarchy Custom Setting is included in the deployment package. No manual object setup is required.

| Field | API Name | Type | Description |
|-------|----------|------|-------------|
| Version Label | `Version_Label__c` | Text(255) | Human-readable release name, e.g. `Spring '26` |
| API Version | `Version_Number__c` | Text(20) | API version number, e.g. `66.0` |
| Last Fetched | `Last_Fetched__c` | DateTime | Timestamp of the most recent successful callout |

---

## Adding the Component to a Page

1. Navigate to the target Lightning Page in the App Builder
2. Search for `Org Release Version` in the component panel
3. Drag onto the page layout
4. Save and activate

The component requires no configuration properties. It renders automatically on load.

---

## Caching Behavior

| Scenario | Behavior |
|----------|----------|
| No cache record exists | Live callout made; cache record created |
| Cache record exists, fetched within 7 days | Cached values returned; no callout |
| Cache record exists, older than 7 days | Live callout made; cache record updated |
| Callout fails | Error state displayed in component; cache not updated |
| Custom Setting upsert fails | Error logged silently; correct version data still returned to LWC |

The 7-day TTL is intentionally conservative. Salesforce releases three times per year, so a weekly cache refresh is more than sufficient to stay current without unnecessary callout volume.

To adjust the TTL, modify the `isCacheFresh` method in `OrgVersionController.cls`:

```apex
private static Boolean isCacheFresh(OrgVersionCache__c cache) {
    return cache.Last_Fetched__c != null 
        && cache.Last_Fetched__c > DateTime.now().addDays(-7); // Change -7 to your preferred TTL
}
```

---

## Troubleshooting

### Component loads but shows an error

**Most likely cause:** Remote Site Settings entry is missing or the URL does not match the org's My Domain exactly.

**Fix:** Confirm the Remote Site URL matches `URL.getOrgDomainUrl().toExternalForm()` for your org — including protocol and subdomain. No trailing slash.

---

### Component shows a spinner indefinitely

**Likely cause:** The Apex callout is timing out or throwing an unhandled exception before the error state can render.

**Fix:** Check Apex debug logs for callout errors. Confirm the org's My Domain URL is accessible and the Remote Site entry is active.

---

### Version displayed is outdated after a Salesforce release

**Likely cause:** The cached value is still within the 7-day TTL window.

**Fix:** Clear the cache by deleting or blanking the `Last_Fetched__c` field on the `OrgVersionCache__c` org default record via **Setup → Custom Settings → OrgVersionCache → Manage**. The next page load will trigger a fresh callout.

---

## Architecture Notes

All logic lives in a single `OrgVersionController.cls` following a single-responsibility structure for a utility of this scope. The class is organized into three methods:

- `fetchOrgVersion()` — public `@AuraEnabled` entry point; orchestrates cache check and delegation
- `isCacheFresh()` — private; evaluates the TTL against the cached timestamp
- `fetchAndCache()` — private; executes the HTTP callout, parses the response, and upserts the cache

The `OrgVersionWrapper` inner class maps directly to the JSON response schema of the `/services/data/` endpoint, enabling typed deserialization without manual field mapping.

**Platform Cache alternative:** For orgs with a configured Platform Cache partition, `Cache.Org.put()` / `Cache.Org.get()` with a TTL is a cleaner alternative to the Custom Setting approach. This asset uses a Hierarchy Custom Setting by default to ensure drop-in deployability with no manual infrastructure setup required.

---

## Test Coverage

| Test Method | Scenario Covered |
|-------------|-----------------|
| `testFetchOrgVersion_CacheHit` | Fresh cache record; no callout made; cached values returned |
| `testFetchOrgVersion_CacheMiss_StaleCache` | Expired cache; callout made; cache updated with fresh values |
| `testFetchOrgVersion_CacheMiss_NoCache` | No cache record; callout made; cache created |
| `testFetchOrgVersion_CalloutFailure` | Non-200 HTTP response; `CalloutException` thrown |
| `testFetchOrgVersion_EmptyResponse` | 200 response with empty array; `CalloutException` thrown |

---

## License

This asset is part of the **Salesforce Athenaeum Project** and is licensed under GPLv3.