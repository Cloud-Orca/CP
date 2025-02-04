trigger SurveyInvitationTrigger on SurveyInvitation (before insert, after update) {
    if(trigger.isBefore){
        if(trigger.isInsert){
            SurveyInvitationTriggerHandler.onBeforeInsert(trigger.new);
        }
    }

    if(trigger.isAfter){
        if(trigger.isUpdate){
            SurveyInvitationTriggerHandler.onAfterUpdate(trigger.new, trigger.oldMap);
        }
    }
}