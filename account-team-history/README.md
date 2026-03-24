# Account Team Member History

## Overview

This asset automatically captures and maintains a complete audit trail of Account Team Member changes including additions, modifications, and removals. Perfect for organizations that need to track team membership history for compliance, reporting, or operational visibility.

## Features

- **Automatic History Tracking** - No manual intervention required
- **Complete Audit Trail** - Captures who made changes and when
- **Role Change Detection** - Tracks modifications to team member roles
- **Bulk Operations Support** - Handles large-volume team changes efficiently
- **Mock-Based Testing** - Comprehensive test coverage with edge case scenarios
- **Framework Integration** - Easily integrates with existing trigger frameworks
- **Extendable** - Easily expand functionality, track additional fields, etc.

## Installation
The asset comes with a Manifest file (/manifest/AccountTeamMemberHistoryAsset.xml), which contains the metadata definitions for the asset (custom object, Apex, Laytou, etc).

Deploy the asset via SF CLI as you would any other manifest-based asset. Or you can manually install the individual components as desired.

## Usage
Account Team Member History records are automatically created and managed on insert, update or deletion of the associated Account Team Member record.

Please referr to the [associated blog post](https://open.substack.com/pub/ilyapinchuk/p/account-team-member-history-the-audit?utm_campaign=post-expanded-share&utm_medium=web) on functionality description and screenshots.

## Architecture

### Key Classes

#### AccountTeamMemberHistoryService Service Class
Main service class handling:
- `createHistoryRecords()` - Creates new history records
- `inactivateHistoryRecords()` - Marks records as inactive

#### Selectors
- **UserSelector** - Retrieves User data for name resolution
- **AccountTeamMemberHistorySelector** - Queries existing history records

#### Trigger Logic
- **AccountTeamMemberTriggerHandler** - Encapsulates trigger functionality for easy integration with existing trigger frameworks
- **AccountTeamMemberTrigger** - Entry point for trigger logic

## Testing

### Test Coverage
- 90%+ code coverage across all components
- Mock-based testing for fast execution
- Edge case scenarios included

### Running Tests

```apex
// Run all tests
@isTest AccountTeamMemberHistoryServiceTest
@isTest UserSelectorTest  
@isTest AccountTeamMemberTriggerTest
```

### Framework Integration

#### fflib Integration
```apex
// In your fflib domain class
public override void onAfterInsert() {
    AccountTeamMemberHistoryService service = new AccountTeamMemberHistoryService();
    service.createHistoryRecords(Records);
}
```

#### Custom Handler Integration
```apex
// In your existing handler
public class MyAccountTeamHandler extends TriggerHandlerBase {
    private AccountTeamMemberHistoryService historyService;
    
    public override void afterInsert() {
        historyService.createHistoryRecords(Trigger.new);
    }
}
```

## Configuration Options

### Trigger Contexts

| Context | Purpose |
|---------|---------|
| After Insert | Creates new history record |
| After Update | Inactivates old record, creates new one |
| Before Delete | Marks existing record as inactive |

### Tracked Changes

Configure which field changes create new history records:

```apex
// In AccountTeamMemberTriggerHandler
private List<String> trackedFields = new List<String>{
    'TeamMemberRole',           // Role changes
    'AccountAccessLevel',       // Access level changes
    'OpportunityAccessLevel'    // Opportunity access changes
};
```

## Data Model

### Account_Team_Member_History__c Fields

| Field | Type | Purpose |
|-------|------|---------|
| Name | Text | Display name (auto-generated) |
| Account__c | Master-Detail | Links to Account |
| Team_Member__c | Lookup | Links to User |
| Status__c | Picklist | Active/Inactive |
| Active_From__c | Date/Time | When membership started |
| Active_To__c | Date/Time | When membership ended |
| Team_Member_Role__c | Text | Role at time of record |
| Account_Access__c | Text | Access level snapshot |
| AccountTeamMemberId__c | Text | Reference to original ATM |

## Reporting

### Sample Reports

**Current Team Composition**
```sql
SELECT Account__r.Name, Team_Member__r.Name, Team_Member_Role__c
FROM Account_Team_Member_History__c 
WHERE Status__c = 'Active'
ORDER BY Account__r.Name
```

**Team Turnover Analysis**
```sql
SELECT Account__r.Name, COUNT(Id) as Changes
FROM Account_Team_Member_History__c
GROUP BY Account__r.Name
ORDER BY COUNT(Id) DESC
```

**User Assignment History**
```sql
SELECT Team_Member__r.Name, Account__r.Name, Active_From__c, Active_To__c
FROM Account_Team_Member_History__c
WHERE Team_Member__c = :userId
ORDER BY Active_From__c DESC
```

## License

This code is part of the **Salesforce Athenaeum Project** and is licensed under GPLv3.

## Related Resources

- [AccountTeamMember Documentation](https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_objects_accountteammember.htm)
- [Trigger Best Practices](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_triggers_best_practices.htm)
- [Testing Best Practices](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_best_practices.htm)

---

**Part of the Salesforce Athenaeum Project** - A curated collection of production-ready Salesforce utilities.
