global class CTCustomRateCardMatcher implements pse.RateCardMatcherPlugin.IFinalRateCardChoicePlugin {
    
    global List<pse.RateCardMatcherPlugin.FinalRateCardChoiceResponse> chooseRateCards(
        List<pse.RateCardMatcherPlugin.FinalRateCardChoiceRequest> requests
    ) {
        //system.debug(1/0);
        // Gather the rate cards and resource requests to query for the custom Level field.
        // Custom fields are not included on the rate cards and records passed into the plugin
        // so they must be queried.
        Set<Id> rateCardIds = new Set<Id>();
        Set<Id> resourceRequestIds = new Set<Id>();
        for (pse.RateCardMatcherPlugin.FinalRateCardChoiceRequest request : requests) {
            for (pse__Rate_Card__c rateCard : request.getRateCardsToChooseFrom()) {
                rateCardIds.add(rateCard.Id);
            }
 
            switch on request.getRecord() {
                when pse__Resource_Request__c resourceRequest {
                    resourceRequestIds.add(resourceRequest.Id);
                }
                when pse__Assignment__c assignment {
                    // Custom rate card matching logic for assignments can be implemented here. In this
                    // plugin implementation, assignments are ignored.
                }
            }
        }
 
        // Select the custom Level__c fields on both rate card and resource request to use them
        // to find a match.
/*
 		Map<Id, pse__Rate_Card__c> rateCardWithLevelById = new Map<Id, pse__Rate_Card__c>(
            [SELECT Id, Level__c FROM pse__Rate_Card__c WHERE Id IN :rateCardIds]
        );
        Map<Id, pse__Resource_Request__c> resourceRequestWithLevelById = new Map<Id, pse__Resource_Request__c>(
            [SELECT Id, Level__c FROM pse__Resource_Request__c WHERE Id IN :resourceRequestIds]
        );
*/
 
        List<pse.RateCardMatcherPlugin.FinalRateCardChoiceResponse> responses = new List<pse.RateCardMatcherPlugin.FinalRateCardChoiceResponse>();
 
        for (pse.RateCardMatcherPlugin.FinalRateCardChoiceRequest request : requests) {
            // Add a response to the list for every request so that the response list matches the
            // request list. Responses that do not have a chosen rate card set will not populate
            // the rates on the record.
            pse.RateCardMatcherPlugin.FinalRateCardChoiceResponse response = new pse.RateCardMatcherPlugin.FinalRateCardChoiceResponse();
            responses.add(response);
  system.debug(request.getRecord());
            switch on request.getRecord() {
                when pse__Resource_Request__c resourceRequest {
                    /*
                    String resourceRequestLevel = resourceRequestWithLevelById.get(
                            resourceRequest.Id
                        )
                        .Level__c;
 */
                    for (pse__Rate_Card__c rateCard : request.getRateCardsToChooseFrom()) {
                        // All other matching parameters including Start Date, Resource Role,
                        // Account, Region, Practice, and Group have already been applied. The rate
                        // cards to choose from are equally matched according to those parameters.
                        //String rateCardLevel = rateCardWithLevelById.get(rateCard.Id).Level__c;
 
                        //if (resourceRequestLevel == rateCardLevel) {
                            // If there is an exact match on the Level field choose the Rate Card.
                            //response.setChosenRateCard(rateCard);
 system.debug(rateCard);
                            // Assume there will only be one rate card that matches for each resource request.
                           // break;
                        //}
                    }
					
                }
            }
        }
 
        return responses;
    }
}