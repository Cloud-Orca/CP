@isTest(SeeAllData=true)
private class SurveyInvitationTriggerHandlerTest {
    @isTest
    static void onInsertInvitation(){
        QueueHttpMock mock = new QueueHttpMock();

        HttpResponse newFolderError = new HttpResponse();
        newFolderError.setStatusCode(401);
        newFolderError.setBody('{"message": "sample"}');
        mock.addResponse(newFolderError);

        HttpResponse getToken = new HttpResponse();
        getToken.setStatusCode(200);
        getToken.setBody('{"access_token": "1234343"}');
        mock.addResponse(getToken);

        HttpResponse newFolderOK = new HttpResponse();
        newFolderOK.setStatusCode(200);
        newFolderOK.setBody('{"id": "65454534"}');
        mock.addResponse(newFolderOK);

        HttpResponse publicFolder = new HttpResponse();
        publicFolder.setStatusCode(200);
        publicFolder.setBody('{"id": "65454534", "webUrl": "https://test.sharepoint.com/sites/rfdfdf"}');
        mock.addResponse(publicFolder);

        HttpResponse secureFolder = new HttpResponse();
        secureFolder.setStatusCode(200);
        secureFolder.setBody('{"id": "3434343", "webUrl": "https://test.sharepoint.com/sites/fdjdfksd"}');
        mock.addResponse(secureFolder);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            Account acc = new Account();
            acc.Name = 'CLOUD ORCA LIMITED';
            acc.Company_Legal_Name__c = 'CLOUD ORCA LIMITED';
            acc.Company_registration_number__c = '11354151';
            insert acc;

            Contact con = new Contact();
            con.Lastname = 'Cloud Orca Contact 1';
            con.AccountId = acc.id;
            insert con;

            SurveyInvitation inv = new SurveyInvitation();
            inv.Name = 'Sinvitation';
            inv.ParticipantId = con.Id;
            inv.SurveyId = [SELECT Id FROM Survey LIMIT 1].Id;
            inv.CommunityId = [SELECT Id FROM Network LIMIT 1].Id;
            insert inv;
        Test.stopTest();
    }

    @isTest
    static void onUpdateInvitation(){
        QueueHttpMock mock = new QueueHttpMock();

        HttpResponse newFolderError = new HttpResponse();
        newFolderError.setStatusCode(401);
        newFolderError.setBody('{"message": "sample"}');
        mock.addResponse(newFolderError);

        HttpResponse getToken = new HttpResponse();
        getToken.setStatusCode(200);
        getToken.setBody('{"access_token": "1234343"}');
        mock.addResponse(getToken);

        HttpResponse newFolderOK = new HttpResponse();
        newFolderOK.setStatusCode(200);
        newFolderOK.setBody('{"id": "65454534"}');
        mock.addResponse(newFolderOK);

        HttpResponse publicFolder = new HttpResponse();
        publicFolder.setStatusCode(200);
        publicFolder.setBody('{"id": "65454534", "webUrl": "https://test.sharepoint.com/sites/rfdfdf"}');
        mock.addResponse(publicFolder);

        HttpResponse secureFolder = new HttpResponse();
        secureFolder.setStatusCode(200);
        secureFolder.setBody('{"id": "3434343", "webUrl": "https://test.sharepoint.com/sites/fdjdfksd"}');
        mock.addResponse(secureFolder);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        Account acc = new Account();
        acc.Name = 'CLOUD ORCA LIMITED';
        acc.Company_Legal_Name__c = 'CLOUD ORCA LIMITED';
        acc.Company_registration_number__c = '11354151';
        insert acc;

        Contact con = new Contact();
        con.Lastname = 'Cloud Orca Contact 1';
        con.AccountId = acc.id;
        insert con;

        SurveyInvitation inv = new SurveyInvitation();
        inv.Name = 'Sinvitation';
        inv.ParticipantId = con.Id;
        inv.SurveyId = [SELECT Id FROM Survey LIMIT 1].Id;
        inv.CommunityId = [SELECT Id FROM Network LIMIT 1].Id;
        insert inv;

        inv.Name = '2nd Sinvitation';
        update inv;

        Test.stopTest();
    }
}