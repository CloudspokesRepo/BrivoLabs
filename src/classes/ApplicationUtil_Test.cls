@isTest
public class ApplicationUtil_Test{

    public static testMethod void increaseCoverage(){
        Map<String,String> jsonMap = new Map<String,String>();
        jsonMap.put('grant_type', 'password');
        jsonMap.put('username', 'somebody');
        jsonMap.put('password', 'nevermind');
        String jsonStr= ApplicationUtil.getJsonBody(jsonMap);
        System.assertNotEquals(jsonStr,'');
        
        String value = ApplicationUtil.getJsonTokenValue(jsonStr,'id');
        value = ApplicationUtil.getJsonTokenValue(jsonStr,'grant_type');
        System.assertEquals(value,'password');
    }
}