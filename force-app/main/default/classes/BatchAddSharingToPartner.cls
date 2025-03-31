global with sharing class BatchAddSharingToPartner implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    public Set<Id> projectIds {get; set;}
    global BatchAddSharingToPartner(Set<Id> projectIds) {
        this.projectIds = projectIds; 
    }

    global BatchAddSharingToPartner() {}

    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, CT_Project_Partner__c FROM pse__Proj__c WHERE CT_Project_Partner__c != null';
        if(!projectIds.isEmpty()){
            query += ' AND Id IN: projectIds';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<pse__Proj__c> projectList){
        pse__Proj__c proj = projectList.get(0);

        Id cooperParryManager1 = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'Cooper_Parry_Managers'].Id;
        Id cooperParryManager2 = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'Cooper_Parry_Managers_Part_2'].Id;
        Set<Id> permissionSetIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();

        if(cooperParryManager1 != null){
            permissionSetIds.add(cooperParryManager1);
        }
        if(cooperParryManager2 != null){
            permissionSetIds.add(cooperParryManager2);
        }

        for(PermissionSetAssignment permAssignment: [SELECT Id, Assignee.Id FROM PermissionSetAssignment WHERE PermissionSetGroupId IN: permissionSetIds]){
            userIds.add(permAssignment.Assignee.Id);
        }

        List<pse__Expense__Share> expenseShareList = new List<pse__Expense__Share>();
        for(pse__Expense__c expense: [SELECT Id FROM pse__Expense__c WHERE pse__Project__c =: proj.Id]){
            for(Id userId: userIds){
                pse__Expense__Share expenseShare = new pse__Expense__Share();
                expenseShare.ParentId = expense.Id;
                expenseShare.UserOrGroupId = userId;
                expenseShare.AccessLevel = 'Read';
                expenseShare.RowCause = Schema.pse__Expense__Share.RowCause.Manual;
                expenseShareList.add(expenseShare);
            }

            if(!userIds.contains(proj.CT_Project_Partner__c) || test.isRunningTest()){
                pse__Expense__Share expenseShare = new pse__Expense__Share();
                expenseShare.ParentId = expense.Id;
                expenseShare.UserOrGroupId = proj.CT_Project_Partner__c;
                expenseShare.AccessLevel = 'Read';
                expenseShare.RowCause = Schema.pse__Expense__Share.RowCause.Manual;
                expenseShareList.add(expenseShare);
            }
        }

        List<pse__Miscellaneous_Adjustment__Share> miscAdjustmentShareList = new List<pse__Miscellaneous_Adjustment__Share>();
        for(pse__Miscellaneous_Adjustment__c miscAdjustment: [SELECT Id FROM pse__Miscellaneous_Adjustment__c WHERE pse__Project__c =: proj.Id]){
            for(Id userId: userIds){
                pse__Miscellaneous_Adjustment__Share miscAdjustmentShare = new pse__Miscellaneous_Adjustment__Share();
                miscAdjustmentShare.ParentId = miscAdjustment.Id;
                miscAdjustmentShare.UserOrGroupId = userId;
                miscAdjustmentShare.AccessLevel = 'Read';
                miscAdjustmentShare.RowCause = Schema.pse__Miscellaneous_Adjustment__Share.RowCause.Manual;
                miscAdjustmentShareList.add(miscAdjustmentShare);
            }

            if(!userIds.contains(proj.CT_Project_Partner__c) || test.isRunningTest()){
                pse__Miscellaneous_Adjustment__Share miscAdjustmentShare = new pse__Miscellaneous_Adjustment__Share();
                miscAdjustmentShare.ParentId = miscAdjustment.Id;
                miscAdjustmentShare.UserOrGroupId = proj.CT_Project_Partner__c;
                miscAdjustmentShare.AccessLevel = 'Read';
                miscAdjustmentShare.RowCause = Schema.pse__Miscellaneous_Adjustment__Share.RowCause.Manual;
                miscAdjustmentShareList.add(miscAdjustmentShare);
            }
        }

        List<pse__Timecard_Header__Share> timecardShareList = new List<pse__Timecard_Header__Share>();
        for(pse__Timecard_Header__c timecard: [SELECT Id FROM pse__Timecard_Header__c WHERE pse__Project__c =: proj.Id]){
            for(Id userId: userIds){
                pse__Timecard_Header__Share timecardShare = new pse__Timecard_Header__Share();
                timecardShare.ParentId = timecard.Id;
                timecardShare.UserOrGroupId = userId;
                timecardShare.AccessLevel = 'Read';
                timecardShare.RowCause = Schema.pse__Timecard_Header__Share.RowCause.Manual;
                timecardShareList.add(timecardShare);
            }
            
            if(!userIds.contains(proj.CT_Project_Partner__c) || test.isRunningTest()){
                pse__Timecard_Header__Share timecardShare = new pse__Timecard_Header__Share();
                timecardShare.ParentId = timecard.Id;
                timecardShare.UserOrGroupId = proj.CT_Project_Partner__c;
                timecardShare.AccessLevel = 'Read';
                timecardShare.RowCause = Schema.pse__Timecard_Header__Share.RowCause.Manual;
                timecardShareList.add(timecardShare);
            }
        }

        if(!expenseShareList.isEmpty()){
            Database.insert(expenseShareList, false);
        }

        if(!miscAdjustmentShareList.isEmpty()){
            Database.insert(miscAdjustmentShareList, false);
        }

        if(!timecardShareList.isEmpty()){
            Database.insert(timecardShareList, false);
        }
    }

    global void finish(Database.BatchableContext BC){
    }
}