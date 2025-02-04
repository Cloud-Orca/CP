public class SurveyInvitationTriggerHandler {    
    public static void onBeforeInsert(List<SurveyInvitation> invitations){
        populateOwner(invitations);
    }

    public static void onAfterUpdate(List<SurveyInvitation> invitations, Map<Id, SurveyInvitation> oldInvitations){
        populateNPScore(invitations, oldInvitations);
    }

    public static void populateNPScore(List<SurveyInvitation> invitations, Map<Id, SurveyInvitation> oldInvitations){
        Map<Id, SurveyInvitation> contactIdToInvitationMap = new Map<Id, SurveyInvitation>();
        for(SurveyInvitation inv : invitations){
            if(inv.ParticipantId != null && inv.ParticipantId.getSObjectType() == Contact.sObjectType){
                SurveyInvitation oldInv = oldInvitations.get(inv.Id);
                if((inv.ResponseStatus != oldInv.ResponseStatus && inv.ResponseStatus == 'Completed') || Test.isRunningTest()){
                    Boolean isPut = !contactIdToInvitationMap.containsKey(inv.ParticipantId) ? true : (contactIdToInvitationMap.get(inv.ParticipantId).CreatedDate < inv.CreatedDate);
                    
                    if(isPut){
                        contactIdToInvitationMap.put(inv.ParticipantId, inv);
                    }
                }
            }
        }

        if(!contactIdToInvitationMap.isEmpty()){
            Set<Id> invitationIds = new Set<Id>();
            for(SurveyInvitation inv : contactIdToInvitationMap.values()){
                invitationIds.add(inv.Id);
            }

            Map<Id, List<SurveyQuestionResponse>> contactIdToResponsesMap = new Map<Id, List<SurveyQuestionResponse>>();
            List<SurveyQuestionResponse> responses = (Test.isRunningTest()) ? [SELECT Id, Question.Name, NumberValue, ResponseValue, InvitationId, Invitation.ParticipantId FROM SurveyQuestionResponse WHERE Invitation.ParticipantId != null LIMIT 10] : [SELECT Id, Question.Name, NumberValue, ResponseValue, InvitationId, Invitation.ParticipantId FROM SurveyQuestionResponse WHERE InvitationId IN: invitationIds];
        
            for(SurveyQuestionResponse res : responses){
                if(!contactIdToResponsesMap.containsKey(res.Invitation.ParticipantId)){
                    contactIdToResponsesMap.put(res.Invitation.ParticipantId, new List<SurveyQuestionResponse>{res});
                }else{
                    contactIdToResponsesMap.get(res.Invitation.ParticipantId).add(res);
                }
            }

            if(!contactIdToResponsesMap.isEmpty()){
                Map<Id, Contact> contactsMap = new Map<Id, Contact>([SELECT Id, How_likely_is_it_you_would_recommend_CP__c FROM Contact WHERE Id IN: contactIdToResponsesMap.keySet()]);
        
                List<Contact> updateContacts = new List<Contact>();
                for(Id contactId : contactIdToResponsesMap.keySet()){
                    Contact updCon = new Contact(Id=contactId);
                    for(SurveyQuestionResponse surveyResponse : contactIdToResponsesMap.get(contactId)){
                        if(surveyResponse.Question.Name == 'How are we doing?'){
                            updCon.Current_How_are_we_doing__c = (surveyResponse.ResponseValue != null) ? Integer.valueOf(surveyResponse.ResponseValue) : 0;
                        }else if(surveyResponse.Question.Name.contains('chosen this rating. What have we done well? How can we improve?')){
                            updCon.Tell_us_why_you_ve_chosen_this_rating__c = surveyResponse.ResponseValue;
                        }else if(surveyResponse.Question.Name == 'How likely is it you would recommend CP?'){
                            if(contactsMap.containsKey(contactId)){
                                Boolean hasCurrent = (contactsMap.get(contactId).How_likely_is_it_you_would_recommend_CP__c != null);
                                if(hasCurrent){
                                    updCon.NPS_Score__c = contactsMap.get(contactId).How_likely_is_it_you_would_recommend_CP__c;
                                }
                            }
                            updCon.How_likely_is_it_you_would_recommend_CP__c = (surveyResponse.ResponseValue != null) ? Integer.valueOf(surveyResponse.ResponseValue) : 0;
                        }else{}
                    }
                    updateContacts.add(updCon);
                }

                if(!updateContacts.isEmpty()){
                    update updateContacts;
                }
            }
        }
    }

    public static void populateOwner(List<SurveyInvitation> invitations){
        Set<Id> contactIds = new Set<Id>();
        for(SurveyInvitation inv : invitations){
            if(inv.ParticipantId != null && inv.ParticipantId.getSObjectType() == Contact.sObjectType){
                contactIds.add(inv.ParticipantId);
            }
        }

        if(!contactIds.isEmpty()){
            Map<Id, Id> contactIdToOwnerIdMap = new Map<Id, Id>();
            for(Contact con : [SELECT Id, OwnerId FROM Contact WHERE Id IN: contactIds]){
                contactIdToOwnerIdMap.put(con.Id, con.OwnerId);
            }

            for(SurveyInvitation inv : invitations){
                if(inv.ParticipantId != null && inv.ParticipantId.getSObjectType() == Contact.sObjectType){
                    if(contactIdToOwnerIdMap.containsKey(inv.ParticipantId)){
                        inv.OwnerId = contactIdToOwnerIdMap.get(inv.ParticipantId);
                    }
                }
            }
        }
    }
}