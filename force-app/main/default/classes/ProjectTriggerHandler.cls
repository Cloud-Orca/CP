public with sharing class ProjectTriggerHandler {
    public static void onAfterInsert(List<pse__Proj__c> newProjects) {
        addSharingToPartner(newProjects, null);
    }

    public static void onAfterUpdate(List<pse__Proj__c> newProjects, Map<Id, pse__Proj__c> oldProjectMap) {
        addSharingToPartner(newProjects, oldProjectMap);
    }

    public static void addSharingToPartner(List<pse__Proj__c> newProjects, Map<Id, pse__Proj__c> oldProjectMap){
        Set<Id> projectIds = new Set<Id>();
        for(pse__Proj__c project: newProjects){
            if(trigger.isInsert && project.CT_Project_Partner__c != null){
                projectIds.add(project.Id);
            }
            else if(trigger.isUpdate && project.CT_Project_Partner__c != null && project.CT_Project_Partner__c != oldProjectMap.get(project.Id).CT_Project_Partner__c){
                projectIds.add(project.Id);
            }
        }

        if(!projectIds.isEmpty() && !System.isFuture()){
            Database.executeBatch(new BatchAddSharingToPartner(projectIds), 1);
        }
    } 
}