/**
 * This final rate card choice plugin example uses a custom Level field on the Estimate Role Request and Rate Card
 * objects to choose the rate card to match to each estimate role request. It will only use an exact match for
 * the Level field.
 */
global class CPQRateSelectorPlugin implements ffscpq.RateCardMatcherPlugin.IFinalRateCardChoicePlugin {
    
    
    global List<ffscpq.RateCardMatcherPlugin.FinalRateCardChoiceResponse> chooseRateCards(List<ffscpq.RateCardMatcherPlugin.FinalRateCardChoiceRequest> requests) {
        // Gather the rate cards and role requests to query for the custom Level field.
        /*Set<Id> rateCardIds = new Set<Id>();
        Set<Id> estimateRoleRequestIds = new Set<Id>();
        for (ffscpq.RateCardMatcherPlugin.FinalRateCardChoiceRequest request : requests) {
            for (pse__Rate_Card__c rateCard : request.getRateCardsToChooseFrom()) {
                rateCardIds.add(rateCard.Id);
            }
            switch on request.getRecord() {
                when ffscpq__Estimate_Role_Request__c estimateRoleRequest {
                    estimateRoleRequestIds.add(estimateRoleRequest.Id);
                }
            }
        }
*/
 
        List<ffscpq.RateCardMatcherPlugin.FinalRateCardChoiceResponse> responses = new List<ffscpq.RateCardMatcherPlugin.FinalRateCardChoiceResponse>();
 
        for (ffscpq.RateCardMatcherPlugin.FinalRateCardChoiceRequest request : requests) {
            ffscpq.RateCardMatcherPlugin.FinalRateCardChoiceResponse response = new ffscpq.RateCardMatcherPlugin.FinalRateCardChoiceResponse();
            responses.add(response);
 
            switch on request.getRecord() {
                when ffscpq__Estimate_Role_Request__c estimateRoleRequest {
                    Set<pse__Rate_Card__c> ratecards = request.getRateCardsToChooseFrom();
                    //if(ratecards.size() == 1){
                        // if only one ratecard was found, select that one
                    //    response.setChosenRateCard(ratecards.iterator().next());
                    //} 
                    //else 
                    //{
                        // if only multiple ratecards found, select the one that has both the Region and the Practice
                        // 
                        pse__Rate_Card__c potentialRatecard;
                        pse__Rate_Card__c chosenRatecard;
                        for (pse__Rate_Card__c rateCard : request.getRateCardsToChooseFrom()) {
                            system.debug(rateCard);
                            if (rateCard.pse__Practice__c == estimateRoleRequest.ffscpq__Practice__c )
                            {
                                if (rateCard.pse__Region__c == null) {
                                    potentialRatecard = rateCard;
                                } else if (rateCard.pse__Region__c == estimateRoleRequest.ffscpq__Region__c )
                                {
                                	chosenRatecard = rateCard;
                                }
                            }
                        }
                        if (chosenRatecard == null){
                            chosenRatecard = potentialRatecard;
                        }
                        response.setChosenRateCard(chosenRatecard);
                    //}
                }
            }
        
        }
 
        return responses;
    }

}