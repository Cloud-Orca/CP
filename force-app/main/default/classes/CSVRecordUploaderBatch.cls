/**
 * Created By: Clifford U
 */
public class CSVRecordUploaderBatch implements Database.Batchable<String>, Database.Stateful{
    private List<string> csvRows;
    private string obj;
    private Map<String, String> result = new Map<String, String>();
    private List<String> headers = new List<String>(); 
    private Boolean isFirstBatch = true;
    public CSVRecordUploaderBatch(List<String> csvData, String obj){
        this.csvRows = csvData; 
        
        this.obj = obj;
        this.headers = csvData[0].split(',');
    }
    public Iterable<String> start(Database.BatchableContext info){
        return this.csvRows;
    }
    public void execute(Database.BatchableContext info, List<String> rows){

        List<Uploader_Mapping__mdt> uploadAccountMapping = [SELECT Column_Name__c, Field_API_Name__c, Object_Name__c FROM Uploader_Mapping__mdt WHERE (Object_Name__c  = :obj OR Object_Name__c  = :obj.toLowerCase()) AND Column_Name__c IN :this.headers];
        Map<String, Id> regNumAcc = new Map<String, Id>();
        Map<String, Id> dataOriginationMap = new Map<String, Id>();
        
        if(obj == 'Contact'){
            List<String> regNumbers = new List<String>();
            for (Integer i = 1; i < rows.size(); i++) {
                String csvLine = CSVRecordUploaderController.removeCommaValueCSV(rows[i]);
                List<String> rowValues = csvLine.split(',');
                for (Integer j = 0; j < rowValues.size(); j++) {
                    String columnHeader = headers[j];
                    if(columnHeader == 'Registered Number'){
                        String regNum = rowValues[j].replaceAll(':quotes:', '').replaceAll(':comma:', ',');
                        regNumbers.add( regNum );
                    }
                }
            }
            if(!regNumbers.isEmpty()){
                List<Account> parentAccounts = [SELECT Id, Beauhurst_ID__c FROM Account WHERE Beauhurst_ID__c IN:regNumbers];
                if(!parentAccounts.isEmpty()){
                    for (Account parentAccount : parentAccounts) {
                        regNumAcc.put(parentAccount.Beauhurst_ID__c, parentAccount.Id);
                    }    
                }
            }
        }


        if(obj == 'Account'){
            List<String> dataOriginationNames = new List<String>();
            for (Integer i = 1; i < rows.size(); i++) {
                String csvLine = CSVRecordUploaderController.removeCommaValueCSV(rows[i]);
                List<String> rowValues = csvLine.split(',');
                for (Integer j = 0; j < rowValues.size(); j++) {
                    String columnHeader = headers[j];
                    if(columnHeader == 'Data Origination ID'){
                        String regNum = rowValues[j].replaceAll(':quotes:', '').replaceAll(':comma:', ',');
                        dataOriginationNames.add( regNum );
                    }
                }
            }

            if(!dataOriginationNames.isEmpty()){
                List<Data_Origination__c> dataOr = [SELECT Id, Name FROM Data_Origination__c WHERE Name IN :dataOriginationNames];
                if (dataOr.size() > 0) {
                    for (Data_Origination__c dtOr : dataOr) {
                        if(!dataOriginationMap.containsKey(dtOr.Name)){
                            dataOriginationMap.put(dtOr.Name, dtOr.Id);
                        }
                    }
                }
            }
        }

        Map<String, Object> accDynamic = CSVRecordUploaderController.fieldColumnMapping(uploadAccountMapping, rows, this.headers, obj, regNumAcc, dataOriginationMap, this.isFirstBatch);
        String errorFile = (String)accDynamic.get('errorFile');
        String successFile = (String)accDynamic.get('successFile');
        List<String> validatedRcrds = (List<String>) accDynamic.get('validatedRcrds');
        List<SObject> retSObj = (List<SObject>) accDynamic.get('retSObj');
        map<String, String> res = CSVRecordUploaderController.dmlFunction(retSObj, validatedRcrds, successFile, errorFile);


        String successHeader = '';
        String errorHeader = '';

        String successCSVRows = '';
        String errorCSVRows = '';
        if (res.containsKey('successFile')) {
            successHeader = res.get('successFile').split('\n')[0];
            successCSVRows = res.get('successFile').remove(res.get('successFile').mid(0, res.get('successFile').indexOf('\n')+1));
        }
        if (res.containsKey('errorFile')) {
            errorHeader = res.get('errorFile').split('\n')[0];
            errorCSVRows = res.get('errorFile').remove(res.get('errorFile').mid(0, res.get('errorFile').indexOf('\n')+1));
        }

        if(this.result.containsKey('csvSuccess')){
            if(!this.result.get('csvSuccess').contains(successHeader)){
                this.result.put('csvSuccess', successHeader + '\n');
            }
            this.result.put('csvSuccess', this.result.get('csvSuccess') + successCSVRows);
        }else{
            this.result.put('csvSuccess', successHeader + '\n' + successCSVRows);
        }

        
        if(this.result.containsKey('csvError')){
            if(!this.result.get('csvError').contains(errorHeader)){
                this.result.put('csvError', errorHeader + '\n');
            }
            this.result.put('csvError', this.result.get('csvError') + errorCSVRows);
        }else{
            this.result.put('csvError', errorHeader + '\n' + errorCSVRows);
        }
        this.isFirstBatch = false;
    }

    public void finish(Database.BatchableContext info){
        // Send email here
        String emailAddress = UserInfo.getUserEmail();
        System.debug('emailAddress: ' + emailAddress);
        CSVRecordUploaderController.sendEmail(emailAddress, 
                                                'Record Upload Complete', 
                                                'Bulk Upload completed, please see the attached CSV file!',
                                                this.result.get('csvSuccess'), 
                                                this.result.get('csvError'));
    }

}