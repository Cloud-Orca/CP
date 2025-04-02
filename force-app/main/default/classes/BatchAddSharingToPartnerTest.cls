@isTest(SeeAllData = true)
public class BatchAddSharingToPartnerTest {

    @isTest static void testMethodAddSharingToPartnerExpense(){
        Id projectId = [SELECT Id, pse__Project__c FROM pse__Expense__c WHERE pse__Project__c != null LIMIT 1].pse__Project__c;
        Set<Id> projectIds = new Set<Id>{projectId};
        test.startTest();
        Database.executeBatch(new BatchAddSharingToPartner(projectIds), 1);
        test.stopTest();
    }

    @isTest static void testMethodAddSharingToPartnerMiscAdjustment(){
        Id projectId = [SELECT Id, pse__Project__c FROM pse__Miscellaneous_Adjustment__c WHERE pse__Project__c != null LIMIT 1].pse__Project__c;
        Set<Id> projectIds = new Set<Id>{projectId};
        test.startTest();
        Database.executeBatch(new BatchAddSharingToPartner(projectIds), 1);
        test.stopTest();
    }

    @isTest static void testMethodAddSharingToPartnerTimeCard(){
        Id projectId = [SELECT Id, pse__Project__c FROM pse__Timecard_Header__c WHERE pse__Project__c != null LIMIT 1].pse__Project__c;
        Set<Id> projectIds = new Set<Id>{projectId};
        test.startTest();
        Database.executeBatch(new BatchAddSharingToPartner(projectIds), 1);
        test.stopTest();
    }
}