global class GetCompanyIdBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful, Database.AllowsCallouts {
    global Set<Id> collectionIds;
    global Map<String, Set<String>> collectionIdToRelatedCompanyIdsMap;

    global void execute(SchedulableContext SC) {
        Database.executebatch(new GetCompanyIdBatch(), 1);
    }

    //Database.executeBatch(new GetCompanyIdBatch(), 1);
    global GetCompanyIdBatch(){
        this.collectionIds = new Set<Id>();
        this.collectionIdToRelatedCompanyIdsMap = new Map<String, Set<String>>();
    }

    global GetCompanyIdBatch(Set<Id> collectionIds){
        this.collectionIds = collectionIds;
        this.collectionIdToRelatedCompanyIdsMap = new Map<String, Set<String>>();
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Name, beauhurst_id__c, collection_name__c';
        query += ' FROM Company_Collection__c';
        query += ' WHERE beauhurst_id__c != null';
        query += ' AND sync__c = true';
        if(!collectionIds.isEmpty()){
            query += ' AND Id IN: collectionIds';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Company_Collection__c> scope){
        Set<String> retrievedCompanyIds = new Set<String>();
        Integer offsetVal = 0;
        Integer limitVal = 100;
        Boolean isLoop = true;

        while(isLoop){
            String append = '/companies/search?collection_id=' + scope[0].beauhurst_id__c + '&limit=' + limitVal + '&offset=' + offsetVal;

            Http http = new Http();
            HttpResponse res = http.send(BeauhurstAPIUtility.constructReq(append));
            if(res.getStatusCode() == 200){
                Response getData = (Response) JSON.deserialize(res.getBody(), Response.class);
                if(!getData.results.isEmpty()){
                    offsetVal += 100;
                    for(Result result : getData.results){
                        if(result.id.isAlphaNumeric() && result.id.length() >= 6 && result.id.length() <= 8){
                            retrievedCompanyIds.add(result.id);
                        }
                    }
                }else{
                    isLoop = false;
                }
            }else{
                isLoop = false;
                System.abortJob(BC.getJobId());
            }
        }
        collectionIdToRelatedCompanyIdsMap.put(scope[0].beauhurst_id__c, retrievedCompanyIds);
    }

    global void finish(Database.BatchableContext BC){
        if(!Test.isRunningTest() && !collectionIdToRelatedCompanyIdsMap.isEmpty()){
            Database.executeBatch(new CreateAccountsFromBHBatch(collectionIdToRelatedCompanyIdsMap), 1);
        }
    }

    public class Response{
        public List<Result> results;
    }

    public class Result{
        public String id;
    }
}