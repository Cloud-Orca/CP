public class BeauhurstAPIUtility {
    public static HttpRequest constructReq(String append){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:BeauhurstAPI' + append);
        req.setMethod('GET');
        req.setTimeOut(120000);
        return req;
    }

    @AuraEnabled
    public static UIWrapper updateFromBH(Id accId){
        UIWrapper wrap = new UIWrapper();
        wrap.success = false;
        wrap.errorMsg = '';
        try{
            List<Account> accounts = [SELECT Id, Beauhurst_ID__c FROM Account WHERE Id =: accId LIMIT 1];
            if(!accounts.isEmpty()){
                Account acc = accounts[0];
                if(acc.Beauhurst_ID__c.isAlphaNumeric() && acc.Beauhurst_ID__c.length() >= 6 && acc.Beauhurst_ID__c.length() <= 8){
                    String append = '/companies?company_ids=' + accounts[0].Beauhurst_ID__c + '&includes=registered_name&includes=other_trading_names&includes=website';
                    append += '&includes=ultimate_parent_company&includes=top_level_industry_groups&includes=top_level_sector_groups&includes=buzzwords&includes=latest_stage_of_evolution';
                    append += '&includes=legal_form&includes=year_end_date&includes=turnover&includes=ebitda&includes=total_assets&includes=number_of_employees&includes=auditor&includes=audit_fees';
                    append += '&includes=emails&includes=directors&includes=total_amount_fundraisings&includes=n_fundraisings&includes=total_amount_grants&includes=latest_valuation';
                    append += '&includes=n_grants&includes=stage_of_evolution_transitions';
                    append += '&limit=100';
                                    
                    Http http = new Http();
                    HttpResponse res = http.send(constructReq(append));
    
                    System.debug('@@@res status code: ' + res.getStatusCode());
                    System.debug('@@@res body: ' + res.getBody());
    
                    if(res.getStatusCode() == 200){
                        wrap.success = true;
                        
                        Map<String, Object> resp = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                        List<Object> results = (List<Object>)resp.get('results');
                        if(results != null && results.size() > 0){
                            Map<String, Object> resultItem = (Map<String, Object>)results[0];
                            
                            Account rec = collectAccount(accounts[0].Id, resultItem);

                            String transactionAppend = '/transactions/company?company_ids=' + accounts[0].Beauhurst_ID__c + '&includes=fundraisings&limit=100';
                            HttpResponse transactionRes = http.send(BeauhurstAPIUtility.constructReq(transactionAppend));

                            System.debug('@@@transaction status code: ' + transactionRes.getStatusCode());
                            System.debug('@@@transaction body: ' + transactionRes.getBody());

                            if(transactionRes.getStatusCode() == 200){
                                Map<String, Object> tranResp = (Map<String, Object>)JSON.deserializeUntyped(transactionRes.getBody());
                                List<Object> tranResults = (List<Object>)tranResp.get('results');
                                if(tranResults != null && tranResults.size() > 0){
                                    Map<String, Object> tranResultItem = (Map<String, Object>)tranResults[0];
                                    if(tranResultItem.get('companies_house_id') != null && tranResultItem.get('fundraisings') != null){
                                        List<Object> fundraisings_lst = (List<Object>)tranResultItem.get('fundraisings');
                                        Map<String, Object> fundraisings_obj = (Map<String, Object>)fundraisings_lst[0];

                                        if(fundraisings_obj.get('date_raised') != null){
                                            rec.Date_Of_Last_Funding_Round__c = stringToDate(String.valueOf(fundraisings_obj.get('date_raised')));
                                        }
                                        if(fundraisings_obj.get('amount_raised_gbp') != null){
                                            rec.Amount_in_Latest_Fundraise__c = Double.valueOf(fundraisings_obj.get('amount_raised_gbp'));
                                        }
                                    }
                                }
                            }

                            update rec;
                        }
                    }else{
                        wrap.errorMsg = 'API Error';
                    }
                }else{
                    wrap.errorMsg = 'Registered Number should be AlphaNumberic and should not exceed 8 characters.';
                }
            }
        }catch(Exception e) {
            wrap.success = false;
            wrap.errorMsg = e.getMessage() + ' line ' + e.getLineNumber();
        }
        return wrap;
    }
    
    public static Account collectAccount(Id accId, Map<String, Object> resultItem){
        Account acc = new Account();
        if(accId != null){
            acc.Id = accId;
        }

        acc.Beauhurst_Updated_Date__c = System.now();
        if(resultItem.get('basic') != null){
            Map<String, Object> basic = (Map<String, Object>)resultItem.get('basic');
            if(basic.get('registered_name') != null){
                acc.Registered_Name__c = String.valueOf(basic.get('registered_name'));
            }
            if(accId == null){
                if(basic.get('companies_house_id') != null){
                    String registered_num = String.valueOf(basic.get('companies_house_id'));
                    acc.Beauhurst_ID__c = registered_num;
                    acc.Name = acc.Registered_Name__c;
                }
            }
            if(basic.get('other_trading_names') != null){
                List<Object> other_trading_names_obj = (List<Object>)basic.get('other_trading_names'); 
                if(!other_trading_names_obj.isEmpty()){
                    List<String> other_trading_names = String.join(other_trading_names_obj,';').split(';');
                    acc.Other_Trading_Names__c = listToString(other_trading_names);
                }
            }
            if(basic.get('website') != null){
                acc.Website = String.valueOf(basic.get('website')).left(255);
            }
            if(basic.get('ultimate_parent_company') != null){
                Map<String, Object> parent = (Map<String, Object>)basic.get('ultimate_parent_company');
                if(parent.get('companies_house_id') != null){
                    acc.Parent_Company_Companies_House_Id__c = String.valueOf(parent.get('companies_house_id'));
                }
                if(parent.get('name') != null){
                    acc.Ultimate_Parent_Company_Name__c = String.valueOf(parent.get('name'));
                }
            }
        }
        
        if(resultItem.get('classification') != null){
            Map<String, Object> classification = (Map<String, Object>)resultItem.get('classification');
            
            if(classification.get('top_level_industry_groups') != null){
                List<Object> top_level_industry_groups_obj = (List<Object>)classification.get('top_level_industry_groups'); 
                if(!top_level_industry_groups_obj.isEmpty()){
                    List<String> top_level_industry_groups = String.join(top_level_industry_groups_obj,';').split(';');
                    acc.Top_Level_Industry_Groups__c = listToString(top_level_industry_groups);
                }
            }
            if(classification.get('top_level_sector_groups') != null){
                List<Object> top_level_sector_groups_obj = (List<Object>)classification.get('top_level_sector_groups'); 
                if(!top_level_sector_groups_obj.isEmpty()){
                    List<String> top_level_sector_groups = String.join(top_level_sector_groups_obj,';').split(';');
                    acc.Top_Level_Sector_Groups__c = listToString(top_level_sector_groups);
                }
            }
            if(classification.get('buzzwords') != null){
                List<Object> buzzwords_obj = (List<Object>)classification.get('buzzwords'); 
                if(!buzzwords_obj.isEmpty()){
                    List<String> buzzwords = String.join(buzzwords_obj,';').split(';');
                    acc.Buzzwords__c = listToString(buzzwords);
                }
            }
            if(classification.get('latest_stage_of_evolution') != null){
                acc.Latest_Stage_Of_Evolution__c = String.valueOf(classification.get('latest_stage_of_evolution'));
            }
            if(classification.get('stage_of_evolution_transitions') != null){
                List<Object> stage_of_evolution_lst = (List<Object>)classification.get('stage_of_evolution_transitions');
                acc.Stage_of_Evolution_Transitions__c = JSON.serialize(stage_of_evolution_lst);

                Map<String, Object> stage_of_evolution_obj = (Map<String, Object>)stage_of_evolution_lst[0];
                if(stage_of_evolution_obj.get('primary_date') != null){
                    acc.Primary_Date__c = stringToDate(String.valueOf(stage_of_evolution_obj.get('primary_date')));
                }
                if(stage_of_evolution_obj.get('stage_before') != null){
                    acc.Stage_Before__c = String.valueOf(stage_of_evolution_obj.get('stage_before'));
                }
                if(stage_of_evolution_obj.get('stage_after') != null){
                    acc.Stage_After__c = String.valueOf(stage_of_evolution_obj.get('stage_after'));
                }
            }
            if(classification.get('legal_form') != null){
                acc.Legal_Form__c = String.valueOf(classification.get('legal_form'));
            }
        }

        if(resultItem.get('transactions') != null){
            Map<String, Object> transactions = (Map<String, Object>)resultItem.get('transactions');

            if(transactions.get('n_fundraisings') != null){
                acc.Number_of_Fundraisings__c = Integer.valueOf(transactions.get('n_fundraisings'));
            }
            if(transactions.get('total_amount_fundraisings') != null){
                acc.Total_Amount_of_Fundraisings__c = Double.valueOf(transactions.get('total_amount_fundraisings'));
                acc.Total_Amount_Raised__c = Double.valueOf(transactions.get('total_amount_fundraisings'));
            }
            if(transactions.get('n_grants') != null){
                acc.Number_of_Grants__c = Integer.valueOf(transactions.get('n_grants'));
            }
            if(transactions.get('total_amount_grants') != null){
                acc.Total_Amount_of_Grants__c = Double.valueOf(transactions.get('total_amount_grants'));
            }
            if(transactions.get('latest_valuation') != null){
                acc.Latest_Valuation__c = Double.valueOf(transactions.get('latest_valuation'));
            }
        }
        
        if(resultItem.get('latest_accounts') != null){
			Map<String, Object> latest = (Map<String, Object>)resultItem.get('latest_accounts');       
            
            if(latest.get('year_end_date') != null){
                acc.Year_End_Date__c = stringToDate(String.valueOf(latest.get('year_end_date')));
            }
            if(latest.get('turnover') != null){
                acc.Turnover__c = Decimal.valueOf(String.valueOf(latest.get('turnover')));
            }
            if(latest.get('ebitda') != null){
                acc.EBITDA__c = Decimal.valueOf(String.valueOf(latest.get('ebitda')));
            }
            if(latest.get('total_assets') != null){
                acc.Total_Assets__c = Decimal.valueOf(String.valueOf(latest.get('total_assets')));
            }
            if(latest.get('number_of_employees') != null){
                acc.NumberOfEmployees = Integer.valueOf(latest.get('number_of_employees'));
            }
            if(latest.get('auditor') != null){
                acc.Auditor__c = String.valueOf(latest.get('auditor'));
            }
            if(latest.get('audit_fees') != null){
                acc.Audit_Fees__c = String.valueOf(latest.get('audit_fees'));
            }
            System.debug('@@@acc: ' + acc);
        }
        return acc;
    }

    public static String listToString(List<String> strList){
        String strVal = String.join(strList, ',');
        return (strVal.length() > 255) ? strVal.left(255) : strVal;
    }
    
    public static Date stringToDate(String strDate){
        List<String> strDates = strDate.split('-');
        return Date.newInstance(Integer.valueOf(strDates[0]), Integer.valueOf(strDates[1]), Integer.valueOf(strDates[2]));
    }

    public static Id getRecordTypeIdbyName(String objectName, String strRecordTypeName){
        return  Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosByName().get(strRecordTypeName).getRecordTypeId();
    }

    /*public class Response{
        public List<Result> results;
    }

    public class Result{
        public String id;
        public Basic basic;
        public Classification classification;
        public ContactInfo contact_information;
        public Accounts latest_accounts;
        public List<Director> directors;
    }

    public class Basic{
        public String name;
        public String registered_name;
        public List<String> other_trading_names;
        public String website;
        public ParentCompany ultimate_parent_company;
    }

    public class ParentCompany{
        public String name;
        public String companies_house_id;
    }

    public class Classification{
        public List<String> top_level_sector_groups;
        public List<String> top_level_industry_groups;
        public List<String> buzzwords;
        public String latest_stage_of_evolution;
        public String legal_form;
    }

    public class ContactInfo{
        public List<String> emails;
    }

    public class Accounts{
        public String year_end_date;
        public String turnover;
        public String ebitda;
        public String total_assets;
        public Integer number_of_employees;
        public String auditor;
        public Integer audit_fees;
    }
    
    public class Director{
        public String people_id;
        public String name;
        public String email;
        public String from_date;
        public String until_date;
        public Boolean currently_active;
    }*/

    public class UIWrapper{
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public String errorMsg;
    }
}