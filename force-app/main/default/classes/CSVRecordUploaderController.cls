/**
 * Created by: Clifford U.
 */
public with sharing class CSVRecordUploaderController {
    
    /**
    * @description: counts the number of rows a given csv content has
    * @param: (String) content of the csv file
    * @return: (Decimal) the total number of rows
    */ 
    @AuraEnabled
    public static Decimal getNumberOfRows(String csvData){
        csvData = csvData.replace('\r\n', '\n').replace('\r', '\n');
        List<String> rows = csvData.split('\n');
        return rows.size();
    }
    

    @AuraEnabled
    public static void createRecord(String csvData, String obj) {
        csvData = csvData.replace('\r\n', '\n').replace('\r', '\n');
        List<String> rows = csvData.split('\n');
        Database.executeBatch(new CSVRecordUploaderBatch(rows, obj), 100);
    }


    public static Map<String, String> dmlFunction(list<SObject> recs, List<String> validatedRcrds, String successFile, String errorFile) {

        Map<String, String> mapRet = new Map<String, String>();
        if (!recs.isEmpty()) {
            Database.SaveResult[] res = Database.Insert(recs, false);
            Integer count = 0; // determines specific validated item from the list.
            for (Database.SaveResult sr : res) {
                String csvRow = '';
                if (sr.isSuccess()) { // if success 
                    Id recId = sr.getId(); // get the record Id
                    csvRow = recId + ',' + validatedRcrds[count].replaceAll(':quotes:', '"').replaceAll(':comma:', ','); // concatinate the record Id and the validated item
                    successFile += csvRow + '\n'; // add the row to the final success csv string
                }else{ // if error
                    String errMsg = '';
                    for(Database.Error err : sr.getErrors()) {
                        errMsg = 'The following error has occurred. ' + err.getStatusCode() + ': ' + err.getMessage() + ' Fields that affected this error: ' + err.getFields(); // get the error message
                    }
                    System.debug('errMsg: ' + errMsg);
                    csvRow = errMsg + ',' + validatedRcrds[count].replaceAll(':quotes:', '"').replaceAll(':comma:', ','); // concatinate the error message and the validated item
                    errorFile += csvRow + '\n'; // add the row to the final error csv string
                }
                count ++;
            }
        }
        mapRet.put('successFile', successFile);
        mapRet.put('errorFile', errorFile);
        return mapRet;
        
    }
    
    public static Map<String, Object> fieldColumnMapping(List<Uploader_Mapping__mdt> uploadMapping, List<String> csvRows, List<String> headers, String objType, Map<String, Id> regNumAcc, Map<String, Id> dataOrigination, Boolean isFirstBatch) {
        Map<String, String> uploadMap = new Map<String, String>();
        String errorFile = 'Error';
        String successFile = 'RecordId';
        List<String> validatedRcrds = new List<String>(); // Validated Lead records for CSV generation.
        Map<String, String> fieldTypeMap = new Map<String, String>();
        for (Uploader_Mapping__mdt mapping : uploadMapping) {
            uploadMap.put(mapping.Column_Name__c, mapping.Field_API_Name__c);
        }

        for (FieldDefinition fieldType : [SELECT DataType, QualifiedApiName FROM FieldDefinition WHERE EntityDefinitionId=:objType AND QualifiedApiName IN :uploadMap.values()]) {
            fieldTypeMap.put(fieldType.QualifiedApiName, fieldType.DataType);
        }
        List<SObject> retSObj = new List<SObject>();
        Map<String, Object> mapRet = new Map<String, Object>();
        
        for (String header : headers) {
            errorFile += ',' + header;
            successFile += ',' + header;
        }
        errorFile += '\n';
        Integer leapCol = (isFirstBatch) ? 1 : 0; // Exclude the CSV header
        for (Integer i = leapCol; i < csvRows.size(); i++) {
            String csvLine = removeCommaValueCSV(csvRows[i]);
            List<String> rowValues = csvLine.split(',');
            SObject obj = createObject(objType);
            Boolean hasError = false;
            String errorMessage = ' ';
            List<String> potentialRecs = new List<String>();
            for (Integer j = 0; j < rowValues.size(); j++) {
                String columnHeader = headers[j];

                if(uploadMap.containsKey(columnHeader)){
                    String field = uploadMap.get(columnHeader);
                    if (field != null) {
                        try {
                            String val = rowValues[j].replaceAll(':quotes:', '').replaceAll(':comma:', ',');      
                            if (!String.isBlank(val)) {
                                if(fieldTypeMap.get(field) != null && fieldTypeMap.get(field).trim() != '' && (fieldTypeMap.get(field).contains('Number') || fieldTypeMap.get(field).contains('Currency') || fieldTypeMap.get(field).contains('Percent'))){
                                    obj.put(field, Decimal.valueOf(val));
                                }else if(fieldTypeMap.get(field) != null && fieldTypeMap.get(field).trim() != '' && fieldTypeMap.get(field).contains('Checkbox')){
                                    obj.put(field, Boolean.valueOf(val));
                                }else if(fieldTypeMap.get(field) != null && fieldTypeMap.get(field).trim() != '' && fieldTypeMap.get(field) == 'Date/Time'){
                                    obj.put(field, Datetime.valueOf(val));
                                }else if(fieldTypeMap.get(field) != null && fieldTypeMap.get(field).trim() != '' && fieldTypeMap.get(field) == 'Date'){
                                    obj.put(field, Date.valueOf(val));
                                }else if(fieldTypeMap.get(field) != null && fieldTypeMap.get(field).trim() != '' && fieldTypeMap.get(field) == 'Time'){
                                    List<String> timeStr = val.trim().split(':');
                                    if(timeStr.size() == 3){
                                        if(!timeStr[0].isNumeric()){
                                            hasError = true;
                                        }else if(!timeStr[1].isNumeric()){
                                            hasError = true;
                                        }else if(!timeStr[2].isNumeric()){
                                            hasError = true;
                                        }
                                    }else{
                                        hasError = true;
                                    }
                                    if(!hasError){
                                        Time timeValue = Time.newInstance(Integer.valueOf(timeStr[0]), Integer.valueOf(timeStr[1]), Integer.valueOf(timeStr[2]), 0);
                                        obj.put(field, timeValue);
                                    }else{
                                        errorMessage += 'Time format should be HH:MM:SS;';
                                    }

                                }else{
                                    obj.put(field, val);
                                }
                            }
                            
                        }catch (Exception e) {
                            hasError = true;
                            errorMessage += e.getMessage() + ';';
                        }
                    }
                }

                if(objType == 'Contact' && columnHeader == 'Registered Number'){
                    if(regNumAcc.containsKey(rowValues[j])){
                        obj.put(uploadMap.get('Registered Number'), regNumAcc.get(rowValues[j]));
                    }else{
                        if(rowValues[j] != null && rowValues[j] != ''){
                            errorMessage += 'Registered Number Does not Exist';
                            hasError = true;
                        }
                    }
                }

                if(objType == 'Account' && columnHeader == 'Data Origination ID'){
                    if(dataOrigination.containsKey(rowValues[j])){
                        obj.put(uploadMap.get('Data Origination ID'), dataOrigination.get(rowValues[j]));
                    }else{
                        if(rowValues[j] != null && rowValues[j].trim() != ''){
                            System.debug('rowValues[j]: ' + rowValues[j]);
                            errorMessage += 'Data Origination Name Does not Exist';
                            hasError = true;
                        }
                    }
                }

                potentialRecs.add(rowValues[j]);
            }
            if(!hasError){
                validatedRcrds.add(String.join(potentialRecs, ',')); // mark current Item as Validated.
                retSObj.add(obj);
            }else{
                errorFile += errorMessage + ',' + csvRows[i] + ',' + '\n';
            }
        }
        
        successFile += '\n';
        mapRet.put('successFile', successFile);
        mapRet.put('errorFile', errorFile);
        mapRet.put('validatedRcrds', validatedRcrds);
        mapRet.put('retSObj', retSObj);
        return mapRet;
    }


    public static String removeCommaValueCSV(String rowCsv){

        String csvLine = rowCsv;
        String prevLine = csvLine;
        Integer startIndex;
        Integer endIndex;
        while(csvLine.indexOf('"') > -1){
            if(startIndex == null){
                startIndex = csvLine.indexOf('"');
                csvLine = csvLine.substring(0, startIndex) + ':quotes:' + csvLine.substring(startIndex+1, csvLine.length());
            }else{
                if(endIndex == null){
                    endIndex = csvLine.indexOf('"');
                    csvLine = csvLine.substring(0, endIndex) + ':quotes:' + csvLine.substring(endIndex+1, csvLine.length());
                }
            }

            if(startIndex != null && endIndex != null){
                String sub = csvLine.substring(startIndex, endIndex);
                sub = sub.replaceAll(',', ':comma:');
                csvLine = csvLine.substring(0, startIndex) + sub + csvLine.substring(endIndex, csvLine.length());
                startIndex = null;
                endIndex = null;
            }
        }

        return csvLine;
    }

    public static sObject createObject(String typeName) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(typeName);
        return targetType.newSObject(); 
    }

    public static void sendEmail(String address, String subject, String body, String csvSuccessData, String csvErrorData){

        List<Messaging.EmailFileAttachment> csvAttachments = new List<Messaging.EmailFileAttachment>();
        if (csvSuccessData != null) {
            Messaging.EmailFileAttachment csvSuccessAttachment = new Messaging.EmailFileAttachment();
            csvSuccessAttachment.setFileName('Success_File('+ System.Now() + ').csv');
            csvSuccessAttachment.setBody(blob.valueOf(csvSuccessData));
            csvAttachments.add(csvSuccessAttachment);
        }

        if (csvErrorData != null) {
            Messaging.EmailFileAttachment csvErrorAttachment = new Messaging.EmailFileAttachment();
            csvErrorAttachment.setFileName('Error_File('+ System.Now() + ').csv');
            csvErrorAttachment.setBody(blob.valueOf(csvErrorData));
            csvAttachments.add(csvErrorAttachment);
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {address};
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setPlainTextBody(body);
        mail.setFileAttachments(csvAttachments);
        Messaging.SendEmailResult[] results = Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail });

        for (Messaging.SendEmailResult res : results) {
            if (res.isSuccess()) {
                System.debug('Email sent successfully');
            }else {
                System.debug('The following errors occurred: ' + res.getErrors());                 
            }
        }
        
    }
    
}