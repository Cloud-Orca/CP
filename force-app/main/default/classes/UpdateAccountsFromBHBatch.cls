global class UpdateAccountsFromBHBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful, Database.AllowsCallouts {
    global Boolean isInitialRun;
    global Set<Id> ids;

    global void execute(SchedulableContext SC) {
        Database.executebatch(new UpdateAccountsFromBHBatch(), 100);
    }
    
    global UpdateAccountsFromBHBatch(){
        this.isInitialRun = false;
        this.ids = new Set<Id>();
    }

    global UpdateAccountsFromBHBatch(Set<Id> ids){
        this.isInitialRun = false;
        this.ids = ids;
    }

    //Database.executeBatch(new UpdateAccountsFromBHBatch(true), 10);
    global UpdateAccountsFromBHBatch(Boolean isInitialRun){
        this.isInitialRun = isInitialRun;
        this.ids = new Set<Id>();
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Name, Beauhurst_ID__c';
        query += ' FROM Account';
        query += ' WHERE Beauhurst_ID__c != null';
        if(isInitialRun){
            query += ' AND Registered_Name__c = null';
        }
        if(!ids.isEmpty()){
            query += ' AND Id IN: ids';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope){
        System.debug('@@@UpdateAccountsFromBHBatch');

        String companyIds = '';
        Map<String, Id> bhIdToAccountIdMap = new Map<String, Id>();
        for(Account acc : scope){
            if(acc.Beauhurst_ID__c.isAlphaNumeric() && acc.Beauhurst_ID__c.length() >= 6 && acc.Beauhurst_ID__c.length() <= 8){
                bhIdToAccountIdMap.put(acc.Beauhurst_ID__c, acc.Id);
                companyIds += 'company_ids=' + acc.Beauhurst_ID__c + '&';
            }
        }

        if(!String.isEmpty(companyIds)){
            Map<Id, Account> accountsToUpdateMap = new Map<Id, Account>();
            String append = '/companies?' + companyIds + 'includes=companies_house_id&includes=registered_name&includes=other_trading_names&includes=website';
                    append += '&includes=ultimate_parent_company&includes=top_level_industry_groups&includes=top_level_sector_groups&includes=buzzwords&includes=latest_stage_of_evolution';
                    append += '&includes=legal_form&includes=year_end_date&includes=turnover&includes=ebitda&includes=total_assets&includes=number_of_employees&includes=auditor&includes=audit_fees';
                    append += '&includes=emails&includes=directors&includes=total_amount_fundraisings&includes=n_fundraisings&includes=total_amount_grants&includes=latest_valuation';
                    append += '&includes=n_grants&includes=stage_of_evolution_transitions';
                    append += '&limit=100';
            
            Http http = new Http();
            HttpResponse res = http.send(BeauhurstAPIUtility.constructReq(append));

            System.debug('@@@company status code: ' + res.getStatusCode());
            System.debug('@@@company body: ' + res.getBody());

            if(res.getStatusCode() == 200){
                Map<String, Object> resp = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                List<Object> results = (List<Object>)resp.get('results');
                if(results != null && results.size() > 0){
                    for(Object result : results){
                        Map<String, Object> resultItem = (Map<String, Object>)result;
                        if(resultItem.get('basic') != null){
                            Map<String, Object> basic = (Map<String, Object>)resultItem.get('basic');
                            if(basic.get('companies_house_id') != null){
                                String resultId = String.valueOf(basic.get('companies_house_id'));
                                if(bhIdToAccountIdMap.containsKey(resultId)){
                                    Id accId = bhIdToAccountIdMap.get(resultId);
                                    accountsToUpdateMap.put(accId, BeauhurstAPIUtility.collectAccount(accId, resultItem));
                                }
                            }
                        }
                    }
                }
            }else{
                if(isInitialRun){
                    System.abortJob(BC.getJobId());
                }
            }

            String transactionAppend = '/transactions/company?' + companyIds + 'includes=fundraisings&limit=100';
            HttpResponse transactionRes = http.send(BeauhurstAPIUtility.constructReq(transactionAppend));

            System.debug('@@@transaction status code: ' + transactionRes.getStatusCode());
            System.debug('@@@transaction body: ' + transactionRes.getBody());

            if(transactionRes.getStatusCode() == 200){
                Map<String, Object> resp = (Map<String, Object>)JSON.deserializeUntyped(transactionRes.getBody());
                List<Object> results = (List<Object>)resp.get('results');
                if(results != null && results.size() > 0){
                    for(Object result : results){
                        Map<String, Object> resultItem = (Map<String, Object>)result;
                        if(resultItem.get('companies_house_id') != null && resultItem.get('fundraisings') != null){
                            String resultId = String.valueOf(resultItem.get('companies_house_id'));
                            if(bhIdToAccountIdMap.containsKey(resultId)){
                                Id accId = bhIdToAccountIdMap.get(resultId);

                                List<Object> fundraisings_lst = (List<Object>)resultItem.get('fundraisings');
                                if(!fundraisings_lst.isEmpty()){
                                    Map<String, Object> fundraisings_obj = (Map<String, Object>)fundraisings_lst[0];

                                    Account acc = new Account(Id=accId);
                                    if(accountsToUpdateMap.containsKey(accId)){
                                        acc = accountsToUpdateMap.get(accId);   
                                    }
                                    if(fundraisings_obj.get('date_raised') != null){
                                        acc.Date_Of_Last_Funding_Round__c = BeauhurstAPIUtility.stringToDate(String.valueOf(fundraisings_obj.get('date_raised')));
                                    }
                                    if(fundraisings_obj.get('amount_raised_gbp') != null){
                                        acc.Amount_in_Latest_Fundraise__c = Double.valueOf(fundraisings_obj.get('amount_raised_gbp'));
                                    }
                                    accountsToUpdateMap.put(accId, acc);
                                }
                            }
                        }
                    }
                }
            }

            if(!accountsToUpdateMap.isEmpty()){
                update accountsToUpdateMap.values();
            }
        }
    }

    global void finish(Database.BatchableContext BC){
        
    }
}