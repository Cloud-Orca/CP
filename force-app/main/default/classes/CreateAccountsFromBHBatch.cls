global class CreateAccountsFromBHBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    global Map<String, Set<String>> collectionIdToRelatedCompanyIdsMap;
    
    global CreateAccountsFromBHBatch(){
        this.collectionIdToRelatedCompanyIdsMap = new Map<String, Set<String>>();
    }

    global CreateAccountsFromBHBatch(Map<String, Set<String>> collectionIdToRelatedCompanyIdsMap){
        this.collectionIdToRelatedCompanyIdsMap = collectionIdToRelatedCompanyIdsMap;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Set<String> bhCollectionIds = collectionIdToRelatedCompanyIdsMap.keySet();
        String query = 'SELECT Id, Name, beauhurst_id__c, collection_name__c';
        query += ' FROM Company_Collection__c';
        if(!collectionIdToRelatedCompanyIdsMap.isEmpty()){
            query += ' WHERE beauhurst_id__c IN: bhCollectionIds';
        }
        System.debug('@@@query: ' + query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Company_Collection__c> scope){
        Company_Collection__c col = scope[0];

        if(collectionIdToRelatedCompanyIdsMap.containsKey(col.beauhurst_id__c)){
            Map<String, Map<String, Object>> companiesHouseIdToResultItemMap = new Map<String, Map<String, Object>>();
            Map<String, Map<String, Object>> companiesHouseIdToTransactionItemMap = new Map<String, Map<String, Object>>();

            Set<String> relatedCompanyIds = collectionIdToRelatedCompanyIdsMap.get(col.beauhurst_id__c);
            Integer setSize = relatedCompanyIds.size();

            String companyIds = '';
            Integer counter = 0;
            Boolean isCall = false;

            for(String companyId : relatedCompanyIds){
                companyIds += 'company_ids=' + companyId + '&';

                counter++;
                if(counter == 100){
                    counter = 0;
                    setSize = setSize - 100;
                    isCall = true;
                }

                if(counter == setSize){
                    isCall = true;
                }

                if(isCall){
                    isCall = false;

                    String append = '/companies?' + companyIds + 'includes=companies_house_id&includes=name&includes=registered_name&includes=other_trading_names&includes=website';
                            append += '&includes=ultimate_parent_company&includes=top_level_industry_groups&includes=top_level_sector_groups&includes=buzzwords&includes=latest_stage_of_evolution';
                            append += '&includes=legal_form&includes=year_end_date&includes=turnover&includes=ebitda&includes=total_assets&includes=number_of_employees&includes=auditor&includes=audit_fees';
                            append += '&includes=emails&includes=directors&includes=total_amount_fundraisings&includes=n_fundraisings&includes=total_amount_grants&includes=latest_valuation';
                            append += '&includes=n_grants&includes=stage_of_evolution_transitions';
                            append += '&limit=100';
                    
                    Http http = new Http();
                    HttpResponse res = http.send(BeauhurstAPIUtility.constructReq(append));

                    System.debug('@@@res code: ' + res.getStatusCode());
                    System.debug('@@@res body: ' + res.getBody());

                    if(res.getStatusCode() == 200){
                        Map<String, Object> resp = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                        List<Object> results = (List<Object>)resp.get('results');
            
                        if(results != null && results.size() > 0){
                            for(Object result : results){
                                Map<String, Object> resultItem = (Map<String, Object>)result;
                                if(resultItem.get('basic') != null){
                                    Map<String, Object> basic = (Map<String, Object>)resultItem.get('basic');
                                    if(basic.get('companies_house_id') != null){
                                        companiesHouseIdToResultItemMap.put(String.valueOf(basic.get('companies_house_id')), resultItem);
                                    }
                                }
                            }
                        }
                    }else{
                        System.abortJob(BC.getJobId());
                    }

                    String transactionAppend = '/transactions/company?' + companyIds + 'includes=fundraisings&limit=100';
                    HttpResponse transactionRes = http.send(BeauhurstAPIUtility.constructReq(transactionAppend));

                    System.debug('@@@transaction status code: ' + transactionRes.getStatusCode());
                    System.debug('@@@transaction body: ' + transactionRes.getBody());

                    if(transactionRes.getStatusCode() == 200){
                        Map<String, Object> tranResp = (Map<String, Object>)JSON.deserializeUntyped(transactionRes.getBody());
                        List<Object> tranResults = (List<Object>)tranResp.get('results');
                        if(tranResults != null && tranResults.size() > 0){
                            for(Object tranResult : tranResults){
                                Map<String, Object> tranResultItem = (Map<String, Object>)tranResult;
                                if(tranResultItem.get('companies_house_id') != null && tranResultItem.get('fundraisings') != null){
                                    companiesHouseIdToTransactionItemMap.put(String.valueOf(tranResultItem.get('companies_house_id')), tranResultItem);
                                }
                            }
                        }
                    }

                    companyIds = '';
                }
            }

            if(!companiesHouseIdToResultItemMap.isEmpty()){
                List<Account> accountsToInsert = new List<Account>();
                Map<String, Id> registeredNumberToAccountIdMap = new Map<String, Id>();
                
                for(Account acc : [SELECT Id, Beauhurst_ID__c FROM Account WHERE Beauhurst_ID__c IN: companiesHouseIdToResultItemMap.keySet()]){
                    registeredNumberToAccountIdMap.put(acc.Beauhurst_ID__c, acc.Id);
                }

                for(String cHouseId : companiesHouseIdToResultItemMap.keySet()){
                    if(!registeredNumberToAccountIdMap.containsKey(cHouseId)){ //not existing in SF
                        List<User> users = [SELECT Id FROM User WHERE Name = 'Sal Mingoia' AND isActive = true LIMIT 1];
                        if(!users.isEmpty()){
                            Account acc = BeauhurstAPIUtility.collectAccount(null, companiesHouseIdToResultItemMap.get(cHouseId));
                            acc.Type = 'Target';
                            acc.BH_Collection_Name__c = col.collection_name__c;
                            acc.RecordTypeId = BeauhurstAPIUtility.getRecordTypeIdbyName('Account', 'Business Account');
                            acc.OwnerId = users[0].Id;

                            if(companiesHouseIdToTransactionItemMap.containsKey(cHouseId)){
                                List<Object> fundraisings_lst = (List<Object>)companiesHouseIdToTransactionItemMap.get(cHouseId).get('fundraisings');
                                Map<String, Object> fundraisings_obj = (Map<String, Object>)fundraisings_lst[0];
                                if(fundraisings_obj.get('date_raised') != null){
                                    acc.Date_Of_Last_Funding_Round__c = BeauhurstAPIUtility.stringToDate(String.valueOf(fundraisings_obj.get('date_raised')));
                                }
                                if(fundraisings_obj.get('amount_raised_gbp') != null){
                                    acc.Amount_in_Latest_Fundraise__c = Double.valueOf(fundraisings_obj.get('amount_raised_gbp'));
                                }
                            }
                            accountsToInsert.add(acc);
                        }
                    }
                }

                System.debug('@@@accountsToInsert: ' + accountsToInsert);
                if(!accountsToInsert.isEmpty()){
                    insert accountsToInsert;
                }
            }
        }
    }

    global void finish(Database.BatchableContext BC){
        
    }

    public class Response{
        public List<Result> results;
    }

    public class Result{
        public String id;
        public Basic basic;
        public Accounts latest_accounts;
    }

    public class Basic{
        public String registered_name;
        public String companies_house_id;
        public String employee_count_range;
    }

    public class Accounts{
        public String turnover;
        public String ebitda;
        public String total_assets;
    }
}