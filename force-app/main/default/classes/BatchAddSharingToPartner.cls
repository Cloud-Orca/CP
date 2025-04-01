global with sharing class BatchAddSharingToPartner implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    public Set<Id> projectIds {get; set;}
    global BatchAddSharingToPartner(Set<Id> projectIds) {
        this.projectIds = projectIds; 
    }

    global BatchAddSharingToPartner() {
        this.projectIds = new Set<Id>();
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id FROM pse__Proj__c';
        if(!projectIds.isEmpty()){
            query += ' WHERE Id IN: projectIds';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<pse__Proj__c> projectList){
        pse__Proj__c proj = projectList.get(0);
        Id cooperParryGroupId = [SELECT Id FROM Group WHERE Name = 'Cooper Parry Managers'].Id;
        List<pse__Expense__Share> expenseShareList = new List<pse__Expense__Share>();
        for(pse__Expense__c expense: [SELECT Id FROM pse__Expense__c WHERE pse__Project__c =: proj.Id]){
            pse__Expense__Share expenseShare = new pse__Expense__Share();
            expenseShare.ParentId = expense.Id;
            expenseShare.UserOrGroupId = cooperParryGroupId;
            expenseShare.AccessLevel = 'Read';
            expenseShare.RowCause = Schema.pse__Expense__Share.RowCause.Manual;
            expenseShareList.add(expenseShare);
        }

        List<pse__Miscellaneous_Adjustment__Share> miscAdjustmentShareList = new List<pse__Miscellaneous_Adjustment__Share>();
        for(pse__Miscellaneous_Adjustment__c miscAdjustment: [SELECT Id FROM pse__Miscellaneous_Adjustment__c WHERE pse__Project__c =: proj.Id]){
            pse__Miscellaneous_Adjustment__Share miscAdjustmentShare = new pse__Miscellaneous_Adjustment__Share();
            miscAdjustmentShare.ParentId = miscAdjustment.Id;
            miscAdjustmentShare.UserOrGroupId = cooperParryGroupId;
            miscAdjustmentShare.AccessLevel = 'Read';
            miscAdjustmentShare.RowCause = Schema.pse__Miscellaneous_Adjustment__Share.RowCause.Manual;
            miscAdjustmentShareList.add(miscAdjustmentShare);
        }

        List<pse__Timecard_Header__Share> timecardShareList = new List<pse__Timecard_Header__Share>();
        for(pse__Timecard_Header__c timecard: [SELECT Id FROM pse__Timecard_Header__c WHERE pse__Project__c =: proj.Id]){
            pse__Timecard_Header__Share timecardShare = new pse__Timecard_Header__Share();
            timecardShare.ParentId = timecard.Id;
            timecardShare.UserOrGroupId = cooperParryGroupId;
            timecardShare.AccessLevel = 'Read';
            timecardShare.RowCause = Schema.pse__Timecard_Header__Share.RowCause.Manual;
            timecardShareList.add(timecardShare);
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