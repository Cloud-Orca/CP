trigger SurveyInvitationTrigger on SurveyInvitation (before insert, after update) {

    if(trigger.isBefore){
        if(trigger.isInsert){
            SurveyInvitationTriggerHandler.onBeforeInsert(trigger.new);
            System.debug('trigger.new.size(): ' + trigger.new.size());
        }
    }

    if(trigger.isAfter){
        if(trigger.isUpdate){
            SurveyInvitationTriggerHandler.onAfterUpdate(trigger.new, trigger.oldMap);
        }
    }
}