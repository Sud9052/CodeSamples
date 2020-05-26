global class UpdateLeads implements 
    Database.Batchable<sObject>, Database.Stateful {
    
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'select Name,Temp__c from Lead'
        );
    }
    global void execute(Database.BatchableContext bc, List<Account> scope){
        // process each batch of records
        List <Lead> UpdateLeadList = new List<Lead>();
        for (Lead l : scope) {
            l.Temp__c = true;
            UpdateLeadList.add(l);
            recordsProcessed = recordsProcessed + 1;
        }
        update UpdateLeadList;
    }    
    global void finish(Database.BatchableContext bc){
        System.debug(recordsProcessed + ' records processed. Shazam!');
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()];
        // call some utility to send email
        EmailUtils.sendMessage(job, recordsProcessed);
    }    
}

MyBatchClass myBatchObject = new UpdateLeads(); 
Id batchId = Database.executeBatch(myBatchObject);
