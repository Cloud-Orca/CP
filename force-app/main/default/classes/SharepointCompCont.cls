public class SharepointCompCont {
   
    public static String getNewAccessToken(){
        HttpResponse httpRes = SharepointAPIUtility.getAccessToken();
        String accessToken = '';
        if(httpRes.getStatusCode() == 200){
            AccessTokenResponse clientResultWrap = (AccessTokenResponse)JSON.deserialize(httpRes.getBody(), AccessTokenResponse.class);
            accessToken = clientResultWrap.access_token;
        }
        return accessToken;
    }

    public static void updateSharepointAccessToken(Id sharepointId, String accessToken){
        Sharepoint_API__c sharepointAPI = new Sharepoint_API__c(Id = sharepointId);
        sharepointAPI.access_token__c = accessToken;
        update sharepointAPI;
    }

    @AuraEnabled
    public static String getDriveItemId(Id recordId){
        if(recordId.getsobjecttype() == Schema.Account.getSObjectType()){
            return  [SELECT Id, Sharepoint_Folder_ID__c FROM Account WHERE Id =: recordId].Sharepoint_Folder_ID__c;
        }
        else if(recordId.getsobjecttype() == Schema.Case.getSObjectType()){
            return  [SELECT Id, Sharepoint_Folder_ID__c FROM Case WHERE Id =: recordId].Sharepoint_Folder_ID__c;
        }
        return '';
    }

    @AuraEnabled
    public static Boolean getSecurePublicGroup(){
        try {
            List<GroupMember> secureGroupMember = [SELECT Id, GroupId, Group.Name, UserOrGroupId FROM GroupMember WHERE Group.Name = 'Secure Public Group' AND UserOrGroupId =: UserInfo.getUserId()];
            return !secureGroupMember.isEmpty();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<DriveItemDetails> getPathDriveItems(Id recordId){
        try {
            List<DriveItemDetails> driveItemListToReturn = new List<DriveItemDetails>();
            String publicFolderId = '';
            String secureFolderId = '';
            
            if(recordId.getsobjecttype() == Schema.Account.getSObjectType()){
                Account accountRec = [SELECT Id, Sharepoint_Public_Folder_ID__c, Sharepoint_Secure_Folder_ID__c, Sharepoint_Public_Folder_URL__c, Sharepoint_Secure_Folder_URL__c FROM Account WHERE Id =: recordId];
                publicFolderId = accountRec.Sharepoint_Public_Folder_URL__c;
                secureFolderId = accountRec.Sharepoint_Secure_Folder_URL__c;
            }
            else if(recordId.getsobjecttype() == Schema.Case.getSObjectType()){
                Case caseRec = [SELECT Id, Account.Sharepoint_Public_Folder_URL__c, Account.Sharepoint_Secure_Folder_URL__c, Sharepoint_Public_Folder_URL__c, Sharepoint_Secure_Folder_URL__c FROM Case WHERE Id =: recordId];
                publicFolderId = caseRec.Account.Sharepoint_Public_Folder_URL__c;
                secureFolderId = caseRec.Account.Sharepoint_Secure_Folder_URL__c;
            }

            if(publicFolderId != '' && publicFolderId != null && secureFolderId != '' && secureFolderId != null){
                List<Sharepoint_API__c> sharepointAPIlist = [SELECT Id, access_token__c FROM Sharepoint_API__c LIMIT 1];
                String accessToken = sharepointAPIlist.get(0).access_token__c;
                if(!sharepointAPIlist.isEmpty()){
                    Boolean isUpdateAccessToken = false;
                    HttpResponse httpRes = SharepointAPIUtility.getCurrentDriveItem(accessToken, publicFolderId, true);
                    if(httpRes.getStatusCode() == 401){
                        accessToken = getNewAccessToken();
                        httpRes = SharepointAPIUtility.getCurrentDriveItem(accessToken, publicFolderId, true);
                        isUpdateAccessToken = true;
                    }

                    if(httpRes.getStatusCode() == 200){
                        DriveItemDetails driveItem = (DriveItemDetails)JSON.deserialize(httpRes.getBody(), DriveItemDetails.class);
                        driveItem.isFolder = (driveItem.folder != null) ? true: false;
                        driveItem.sizeToDisplay = (driveItem.isFolder) ? String.valueOf(driveItem.folder.childCount) + ' items' : String.valueOf((driveItem.size / 1024).setScale(1, RoundingMode.HALF_UP)) + ' KB';

                        driveItem.modifiedByName = driveItem.lastModifiedBy?.user?.displayName;
                        driveItem.createdByName = driveItem.createdBy?.user?.displayName;

                        driveItem.currentDriveItemId = driveItem.parentReference?.id;
                        driveItem.isPublic = true;

                        if(driveItem.createdDateTime != null){
                            String dateString = driveItem.createdDateTime;
                            dateString = dateString.replace('T', ' ').replace('Z', '');
                            DateTime dt = DateTime.valueOfGmt(dateString);
                            driveItem.createdDateTimeFinal = dt;
                        }

                        if(driveItem.lastModifiedDateTime != null){
                            String dateString = driveItem.lastModifiedDateTime;
                            dateString = dateString.replace('T', ' ').replace('Z', '');
                            DateTime dt = DateTime.valueOfGmt(dateString);
                            driveItem.lastModifiedDateTimeFinal = dt;
                        }

                        driveItemListToReturn.add(driveItem);
                    }

                    HttpResponse httpRes2 = SharepointAPIUtility.getCurrentDriveItem(accessToken, secureFolderId, false);
                    if(httpRes2.getStatusCode() == 200){
                        DriveItemDetails driveItem = (DriveItemDetails)JSON.deserialize(httpRes2.getBody(), DriveItemDetails.class);
                        driveItem.isFolder = (driveItem.folder != null) ? true: false;
                        driveItem.sizeToDisplay = (driveItem.isFolder) ? String.valueOf(driveItem.folder.childCount) + ' items' : String.valueOf((driveItem.size / 1024).setScale(1, RoundingMode.HALF_UP)) + ' KB';

                        driveItem.modifiedByName = driveItem.lastModifiedBy?.user?.displayName;
                        driveItem.createdByName = driveItem.createdBy?.user?.displayName;

                        driveItem.currentDriveItemId = driveItem.parentReference?.id;
                        driveItem.isPublic = false;

                        if(driveItem.createdDateTime != null){
                            String dateString = driveItem.createdDateTime;
                            dateString = dateString.replace('T', ' ').replace('Z', '');
                            DateTime dt = DateTime.valueOfGmt(dateString);
                            driveItem.createdDateTimeFinal = dt;
                        }

                        if(driveItem.lastModifiedDateTime != null){
                            String dateString = driveItem.lastModifiedDateTime;
                            dateString = dateString.replace('T', ' ').replace('Z', '');
                            DateTime dt = DateTime.valueOfGmt(dateString);
                            driveItem.lastModifiedDateTimeFinal = dt;
                        }
                        
                        driveItemListToReturn.add(driveItem);
                    }

                    if(isUpdateAccessToken){
                        updateSharepointAccessToken(sharepointAPIlist.get(0).Id, accessToken);
                    }

                    return driveItemListToReturn;
                }
            }
            return null;
        } catch (Exception e) {
            System.debug(e.getMessage() + ' - ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<DriveItemDetails> getChildrenFromDriveId(String driveItemId, Id recordId, Boolean isPublic){
        try {
            List<Sharepoint_API__c> sharepointAPIlist = [SELECT Id, access_token__c FROM Sharepoint_API__c LIMIT 1];
            String accessToken = sharepointAPIlist.get(0).access_token__c;
            if(!sharepointAPIlist.isEmpty()){
                Boolean isUpdateAccessToken = false;
                HttpResponse httpRes = SharepointAPIUtility.getChildrenFromDriveItemId(accessToken, driveItemId, isPublic);
                if(httpRes.getStatusCode() == 401){
                    accessToken = getNewAccessToken();
                    httpRes = SharepointAPIUtility.getChildrenFromDriveItemId(accessToken, driveItemId, isPublic);
                    isUpdateAccessToken = true;
                }
    
                if(httpRes.getStatusCode() == 200){
                    DriveItemResponse driveResp = (DriveItemResponse)JSON.deserialize(httpRes.getBody(), DriveItemResponse.class);
                    if(!driveResp.value.isEmpty()){
                        for(DriveItemDetails driveItem: driveResp.value){
                            driveItem.isFolder = (driveItem.folder != null) ? true: false;
                            Decimal fileSizeInKB = driveItem.size / 1024;
                            driveItem.sizeToDisplay = (driveItem.isFolder) ? String.valueOf(driveItem.folder.childCount) + ' items' : String.valueOf((driveItem.size / 1024).setScale(1, RoundingMode.HALF_UP)) + ' KB';

                            driveItem.modifiedByName = driveItem.lastModifiedBy?.user?.displayName;
                            driveItem.createdByName = driveItem.createdBy?.user?.displayName;
                            driveItem.isPublic = isPublic;

                            if(driveItem.createdDateTime != null){
                                String dateString = driveItem.createdDateTime;
                                dateString = dateString.replace('T', ' ').replace('Z', '');
                                DateTime dt = DateTime.valueOfGmt(dateString);
                                driveItem.createdDateTimeFinal = dt;
                            }

                            if(driveItem.lastModifiedDateTime != null){
                                String dateString = driveItem.lastModifiedDateTime;
                                dateString = dateString.replace('T', ' ').replace('Z', '');
                                DateTime dt = DateTime.valueOfGmt(dateString);
                                driveItem.lastModifiedDateTimeFinal = dt;
                            }
                        }

                        if(isUpdateAccessToken){
                            updateSharepointAccessToken(sharepointAPIlist.get(0).Id, accessToken);
                        }

                        return driveResp.value;
                    }
                }
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + ' - ' + e.getLineNumber());
        }
    }

    @AuraEnabled
    public static Boolean uploadDocument(Id recordId, String driveItemId, String fileDataList, Boolean isPublic){
        List<FileWrapper> fileWrappList = (List<FileWrapper>) JSON.deserialize(fileDataList, List<FileWrapper>.class);

        System.debug('@@@ fileWrappList: ' + fileWrappList);
        List<ContentVersion> cvList = new List<ContentVersion>();
        for(FileWrapper fileWrapp: fileWrappList){
            ContentVersion cv = new ContentVersion();
            cv.VersionData = EncodingUtil.base64Decode(fileWrapp.base64);
            cv.Title = fileWrapp.filename;
            cv.PathOnClient = fileWrapp.filename;
            cv.ContentLocation = 'S';
            cv.SharingOption = 'A';
            cv.Origin = 'C';
            cvList.add(cv);
        }

        if(!cvList.isEmpty() && driveItemId != null){
            return uploadFileFromDriveId(driveItemId, cvList, recordId, isPublic);
        }
        return false;
        // if(!fileWrappList.isEmpty()){
        //     FileWrapper fileWrapp = fileWrappList.get(0);
        //     ContentVersion cv = new ContentVersion();
        //     cv.VersionData = EncodingUtil.base64Decode(fileWrapp.base64);
        //     cv.Title = fileWrapp.filename;
        //     cv.PathOnClient = fileWrapp.filename;
        //     cv.ContentLocation = 'S';
        //     cv.SharingOption = 'A';
        //     cv.Origin = 'C';

        //     if(driveItemId != null){
        //         return uploadFileFromDriveId(driveItemId, cv, recordId);
        //     }
        // }
        // return false;
    }

    @AuraEnabled
    public static Boolean uploadFileFromDriveId(String driveItemId, List<ContentVersion> cvList, Id recordId, Boolean isPublic){
        try {
            List<Sharepoint_API__c> sharepointAPIlist = [SELECT Id, access_token__c FROM Sharepoint_API__c LIMIT 1];
            String accessToken = sharepointAPIlist.get(0).access_token__c;

            if(!sharepointAPIlist.isEmpty()){
                Boolean isUpdateAccessToken = false;

                for(ContentVersion cv: cvList){
                    HttpResponse httpRes = SharepointAPIUtility.uploadFileToDriveItem(accessToken, driveItemId, cv.Title, cv.VersionData, isPublic);
                    if(httpRes.getStatusCode() == 401){
                        accessToken = getNewAccessToken();
                        httpRes = SharepointAPIUtility.uploadFileToDriveItem(accessToken, driveItemId, cv.Title, cv.VersionData, isPublic);
                        isUpdateAccessToken = true;
                    }
                }

                if(isUpdateAccessToken){
                    updateSharepointAccessToken(sharepointAPIlist.get(0).Id, accessToken);
                }
                return true;
            }
            return false;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class AccessTokenResponse{
        public String access_token;
    }

    public class DriveItemResponse{
        @AuraEnabled public List<DriveItemDetails> value;
    }

    public class DriveItemDetails{
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String webUrl;
        @AuraEnabled public Decimal size;
        @AuraEnabled public String sizeToDisplay;
        @AuraEnabled public FolderDetails folder;
        @AuraEnabled public Boolean isFolder;
        @AuraEnabled public String modifiedByName;
        @AuraEnabled public String createdByName;
        @AuraEnabled public String currentDriveItemId;
        @AuraEnabled public Boolean isPublic;
        @AuraEnabled public String createdDateTime;
        @AuraEnabled public String lastModifiedDateTime;
        @AuraEnabled public DateTime createdDateTimeFinal;
        @AuraEnabled public DateTime lastModifiedDateTimeFinal;

        @AuraEnabled public UserInfoDetail createdBy;
        @AuraEnabled public UserInfoDetail lastModifiedBy;
        @AuraEnabled public ParentInfo parentReference;
    }

    public class FolderDetails{
        @AuraEnabled public Decimal childCount;
    }

    public class UserInfoDetail{
        public UserDetails user;
    }

    public class UserDetails{
        public String displayName;
    }

    public class FileWrapper{
        @AuraEnabled public String filename;
        @AuraEnabled public String base64;
        @AuraEnabled public String fileSection;
        @AuraEnabled public String caseFieldAPI;
    }

    public class ParentInfo{
        public String id;
    }
}