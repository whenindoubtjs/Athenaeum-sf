 //Batch class for safely deleting large volumes of records with 
 //comprehensive error handling, monitoring, and configurable behavior.
  
 //USAGE: This class can be invoked from anonymous Apex or other classes via the following sample invocation code:
 //
 //String query = 'SELECT Id FROM Contact WHERE LastName = \'Test\'';
 //BulkDeleteRecords batch = new BulkDeleteRecords(query);
 //Database.executeBatch(batch, 200);
 //
 //Advanced usage with options:
 //BulkDeleteRecords batch = new BulkDeleteRecords(query)
 //   .setAllOrNone(false)              //Continue processing even if some records fail
 //   .setHardDelete(true)              //Bypass recycle bin
 //   .setSendEmail(true)               //Send completion email to running user
 //   .setDryRun(false);                //Actually perform deletes (true = count only)
 //Database.executeBatch(batch, 200);

public class BulkDeleteRecords implements Database.Batchable<SObject>, Database.Stateful {   

    private final String query;                 //SOQL query string identifying records to delete
    private Boolean allOrNone = false;          //If true, entire batch fails if any record fails to delete
    private Boolean hardDelete = false;         //If true, permanently delete records (bypass recycle bin)
    private Boolean sendEmail = false;          //If true, send email notification on completion
    private Boolean dryRun = false;             //If true, only count records without actually deleting
    private String notificationEmail;           //Email address to send notifications to (defaults to running user)

    //Stateful tracking variables (persist across batch chunks)
    private Integer totalProcessed = 0;
    private Integer totalSuccess = 0;
    private Integer totalFailed = 0;
    private List<String> errorMessages = new List<String>();
    private DateTime startTime;
    
    //Constants
    private static final Integer MAX_ERROR_MESSAGES = 100; //Prevent list from growing too large
    
    //CONSTRUCTOR: Used for initiation of the class\\

    //Primary constructor - initializes class with provided query and executes defensive validation checks.
    //@param inputQuery SOQL query that returns records to delete. Must include Id field.
    //@throws BatchMassDeleteException if query is invalid
    public BulkDeleteRecords(String inputQuery) {
        //Defensive check - If query is null or empty, throw exception
        if(String.isBlank(inputQuery)) {
            throw new BatchMassDeleteException('Query string cannot be null or empty');
        }

        //Defensive check: ensure query has SELECT and FROM
        String normalizedQuery = inputQuery.trim().toLowerCase();
        if(!normalizedQuery.startsWith('select') || !normalizedQuery.contains('from')) {
            throw new BatchMassDeleteException('Invalid SOQL query: must contain SELECT and FROM clauses');
        }
        
        //Defensive check: Ensure Id field is part of query (required for delete)
        if(!normalizedQuery.contains('id')) {
            throw new BatchMassDeleteException('Query must include Id field for deletion');
        }

        //Assign query to class variable and initialize start time
        this.query = inputQuery;
        this.startTime = DateTime.now();
    }

    //CONFIGURATION METHODS: Used to set optional properties

    //Set allOrNone behavior for delete operations
    //@param allOrNone: If true, entire batch fails if any record fails. If false, continue processing and track individual failures.
    public BulkDeleteRecords setAllOrNone(Boolean allOrNone) {
        this.allOrNone = allOrNone;
        return this;
    }

    //Enable/disable hard delete (bypass recycle bin)
    //@param hardDelete: If true, records are permanently deleted and cannot be restored
    public BulkDeleteRecords setHardDelete(Boolean hardDelete) {
        this.hardDelete = hardDelete;
        return this;
    }

    //Enable/disable email notification on completion
    //@param sendEmail: If true, sends summary email to running user on completion
    public BulkDeleteRecords setSendEmail(Boolean sendEmail) {
        this.sendEmail = sendEmail;
        return this;
    }

    //Set custom notification email address
    //@param email: Email address to send completion notification
    public BulkDeleteRecords setNotificationEmail(String email) {
        this.notificationEmail = email;
        return this;
    }

    //Enable/disable dry run mode
    //@param dryRun: If true, only count records without performing deletes
    public BulkDeleteRecords setDryRun(Boolean dryRun) {
        this.dryRun = dryRun;
        return this;
    }

    //BATCHABLE INTERFACE METHODS: Methods required by the Batchable interface to process records\\

    //Start method - Entry point for batch class
    //Retrieves all records matching the query using QueryLocator for efficient processing, automaticallty invokes execute method in chunks.
    public Database.QueryLocator start(Database.BatchableContext BatchContext) {
        System.debug('BulkDeleteRecords: Starting batch job');
        System.debug('Query: ' + query);
        System.debug('Configuration: allOrNone=' + allOrNone + ', hardDelete=' + hardDelete + 
                     ', dryRun=' + dryRun + ', sendEmail=' + sendEmail);
        return Database.getQueryLocator(query);
    }
    
    //Execute method - called once per batch chunk
    //Performs the actual delete operation with comprehensive error handling
    //@param BatchContext: provided by Salesforce
    //@param listOfRecordsInChunk: List of records in this chunk to process
    public void execute(Database.BatchableContext BatchContext, List<SObject> listOfRecordsInChunk) {
        //Defensive check: ensure list of records is not empty or null
        if(listOfRecordsInChunk == null || listOfRecordsInChunk.isEmpty()) {
            return;
        }

        //Set up debugging info; chunck size (number of records in current batch) and total process (number of records in job)
        Integer chunkSize = listOfRecordsInChunk.size();
        totalProcessed += chunkSize;
        System.debug('Processing chunk of ' + chunkSize + ' records. Total processed: ' + totalProcessed);
        
        //If dryRun is true, do not do DML, but identify what the count would be, then return out of the batch job
        if(dryRun) {
            System.debug('DRY RUN: Would delete ' + chunkSize + ' records');
            totalSuccess += chunkSize;
            return;
        }

        //If not dry run, proceed with delete operation using the all-or-nothing flag provided by the constructor (or default value)
        Database.DeleteResult[] results = Database.delete(listOfRecordsInChunk, allOrNone);
        
        //Read each DeleteResult value and track successes and failures for logging purposes
        for(Integer i = 0; i < results.size(); i++) {
            Database.DeleteResult dr = results[i];

            //Update success/failure counts
            if(dr.isSuccess()) {
                totalSuccess++;
            } else {
                totalFailed++;

                //Capture error details (up to MAX_ERROR_MESSAGES to prevent memory issues) for each failed delete record
                //If have space, add record error message. Otherwise, skip to avoid exceeding limits
                if(errorMessages.size() < MAX_ERROR_MESSAGES) {
                    //Build error message by grabbing the failed RecordId and the provided Salesforce DML error
                    String recordId = listOfRecordsInChunk[i].Id;
                    for(Database.Error err : dr.getErrors()) {
                        String errorMsg = 'Record ' + recordId + ': ' + err.getMessage() + 
                                        ' (Fields: ' + err.getFields() + ')';
                        errorMessages.add(errorMsg);
                        System.debug(LoggingLevel.ERROR, errorMsg);
                    }
                }
            }
        }
        
        //If hardDelete flag is true and we have at least one successfully deleted record in the chunk, 
        //execute a hard delete by emptying the deleted records from the recycle bin
        if(hardDelete && totalSuccess > 0) {
            try {
                Database.emptyRecycleBin(listOfRecordsInChunk);
                System.debug('Hard delete completed for ' + listOfRecordsInChunk.size() + ' records');
            } catch(Exception e) {
                //If hard delete fails, log error but do not fail the entire batch
                String errorMsg = 'Hard delete failed: ' + e.getMessage();
                errorMessages.add(errorMsg);
                System.debug(LoggingLevel.ERROR, errorMsg);
            }
        }
    }
    
    //Finish method - automatically called once after all batches complete
    //Generates summary statistics and optionally sends email notification
    public void finish(Database.BatchableContext BatchContext) {
        //Log the time the batch job finished and calculate total duration
        DateTime endTime = DateTime.now();
        Long durationSeconds = (endTime.getTime() - startTime.getTime()) / 1000;
        
        //Retrieve job information via SOQL
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, 
                   CreatedBy.Email, CreatedBy.Name, ExtendedStatus
            FROM AsyncApexJob 
            WHERE Id = :BatchContext.getJobId()
        ];
        
        //Build summary message
        String summary = buildSummaryMessage(job, durationSeconds);
        System.debug(summary);
        
        //Send email notification if configured
        if(sendEmail) {
            sendCompletionEmail(job, summary);
        }
    }
    
    //HELPER METHODS: Private methods to support main batch functionality\\
    
    //Builds a formatted summary message with job statistics. This message can be logged via Debug, or emailed if desired
    //@param batchJob The AsyncApexJob record for this batch
    //@param durationSeconds Total execution time in seconds
    //@return Formatted summary string
    private String buildSummaryMessage(AsyncApexJob batchJob, Long durationSeconds) {
        //Determine mode string based on dryRun flag
        String mode = dryRun ? 'DRY RUN' : 'DELETE';
        
        //Init empty array of strings to build summary lines
        List<String> summaryLines = new List<String>();
        //Build the summary line by line
        summaryLines.add('========================================');
        summaryLines.add('Batch Mass Delete - ' + mode + ' - COMPLETE');
        summaryLines.add('========================================');
        summaryLines.add('Job ID: ' + batchJob.Id);
        summaryLines.add('Status: ' + batchJob.Status);
        summaryLines.add('Started: ' + startTime.format());
        summaryLines.add('Duration: ' + durationSeconds + ' seconds');
        summaryLines.add('');
        summaryLines.add('RESULTS:');
        summaryLines.add('Total Processed: ' + totalProcessed);
        summaryLines.add('Successful: ' + totalSuccess);
        summaryLines.add('Failed: ' + totalFailed);
        
        //If we have any errors logged, include them here in the summary text
        if(totalFailed > 0) {
            summaryLines.add('');
            summaryLines.add('ERRORS (' + errorMessages.size() + ' shown):');

            //For each error message, add its details to the summary
            for(String error : errorMessages) {
                summaryLines.add('  - ' + error);
            }
        }
        
        summaryLines.add('========================================');
        //Join all lines into a single string separated by new lines and return for usasge to the invoking method
        return String.join(summaryLines, '\n');
    }

    //Uses Salesforce's Apex SingleEmailMessage to send a completion email with job summary built in buildSummaryMessage 
    //helper method.
    //@param batchJob The AsyncApexJob record for this batch
    //@param summaryText Pre-formatted summary message
    private void sendCompletionEmail(AsyncApexJob batchJob, String summaryText) {
        try {
            //Build email message via Messaging class
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            //Determine recipient; will either be the provided in the notificationEmail property, or the running user's email
            String recipient = String.isNotBlank(notificationEmail) ? 
                             notificationEmail : batchJob.CreatedBy.Email;
            mail.setToAddresses(new String[] { recipient });
            
            //Set subject based on if the batch was a dry run and if there were any errors
            String mode = dryRun ? '[DRY RUN] ' : '';
            String status = totalFailed > 0 ? 'COMPLETED WITH ERRORS' : 'COMPLETED SUCCESSFULLY';
            mail.setSubject(mode + 'Batch Mass Delete - ' + status);
            
            //Set body as the summaryText built in the buildSummaryMessage method
            mail.setPlainTextBody(summaryText);

            //Send email using Messaging class
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            System.debug('Completion email sent to: ' + recipient);
            
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to send completion email: ' + e.getMessage());
        }
    }
    
    //CUSTOM EXCEPTION\\
    
    //Custom exception for batch delete validation errors
    public class BatchMassDeleteException extends Exception {}
}