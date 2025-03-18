@IsTest 
public class CSVRecordUploaderControllerTest {

    @IsTest
    static void testGetNumberOfRows(){
        
        Test.startTest();
        String csvStrContent = 'First Name\nTest';
        Decimal count = CSVRecordUploaderController.getNumberOfRows(csvStrContent);
        System.assertEquals(2, count);
        Test.stopTest();
        
        Data_Origination__c dataOri = new Data_Origination__c();
        dataOri.Name = 'test';
        Insert dataOri;
         
    }
    
    @IsTest
    static void testCreateRecordAccount(){
        
        Test.startTest();
        String csvStrContent = 'Company Name\n"Test, test-test"';
        CSVRecordUploaderController.createRecord(csvStrContent, 'Account');
        Test.stopTest();
        
    }
    
    @IsTest
    static void testCreateRecordContact(){
        
        Test.startTest();
        Account newAcc = new Account();
        newAcc.Name = 'test';
        newAcc.Beauhurst_ID__c = '3245';
        insert newAcc;
        String csvStrContent = 'FirstName,LastName,Registered Number\nTest,Test,3245';
        CSVRecordUploaderController.createRecord(csvStrContent, 'Contact');
        Test.stopTest();
    }
    

}