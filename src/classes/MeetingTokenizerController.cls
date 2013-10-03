public with sharing class MeetingTokenizerController {
    //main event
    public Event evt{get;Set;}
    
    //locations got from the API
    public List<SelectOption> locations{get;set;}
    public Map<String, String>	mapLocations {get; set;}
    public Map<String, String>	mapObjectTypes {get; set;}
    public Boolean hasInvitees {get; set;}
    
    //access token
    private String accessToken;
        
    public static boolean isTest{get;set;}
    public List<EventToken> tokens{get;Set;}
    /*
        Page Controller Constructor
    */    
    public MeetingTokenizerController(ApexPages.StandardController controller){
        isTest = false;
        this.evt = [Select Id, OwnerId, Location, VMS_zone__c, EndDateTime, StartDateTime, IsChild, IsGroupEvent, Subject From Event Where Id = :controller.getId()];        
        this.locations = new List<SelectOption>();
        this.tokens = new List<EventToken>();
        mapLocations = new Map<String, String>();
        hasInvitees = true;
        mapObjectTypes = new Map<String, String>{ 	'005'	=>  'User',
        											'ooq'	=>	'Lead',
        											'003'	=>	'Contact'
        										};
    }
    
    //helper object to select a given person
    public class EventToken{
        /*
            Wrapper Class Constructor.
        */
        public EventToken(EventRelation relation, Boolean isSelected, String objectType, String recordId){
            this.relation = relation;
            this.isSelected = isSelected;
            this.objectType = objectType;
            this.recordId = recordId;
        }
        public boolean enableToken{
            get{
                return this.relation.Status == 'New' || this.relation.Status == 'Accepted';
            }
        }
        public EventRelation relation {get;set;}
        public String 	   recordId {get; set;}
        public Boolean isSelected{get;set;}
        public String token{get;set;}
        public String errorMessage{get;set;}
        public String objectType {get; set;}
        public String imageUrl{get;set;}

    } 
    
    public void loadPage(){
    	List<EventRelation> relations = [Select Id, RelationId, Relation.Name, Status From EventRelation 
                                            Where EventId = :this.evt.Id order by Relation.Name];
                                            
        if (relations.isEmpty()){
        	hasInvitees = false;
        }else{
	        //simulated locations API call
	        this.locations = ServiceCallout.getSites();  
	        
	        for (SelectOption option : locations){
	        	mapLocations.put(option.getValue().toLowerCase(), option.getLabel().toLowerCase());
	        }  
	                
	        //load all relations
	        for(EventRelation er : relations){ 
	            this.tokens.add(new EventToken(er,er.Status == 'Accepted' || er.Status == 'New', mapObjectTypes.get(String.valueOf(er.RelationId).subString(0,3).toLowerCase()), String.valueOf(er.RelationId)));
	        }
	        
	        //Whenever Page loads get Auth-Token from /oauth/token endpoint.
	        if(!Test.isRunningTest()){
	            //Set Authentication token on page load in ServiceCallout`s static variable for further use.
	            system.debug('getting auth token...');
	            this.accessToken = ServiceCallout.getAuthenticationToken();
	
	        }
        }
    }
    
    /*
    *	Get the token and image url in a single api call
    */ 
    public void GenerateTokens(){ 
        List<ApplicationUtil.identitiesRequest> identitiesList = new List<ApplicationUtil.identitiesRequest>();
        List<ApplicationUtil.schedulesRequest>	 schedulesList = new List<ApplicationUtil.schedulesRequest>();
        
        // loop through event invitees
        if (!this.tokens.isEmpty()){
        	for (EventToken et : this.tokens){
        		if(et.isSelected==false ) continue; 
        		if(et.isSelected && String.isBlank(et.token)){
        			identitiesList.add(new ApplicationUtil.identitiesRequest(et.objectType, et.relation.RelationId));
        			schedulesList.add(new ApplicationUtil.schedulesRequest(String.valueOf(evt.StartDateTime), String.valueOf(evt.EndDateTime)));
        		}
        	}
        }
        
        String reqJson = JSON.serialize(new ApplicationUtil.requestForm(String.valueOf(Math.random()), identitiesList, schedulesList, Integer.valueOf(this.evt.VMS_zone__c)));  
        List<ApplicationUtil.eventIniviteToken> eventTokens = ServiceCallout.getQrImageUrl(reqJson);
        
        // Loop throguh event token and assign the token and imageUrl
        if (!this.tokens.isEmpty()){
        	for (EventToken et : this.tokens){
        		if(et.isSelected==false ) continue; 
        		if(et.isSelected && String.isBlank(et.token)){
        			for (ApplicationUtil.eventIniviteToken inviteToken : eventTokens){
        				if (inviteToken.recordId == et.recordId){
        					et.token = inviteToken.token;
        					et.imageUrl = inviteToken.imageUrl;
        				}
        			}
        		}
        	}
        }
        
        try{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.CONFIRM,'Tokens generated successfully.'));
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR,'Error occurred: '+e.getMessage()));
        }
    }
    
    /*
    *	Used to send an email
    */
    public void sendEmails(){
    	List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(EventToken et : this.tokens){
            if(et.isSelected==false ) continue;
            if(et.isSelected && String.isBlank(et.token)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR,'Token of person "'+et.relation.Relation.Name+'" is null.'));
                return;
            }
            String emailHtmlBody = ApplicationUtil.getHtmlBody(et.token,et.imageUrl);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(et.relation.RelationId);
            mail.setSubject('Event "'+this.evt.Subject+'" Token with QR code.');
            mail.setHtmlBody(emailHtmlBody);
            mail.setSaveAsActivity(false);
            emails.add(mail);
        }
        
        if(emails.size()==0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR,'Select at least 1 person with token.'));
            return;
        }
        
        try{
            Messaging.sendEmail(emails, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.INFO,'Tokens & QR Code sent.'));
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR,'Error occurred: '+e.getMessage()));
        }
    }
    
    public void setLocation(){
        if(String.isBlank(this.evt.VMS_zone__c)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR,'Select a location.'));
            return;
        }
        update this.evt;
    }
    
    
    public void changeLocation(){
        this.evt.VMS_zone__c = null;
        update this.evt;
    }

    
    public boolean enableTokenRequest{
            get{
                return this.evt.OwnerId == UserInfo.getUserId() && this.evt.IsGroupEvent == true && this.evt.isChild == false;
            }
    }
}