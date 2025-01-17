public class CPNoteHTMLController {
    public CP_Note__c note { get; set; }
    public String htmlContent { get; set; }

    public CPNoteHTMLController(ApexPages.StandardController controller) {
        Id noteId = controller.getId();
        note = [SELECT Id, Description__c FROM CP_Note__c WHERE Id = :noteId];
        htmlContent = note.Description__c;
    }
}