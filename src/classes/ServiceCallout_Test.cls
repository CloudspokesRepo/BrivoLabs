@isTest
public class ServiceCallout_Test{

    public static testMethod void TestCalloutMethods(){
        String dummyRecId = 'flkksjfbdskjvbhdsjvh';
        ServiceCallout.retrieveAndSaveClientSecret('_test');
        
        String authToken = ServiceCallout.getAuthenticationToken();
        System.assertEquals(authToken,'gsdfbsdgbgnfgnbfgbgb');
        
        String image = ServiceCallout.getQrImageUrl(authToken, dummyRecId);
        System.assertEquals(image,'http://www.mycompany.com/qrcode.jpg');
    }
}