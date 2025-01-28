global class BatchCreateSharepointFolderAccount implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public Set<Id> accountIds;

    global BatchCreateSharepointFolderAccount(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, Name, Sharepoint_Public_Folder_URL__c, Sharepoint_Secure_Folder_URL__c FROM Account WHERE Id IN: accountIds]);
    }

    global void execute(Database.BatchableContext BC, List<Account> accountList){
        try {
            Account accRec = accountList.get(0);
            Account accRecToUpdate = new Account(Id = accountList.get(0).Id);

            List<Sharepoint_API__c> sharepointAPIlist = [SELECT Id, access_token__c FROM Sharepoint_API__c LIMIT 1];
            String accessToken = sharepointAPIlist.get(0).access_token__c;

            if(!sharepointAPIlist.isEmpty()){
                Boolean isUpdateAccessToken = false;

                //public account
                if(accRec.Sharepoint_Public_Folder_URL__c == null){
                    HttpResponse httpRes = SharepointAPIUtility.createNewFolderFromParentDocument(accessToken, accRec.Name, true);
                    if(httpRes.getStatusCode() == 401){
                        accessToken = getNewAccessToken();
                        httpRes = SharepointAPIUtility.createNewFolderFromParentDocument(accessToken, accRec.Name, true);
                        isUpdateAccessToken = true;
                    }
        
                    if(httpRes.getStatusCode() == 200 || httpRes.getStatusCode() == 201){
                        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(httpRes.getBody());
                        String folderId = (String) responseMap.get('id');
                        accRecToUpdate.Sharepoint_Public_Folder_ID__c = folderId;
                        accRecToUpdate.Sharepoint_Public_Folder_URL__c = accRec.Name;
                    }
                }

                //secure account
                if(accRec.Sharepoint_Secure_Folder_URL__c == null){
                    String secureFolderName = 'Secure ' + accRec.Name;
                    HttpResponse httpRes2 = SharepointAPIUtility.createNewFolderFromParentDocument(accessToken, secureFolderName, false);
                    if(httpRes2.getStatusCode() == 401){
                        accessToken = getNewAccessToken();
                        httpRes2 = SharepointAPIUtility.createNewFolderFromParentDocument(accessToken, secureFolderName, false);
                        isUpdateAccessToken = true;
                    }

                    if(httpRes2.getStatusCode() == 200 || httpRes2.getStatusCode() == 201){
                        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(httpRes2.getBody());
                        accRecToUpdate.Sharepoint_Secure_Folder_ID__c = (String) responseMap.get('id');
                        accRecToUpdate.Sharepoint_Secure_Folder_URL__c = secureFolderName;
                    }
                }

                if(isUpdateAccessToken){
                    updateSharepointAccessToken(sharepointAPIlist.get(0).Id, accessToken);
                }

                update accRecToUpdate;
            }
        } catch (Exception e) {
            System.debug(e.getMessage() + ' ' + e.getLineNumber());
        }
    }

    global void finish(Database.BatchableContext BC){
    }

    public static void updateSharepointAccessToken(Id sharepointId, String accessToken){
        Sharepoint_API__c sharepointAPI = new Sharepoint_API__c(Id = sharepointId);
        sharepointAPI.access_token__c = accessToken;
        update sharepointAPI;
    }

    public static String getNewAccessToken(){
        HttpResponse httpRes = SharepointAPIUtility.getAccessToken();
        String accessToken = '';
        if(httpRes.getStatusCode() == 200){
            AccessTokenResponse clientResultWrap = (AccessTokenResponse)JSON.deserialize(httpRes.getBody(), AccessTokenResponse.class);
            accessToken = clientResultWrap.access_token;
        }
        return accessToken;
    }

    public class AccessTokenResponse{
        public String access_token;
    }
}