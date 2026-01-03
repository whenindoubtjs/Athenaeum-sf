# Bulk Delete Records

Production-ready batch Apex class for safely deleting large volumes of Salesforce records with comprehensive error handling, monitoring, and configurable behavior.

## Overview

`BulkDeleteRecords` is an Apex batch class that enables deletion of large record sets (10,000+) while avoiding governor limits and providing features such as error tracking, email notifications, and dry run capabilities.

### Key Features

- **Scalable**: Delete millions of records using Salesforce's batch framework
- **Configurable**: Uses fluent interface for easy configuration
- **Safe**: Built-in error handling and validation
- **Observable**: Email notifications and detailed logging of batch delete jobs
- **Flexible**: Supports dry run, hard delete, and custom batch sizes
- **Stateful**: Tracks progress and errors across batch chunks

## Use Cases

### When to Use This Class

- Deleting more than 10,000 records and needing to avoid Apex DML Limits
- Working in orgs with complex trigger logic that slows down DataLoader
- Need background processing without keeping connections open
- Testing deletion impact with dry run mode
- Permanent deletion (hard delete) of sensitive data

### When NOT to Use This Class

- Deleting fewer than 100 records (use simple DML or Anonymous Apex)
- Need immediate, synchronous deletion
- DataLoader works efficiently for your use case

## Usage
Below are a few examples of using this class to acomplish various deletion tasks.

### Basic Usage: Simple deletion with defaults

```apex
String query = 'SELECT Id FROM Contact WHERE Email LIKE \'%test%\'';
BulkDeleteRecords batch = new BulkDeleteRecords(query);
Database.executeBatch(batch, 200);
```

### Additional Configurations: Configure multiple options via fluent method chaining

```apex
String query = 'SELECT Id FROM Contact WHERE Email LIKE \'%test%\'';
BulkDeleteRecords batch = new BulkDeleteRecords(query)
    .setAllOrNone(false)              
    .setHardDelete(true)              
    .setSendEmail(true)               
    .setNotificationEmail('admin@company.com')  
    .setDryRun(false);                
Database.executeBatch(batch, 200);
```

### Dry Run: Test Delete Job and Review Test Results via Eamil

```apex
String query = 'SELECT Id FROM Contact WHERE Email LIKE \'%test%\'';
BulkDeleteRecords batch = new BulkDeleteRecords(query)
    .setDryRun(true)
    .setSendEmail(true);
Database.executeBatch(batch);
```

### Hard Delete: Bypass Recycle Bin During Delete - Use With Caution!!!

```apex
String query = 'SELECT Id FROM Contact WHERE Email LIKE \'%test%\'';
BulkDeleteRecords batch = new BulkDeleteRecords(query)
    .setHardDelete(true)
    .setSendEmail(true);
Database.executeBatch(batch, 100);
```

## Configuration Options

### Constructor

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | String | Yes | SOQL query returning records to delete. Must include `Id` field and contain a SELECT and FROM statements (class checks for malformed queries). |

### Configuration Methods

Configuration methods allow for setting of additional logic using Fluent Interface design pattern. 

| Method | Parameter | Default | Description |
|--------|-----------|---------|-------------|
| `setAllOrNone(Boolean)` | Boolean | `false` | If `true`, entire batch fails on any error. If `false`, continues and tracks failures. |
| `setHardDelete(Boolean)` | Boolean | `false` | If `true`, permanently deletes records (cannot be restored). |
| `setSendEmail(Boolean)` | Boolean | `false` | If `true`, sends completion email with job summary. |
| `setNotificationEmail(String)` | String | Running user's email | Email address for notifications. |
| `setDryRun(Boolean)` | Boolean | `false` | If `true`, counts records without deleting. |

## Query Requirements

### Query Validation

This class performs the following defensive validation on construction:

1. Query must not be `null` or empty
2. Query must contain `SELECT` clause
3. Query must contain `FROM` clause  
4. Query must include `Id` field

### Valid Query Format

```apex
✅ VALID: Basic query
'SELECT Id FROM Contact WHERE LastName = \'Test\''

✅ VALID: Complex filters
'SELECT Id FROM Opportunity WHERE StageName = \'Closed Lost\' AND CloseDate < LAST_YEAR'

✅ VALID: Multiple fields (Id required, others optional)
'SELECT Id, Name FROM Account WHERE Type = \'Prospect\''

❌ INVALID: Missing Id field
'SELECT Name FROM Contact'

❌ INVALID: Missing SELECT
'FROM Contact WHERE Name = \'Test\''
```

## Error Handling
This class throws a custom Apex exception `BulkDeleteRecords.BatchMassDeleteException`to handle expected errors

### Status & Error Tracking

The class automatically tracks:
- Total records processed
- Successful deletions
- Failed deletions
- Error messages (up to 100 to prevent memory issues, but this can be changed if desired)

### Viewing Errors

Errors are available via:
1. **Debug Logs**: All errors logged with `ERROR` level
2. **Email Summary**: Sent if `setSendEmail(true)` is configured
3. **Batch Job**: Query `AsyncApexJob` for job status

```apex
AsyncApexJob job = [
    SELECT Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
    FROM AsyncApexJob 
    WHERE Id = :jobId
];
```

## Email Notifications
### Email Content
When `setSendEmail(true)` is enabled, completion emails include:
- Job ID and status
- Start time and duration
- Total records processed
- Success/failure counts
- Detailed error messages (up to 100)
- Dry run indicator (if applicable)

### Example Email

```
========================================
Batch Mass Delete - DELETE - COMPLETE
========================================
Job ID: 7071234567890ABC
Status: Completed
Started: Jan 2, 2026 3:45 PM
Duration: 127 seconds

RESULTS:
Total Processed: 15000
Successful: 14987
Failed: 13

ERRORS (13 shown):
  - Record 003XXXXXXXX: FIELD_CUSTOM_VALIDATION_EXCEPTION (Fields: Status__c)
  - Record 003XXXXXXXY: DELETE_FAILED (Fields: Id)
  ...
========================================
```

## Technical Details

### Interfaces Implemented

- `Database.Batchable<SObject>`: Enables batch processing
- `Database.Stateful`: Maintains statistics across chunks

### Governor Limits Impacts

| Limit | Per Chunk | Notes |
|-------|-----------|-------|
| DML Rows | Up to batch size | Default 200 |
| SOQL Queries | 1 (start method) | QueryLocator handles large datasets |
| Heap Size | ~6 MB | Error list capped at 100 messages |
| CPU Time | 10,000 ms | Per chunk |

### Batch Lifecycle

1. **Constructor**: Validates query, initializes state
2. **start()**: Executes query via `QueryLocator` (once)
3. **execute()**: Processes each chunk of records (multiple times)
   - Performs deletions
   - Tracks success/failure
   - Optionally hard deletes
4. **finish()**: Generates summary, sends email (once)

## Troubleshooting

### "Query must include Id field for deletion"

**Cause**: Query doesn't select the `Id` field  
**Fix**: Add `Id` to SELECT clause: `SELECT Id, Name FROM...`

### Batch fails on first chunk

**Cause**: `allOrNone=true` with validation errors  
**Fix**: Use `.setAllOrNone(false)` to continue processing

### Email not received

**Cause**: Email delivery settings or test context  
**Fix**: Check Setup → Email Administration → Deliverability. Note: emails don't send in test context.

### CPU Timeout errors

**Cause**: Complex triggers consuming CPU time  
**Fix**: Reduce batch size

### Hard delete fails

**Cause**: Recycle bin permissions or record lock  
**Fix**: Ensure running user has "Bulk API Hard Delete" permission

## Version History

### v1.0
- Production-ready release
- Fluent interface for configuration
- Comprehensive error handling
- Email notifications
- Dry run mode
- Hard delete support
- Stateful tracking across chunks

## License & Extension

This code is open-sourced and covered under GPLv3 licensed and can be used and extended in any open manner

---

**Part of the Salesforce Athenaeum Project** - A curated collection of production-ready Salesforce utilities.