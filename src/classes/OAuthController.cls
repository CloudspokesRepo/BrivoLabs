public with sharing class OAuthController {
	
	public PageReference OAuthCallback(){
		ServiceCallout.retrieveAndSaveClientSecret(String.valueOf(Math.random()));
		
		try{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Got the brivo labs oauth credentials sucessfully.'));
		}catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Error occured :'+ex.getMessage()));
		}
		
		return null;
	}
}