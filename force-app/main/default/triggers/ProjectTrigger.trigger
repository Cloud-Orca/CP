trigger ProjectTrigger on pse__Proj__c (after insert, after update) {
    if(trigger.isAfter){
        if(trigger.isInsert){
            ProjectTriggerHandler.onAfterInsert(trigger.new);
        }
        if(trigger.isUpdate){
            ProjectTriggerHandler.onAfterUpdate(trigger.new, trigger.oldMap);
        }
    } 
}