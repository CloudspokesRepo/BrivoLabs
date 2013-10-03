@isTest
private class MeetingTokenizerController_Test {

    static testMethod void test_1() {
        Test.startTest();
        Event evt = new Event();
        evt.DurationInMinutes = 60;
        evt.ActivityDateTime = System.now();
        insert evt;
        contact c = new contact();
        c.lastname = 'x';
        c.email = 'qwe@qwe.it';
        insert c;
        EventRelation er = new EventRelation();
        er.relationId = c.Id ;
        er.eventid = evt.Id;
        insert er;
        
        MeetingTokenizerController controller = new MeetingTokenizerController(new ApexPages.StandardController(evt));
        MeetingTokenizerController.isTest = true;
        controller.loadPage();
        
        controller.changeLocation();
        evt.Location = null;
        controller.setLocation();
        
        evt.Location = 'Building 1';
        controller.setLocation();
        
        
        Boolean et = controller.tokens[0].enableToken;
        et = controller.enableTokenRequest;
        controller.tokens[0].loadToken();
        
        controller.sendTokens();
        
        Test.stopTest();
    }
}