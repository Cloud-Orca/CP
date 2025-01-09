public class SurveyInvitationTriggerHandler {
    public static void onBeforeInsert(List<SurveyInvitation> invitations){
        populateOwner(invitations);
    }

    public static void onAfterUpdate(List<SurveyInvitation> invitations, Map<Id, SurveyInvitation> oldInvitations){
        populateNPScore(invitations, oldInvitations);
    }

    public static void populateNPScore(List<SurveyInvitation> invitations, Map<Id, SurveyInvitation> oldInvitations){
        Map<Id, Id> invitationIdToContactIdMap = new Map<Id, Id>();
        for(SurveyInvitation inv : invitations){
            if(inv.ParticipantId != null && inv.ParticipantId.getSObjectType() == Contact.sObjectType){
                SurveyInvitation oldInv = oldInvitations.get(inv.Id);
                if(inv.ResponseStatus != oldInv.ResponseStatus && inv.ResponseStatus == 'Completed'){
                    invitationIdToContactIdMap.put(inv.Id, inv.ParticipantId);
                }
            }
        }

        if(!invitationIdToContactIdMap.isEmpty()){
            Map<Id, SurveyQuestionResponse> contactIdToResponseMap = new Map<Id, SurveyQuestionResponse>();
            for(SurveyQuestionResponse res : [SELECT Id, Question.Name, NumberValue, InvitationId, Invitation.CreatedDate FROM SurveyQuestionResponse WHERE InvitationId IN: invitationIdToContactIdMap.keySet() AND Question.Name = 'How likely is it you would recommend CP?' AND NumberValue != null]){
                Id contactId = invitationIdToContactIdMap.get(res.InvitationId);
                Boolean isPut = !contactIdToResponseMap.containsKey(contactId) ? true : (contactIdToResponseMap.get(contactId).Invitation.CreatedDate < res.Invitation.CreatedDate);
                
                if(isPut){
                    contactIdToResponseMap.put(contactId, res);
                }
            }

            if(!contactIdToResponseMap.isEmpty()){
                List<Contact> updateContacts = new List<Contact>();
                for(Id contactId : contactIdToResponseMap.keySet()){
                    SurveyQuestionResponse res = contactIdToResponseMap.get(contactId);

                    Contact updCon = new Contact(Id=contactId);
                    updCon.NPS_Score__c = res.NumberValue;
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