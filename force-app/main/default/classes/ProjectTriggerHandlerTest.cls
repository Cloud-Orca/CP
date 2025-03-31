@isTest(SeeAllData = true)
public with sharing class ProjectTriggerHandlerTest {
    
    @isTest static void testMethodAddSharingToPartnerExpense(){
        Id projectId = [SELECT Id, pse__Project__c FROM pse__Expense__c WHERE pse__Project__c != null LIMIT 1].pse__Project__c;

        pse__Proj__c proj = new pse__Proj__c(Id = projectId);
        proj.CT_Project_Partner__c = UserInfo.getUserId();
        update proj;
        // Set<Id> projectIds = new Set<Id>{projectId};
        // test.startTest();
        // Database.executeBatch(new BatchAddSharingToPartner(projectIds), 1);
        // test.stopTest();
    }

    @isTest static void testMethodAddSharingToPartnerMiscAdjustment(){
        Id projectId = [SELECT Id, pse__Project__c FROM pse__Miscellaneous_Adjustment__c WHERE pse__Project__c != null LIMIT 1].pse__Project__c;

        pse__Proj__c proj = new pse__Proj__c(Id = projectId);
        proj.CT_Project_Partner__c = UserInfo.getUserId();
        update proj;
        // Set<Id> projectIds = new Set<Id>{projectId};
        // test.startTest();
        // Database.executeBatch(new BatchAddSharingToPartner(projectIds), 1);
        // test.stopTest();
    }

    @isTest static void testMethodAddSharingToPartnerTimeCard(){
        Id projectId = [SELECT Id, pse__Project__c FROM pse__Timecard_Header__c WHERE pse__Project__c != null LIMIT 1].pse__Project__c;

        pse__Proj__c proj = new pse__Proj__c(Id = projectId);
        proj.CT_Project_Partner__c = UserInfo.getUserId();
        update proj;
        // Set<Id> projectIds = new Set<Id>{projectId};
        // test.startTest();
        // Database.executeBatch(new BatchAddSharingToPartner(projectIds), 1);
        // test.stopTest();
    }
}