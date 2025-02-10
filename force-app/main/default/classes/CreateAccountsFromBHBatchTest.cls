@isTest
private class CreateAccountsFromBHBatchTest {
    @IsTest
    static void createAccountFromBHBatch(){
        Company_Collection__c col = new Company_Collection__c();
        col.beauhurst_id__c = 'kafjwd';
        col.collection_name__c = 'Sample Collection';
        col.count__c = 34;
        col.sync__c = true;
        insert col;

        QueueHttpMock mock = new QueueHttpMock();

        HttpResponse getComp = new HttpResponse();
        getComp.setStatusCode(200);
        getComp.setBody('{"meta":{"total":1,"limit":20,"offset":0,"count":1},"results":[{"id":"b7vpnx","basic":{"registered_name":"Amo Pharma Limited","other_trading_names":[],"companies_house_id":"09431909","website":"http://www.amo-pharma.com/","ultimate_parent_company":{"name":"","companies_house_id":"","country":""}},"classification":{"top_level_sector_groups":["Technology/IP-based businesses"],"top_level_industry_groups":["Life sciences and medical technology"],"buzzwords":["Genomics"],"latest_stage_of_evolution":"Venture","stage_of_evolution_transitions":[{"primary_date":"2015-10-01","stage_before":null,"stage_after":"venture"}],"legal_form":"Private limited with Share Capital"},"transactions":{"n_fundraisings":4,"total_amount_fundraisings":62825248,"n_grants":0,"total_amount_grants":0,"latest_valuation":90571703},"contact_information":{"emails":["info@amo-pharma.com"]},"latest_accounts":{"year_end_date":"2023-12-31","turnover":null,"ebitda":null,"total_assets":4933000,"number_of_employees":7,"auditor":"ARCHANGEL ACCOUNTING","audit_fees":0},"historic_accounts":[{"year_end_date":"2023-12-31","turnover":null,"ebitda":null,"total_assets":4933000,"number_of_employees":7,"auditor":"ARCHANGEL ACCOUNTING","audit_fees":0},{"year_end_date":"2022-12-31","turnover":null,"ebitda":null,"total_assets":7280000,"number_of_employees":7,"auditor":"ARCHANGEL ACCOUNTING","audit_fees":0},{"year_end_date":"2021-12-31","turnover":0,"ebitda":-8696000,"total_assets":4658000,"number_of_employees":10,"auditor":"DELOITTE","audit_fees":45000},{"year_end_date":"2020-12-31","turnover":0,"ebitda":-5566000,"total_assets":8898000,"number_of_employees":9,"auditor":"DELOITTE","audit_fees":35000},{"year_end_date":"2019-12-31","turnover":0,"ebitda":-3168000,"total_assets":2149000,"number_of_employees":7,"auditor":"DELOITTE","audit_fees":33000}],"directors":[{"people_id":"nmfbfy","name":"Alan Rubino","email":"alan.rubino@amo-pharma.com","from_date":"2021-08-16","until_date":null,"currently_active":true},{"people_id":"6mvmh9","name":"Martin McNulty","email":null,"from_date":"2024-05-08","until_date":null,"currently_active":true},{"people_id":"vg5mmy","name":"Michael Snape","email":null,"from_date":"2015-02-10","until_date":null,"currently_active":true},{"people_id":"x7jzer","name":"Julia Jones","email":null,"from_date":"2021-09-23","until_date":null,"currently_active":true},{"people_id":"ahpspp","name":"John Bateson","email":null,"from_date":"2024-05-08","until_date":null,"currently_active":true},{"people_id":"ws8gsd","name":"Lisa Wittmer","email":null,"from_date":"2015-12-21","until_date":"2016-11-30","currently_active":false},{"people_id":"h4hv7e","name":"Joseph Horrigan","email":"joseph.horrigan@amo-pharma.com","from_date":"2015-12-21","until_date":null,"currently_active":true},{"people_id":"thegps","name":"Martyn Williams","email":null,"from_date":"2015-06-08","until_date":"2021-08-12","currently_active":false},{"people_id":"q8nskn","name":"Saiyed Mahmood","email":null,"from_date":"2015-06-26","until_date":"2024-05-02","currently_active":false}]}]}');
        mock.addResponse(getComp);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            Database.executeBatch(new CreateAccountsFromBHBatch(), 1);
        Test.stopTest();
    }

    @IsTest
    static void createAccountFromBHBatchIDParam(){
        Company_Collection__c col = new Company_Collection__c();
        col.beauhurst_id__c = 'kafjwd';
        col.collection_name__c = 'Sample Collection';
        col.count__c = 34;
        col.sync__c = true;
        insert col;

        QueueHttpMock mock = new QueueHttpMock();

        HttpResponse getComp = new HttpResponse();
        getComp.setStatusCode(200);
        getComp.setBody('{"meta":{"total":1,"limit":20,"offset":0,"count":1},"results":[{"id":"4mzwas","basic":{"registered_name":"Proampac London Limited","companies_house_id": "123456","other_trading_names":[],"website":"https://www.rapuk.com/","ultimate_parent_company":{"name":"Ampac Holding LLC","companies_house_id":""}},"classification":{"top_level_sector_groups":["Industrials","Technology/IP-based businesses"],"top_level_industry_groups":["Supply chain, manufacturing and commerce models"],"buzzwords":[],"latest_stage_of_evolution":"Exited","legal_form":"Private limited with Share Capital"},"contact_information":{"emails":["info@rapuk.com"]},"latest_accounts":{"year_end_date":"2023-12-31","turnover":53030000,"ebitda":7962000,"total_assets":40839000,"number_of_employees":296,"auditor":"MOORE & CO","audit_fees":30000},"historic_accounts":[{"year_end_date":"2023-12-31","turnover":53030000,"ebitda":7962000,"total_assets":40839000,"number_of_employees":296,"auditor":"MOORE & CO","audit_fees":30000},{"year_end_date":"2022-12-31","turnover":46039000,"ebitda":6870000,"total_assets":37110000,"number_of_employees":295,"auditor":"MOORE & CO","audit_fees":45000},{"year_end_date":"2021-12-31","turnover":33384000,"ebitda":4041000,"total_assets":27699000,"number_of_employees":253,"auditor":"MOORE & CO","audit_fees":35000},{"year_end_date":"2020-09-30","turnover":26839000,"ebitda":2163000,"total_assets":21772000,"number_of_employees":254,"auditor":"BDO","audit_fees":46000},{"year_end_date":"2019-09-30","turnover":35227000,"ebitda":2952000,"total_assets":23641000,"number_of_employees":295,"auditor":"BDO","audit_fees":28000}],"directors":[{"people_id":"2jq6qe","name":"Lord Beaver","email":null,"from_date":"2006-06-20","until_date":"2021-01-09","currently_active":false},{"people_id":"bcyfsx","name":"Graham Williams","email":null,"from_date":"1996-04-23","until_date":"2021-01-09","currently_active":false},{"people_id":"dyn8h8","name":"Eric Bradford","email":null,"from_date":"2021-01-09","until_date":null,"currently_active":true},{"people_id":"6k5jb5","name":"Simon Flamank","email":null,"from_date":"1998-04-30","until_date":"2000-03-31","currently_active":false},{"people_id":"pnwr3i","name":"Ekaterina Sharashidze Voskamp","email":null,"from_date":"2015-09-01","until_date":"2021-01-09","currently_active":false},{"people_id":"g9gixb","name":"Gijs-Jan Voskamp","email":null,"from_date":"2014-03-01","until_date":"2021-01-09","currently_active":false},{"people_id":"fhtti7","name":"John McKimmie","email":null,"from_date":"2000-03-29","until_date":"2021-01-09","currently_active":false},{"people_id":"2vbmsn","name":"Tony Prior","email":null,"from_date":"1996-04-23","until_date":"1997-04-18","currently_active":false},{"people_id":"873853","name":"Andrew Drummond","email":null,"from_date":"2008-01-02","until_date":"2021-01-09","currently_active":false},{"people_id":"7khdn9","name":"John Curtis","email":null,"from_date":"2011-06-13","until_date":"2015-08-31","currently_active":false},{"people_id":"fhwsth","name":"David Venus","email":null,"from_date":"1996-04-22","until_date":"1996-04-23","currently_active":false},{"people_id":"wkinpe","name":"Gregory Tucker","email":null,"from_date":"2021-01-09","until_date":null,"currently_active":true},{"people_id":"jmdnq2","name":"Nicholas Pople","email":null,"from_date":"2008-05-22","until_date":"2014-02-28","currently_active":false},{"people_id":"d4yxr9","name":"Sean O\'Brien","email":null,"from_date":"1997-04-17","until_date":"1997-06-30","currently_active":false},{"people_id":"iv787e","name":"Julian Money","email":null,"from_date":"1997-04-18","until_date":"2021-01-09","currently_active":false},{"people_id":"pqx2vk","name":"Katherine Pethick","email":null,"from_date":"1997-04-18","until_date":"2021-01-09","currently_active":false}]}]}');
        mock.addResponse(getComp);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            Map<String, Set<String>> collectionIdToRelatedCompanyIdsMap = new Map<String, Set<String>>();
            collectionIdToRelatedCompanyIdsMap.put('kafjwd', new Set<String>{'12322'});
            Database.executeBatch(new CreateAccountsFromBHBatch(collectionIdToRelatedCompanyIdsMap), 1);
        Test.stopTest();
    }
}