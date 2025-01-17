@isTest
public class CPNoteHTMLControllerTest {

    @isTest
    static void testCPNoteHTMLController() {
        CP_Note__c testNote = new CP_Note__c(
            Description__c = '<p>This is a test HTML content.</p>'
        );
        insert testNote;

        ApexPages.StandardController sc = new ApexPages.StandardController(testNote);
        CPNoteHTMLController controller = new CPNoteHTMLController(sc);

        System.assertNotEquals(controller.note, null, 'Note should not be null');
        System.assertEquals(testNote.Id, controller.note.Id, 'The note IDs should match');
        System.assertEquals(testNote.Description__c, controller.htmlContent, 'The HTML content should match the Description__c field');
    }
}