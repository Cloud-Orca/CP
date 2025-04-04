@IsTest
public class CSVRecordUploaderBatchTest {
    @TestSetup
    static void makeData(){
        
        Account acc = New Account();
        acc.Name = 'test';
        acc.Beauhurst_ID__c = '12345986';
        Insert acc;

        Data_Origination__c dataOri = new Data_Origination__c();
        dataOri.Name = 'test';
        Insert dataOri;

    }

    @IsTest
    static void wihoutDataOriginationCreateRecordAccount(){
        
        Test.startTest();
        String csvStrContent = 'Company Name\nTest';
        CSVRecordUploaderController.createRecord(csvStrContent, 'Account');
        Test.stopTest();
        
    }

    @IsTest
    static void wihDataOriginationCreateRecordAccount(){
        
        Test.startTest();
        String csvStrContent = 'Company Name,Data Origination ID\nTest,test';
        CSVRecordUploaderController.createRecord(csvStrContent, 'Account');
        Test.stopTest();
        
    }
    
    @IsTest
    static void withoutRegistrationNumberTest(){
        
        Test.startTest();

        String csvStrContent = 'FirstName,LastName,Registered Number\nTest,Test,3245';
        CSVRecordUploaderController.createRecord(csvStrContent, 'Contact');
        Test.stopTest();
    }

    @IsTest
    static void withRegistrationNumberTest(){
        
        Test.startTest();
        String csvStrContent = 'FirstName,LastName,Registered Number\nTest,Test,12345986';
        CSVRecordUploaderController.createRecord(csvStrContent, 'Contact');
        Test.stopTest();
    }
}