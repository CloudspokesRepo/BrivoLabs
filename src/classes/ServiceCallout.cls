global class ServiceCallout{
    private static String DEFAULT_URL = 'http://pi-api-dev.herokuapp.com';
    private static String endPointUrl = ''; 
    public static String TOKEN_TYPE = '';
    public static String QR_IMG_URL = '';
    
    /*
        This method calls '/clients' endpoint, Fetches Client Secret & ID.
        Method Saves Client Secret & ID in Custom settings.
        Method is not called anywhere from code because we call this method from SF anomymous window,
        so that user can set Client secret & Id without using POSTMAN extension.
        
        @name param : Salesforce Organization Id is used for Name parameter in /clients callout.
    */
    public static void retrieveAndSaveClientSecret(String clientSuffix) {
        String errorMessage = '';
        String clientSecret = '';
        String clientId     = '';
        String clientName   = '';
        
        //get Url from custom settings
        Brivo_Labs_SAM_Connection_Settings__c customSetting = Brivo_Labs_SAM_Connection_Settings__c.getOrgDefaults(); 
        endPointUrl = customSetting.Server_Url__c;
        
        //set default url if not defined in Custom settings.
        if(endPointUrl == null){
            endPointUrl = DEFAULT_URL;    
        }
        //service to callout
        endPointUrl = endPointUrl + ApplicationConstants.CLIENT_ENDPOINT;
        
        // Instantiate a new http object
        Http h = new Http();
        
        //Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPointUrl);
        req.setHeader('Accept-Version',ApplicationConstants.ACCEPT_VERSION);
        req.setHeader('backdoor',ApplicationConstants.BACKDOOR);
        req.setMethod(ApplicationConstants.HTTPPOST);
        req.setBody('name='+Userinfo.getOrganizationId()+'_'+clientSuffix+'&redirectUrl=dummyUrl');
        
        //Send the request, and return a response
         HttpResponse res;
        if(!Test.isRunningTest()){
            res = h.send(req);
        }else{
             //Call to get dummy HttpResponse for Unit Test Running.
            Map<String,String> responseMap = new Map<string,String>();
            responseMap.put('secret','252rsdsfsas2rwdfs');
            responseMap.put('id','3');
            responseMap.put('name','fake');
            String s = ApplicationUtil.getJsonBody(responseMap);
            res = ApplicationUtil.getDummyHttpResponse(s);
        }
        String body = res.getBody();
        
        System.debug(System.LoggingLevel.INFO,'Response body '+body);
        
        //Retrieve Client Secret & Id from Json Response.   
        clientSecret = ApplicationUtil.getJsonTokenValue(body,ApplicationConstants.CLIENT_SECRET);
        clientName   = ApplicationUtil.getJsonTokenValue(body,ApplicationConstants.CLIENT_NAME);
        clientId     = ApplicationUtil.getJsonTokenValue(body,ApplicationConstants.CLIENT_ID);
        errorMessage = ApplicationUtil.getJsonTokenValue(body,'message');
        
        System.debug(System.LoggingLevel.INFO,'Client Secret: '+clientSecret+' Client Name: '+clientId+' Message: '+errorMessage);
        
        //If called twice from anonymous window,do not call DML to update custom settings. 
        if(errorMessage.equals('')){
            //Save Client secret & Id in custom settings.
            customSetting.Server_Url__c = DEFAULT_URL;
            customSetting.Client_Secret_Key__c = clientSecret;
            customSetting.Client_Id__c = clientId;
            customSetting.Client_Name__c = clientName;
            upsert customSetting;
        }
    }
    /*
        This method calls '/oauth/token' endpoint, Fetches access token for further calls.
        Method Returns access token
    */
    public static String getAuthenticationToken(){
        //Get Client Secret & Id From Custom Settings.
        Brivo_Labs_SAM_Connection_Settings__c customSetting = Brivo_Labs_SAM_Connection_Settings__c.getOrgDefaults(); 
        String username = customSetting.Client_Name__c;
        String password = customSetting.Client_Secret_key__c;
        
        endPointUrl = customSetting.Server_Url__c;
        //set default url if not defined in Custom settings.
        if(endPointUrl == null){
            endPointUrl = DEFAULT_URL;    
        }
        //complete URL to callout
        endPointUrl = endPointUrl + ApplicationConstants.OAUTH_TOKEN;
     
        // Instantiate a new http object
        Http h = new Http();  
        Blob headerValue = Blob.valueOf(username +':'+ password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        
        //Build Map to get JSON Body for POST.
        Map<String,String> jsonMap = new Map<String,String>();
        jsonMap.put('grant_type', 'password');
        jsonMap.put('username', UserInfo.getUserName());
        jsonMap.put('password', 'nevermind');
        jsonMap.put('orgId', '1'); //UserInfo.getOrganizationId()
        String body = ApplicationUtil.getJsonBody(jsonMap); 
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPointUrl);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Content-Length',String.valueof(body.length()));
        req.setHeader('Authorization', authorizationHeader);
        req.setMethod(ApplicationConstants.HTTPPOST);
        req.setBody(body);
        
        
        //Send the request, and return a response
        HttpResponse res;
        if(!Test.isRunningTest()){
            res = h.send(req);
        }else{
            //Call to get dummy HttpResponse for Unit Test Running.
            Map<String,String> responseMap = new Map<string,String>();
            responseMap.put('access_token','gsdfbsdgbgnfgnbfgbgb');
            responseMap.put('token_type','Bearer');
            String s = ApplicationUtil.getJsonBody(responseMap);
            res = ApplicationUtil.getDummyHttpResponse(s);
        }
        String resBody = res.getBody();
        
        //Call JSON parser & get Token values.
        TOKEN_TYPE = ApplicationUtil.getJsonTokenValue(resBody,ApplicationConstants.TOKEN_TYPE);
        
        return ApplicationUtil.getJsonTokenValue(resBody,ApplicationConstants.ACCESS_TOKEN);
    }
    public static List<ApplicationUtil.eventIniviteToken> getQrImageUrl(String reqJson){
        //get Url from custom settings
        Brivo_Labs_SAM_Connection_Settings__c customSetting = Brivo_Labs_SAM_Connection_Settings__c.getOrgDefaults(); 
        endPointUrl = customSetting.Server_Url__c;
        
        //set default url if not defined in Custom settings.
        if(endPointUrl == null){
            endPointUrl = DEFAULT_URL;    
        }
        //service to callout
        endPointUrl = endPointUrl + ApplicationConstants.QR_CODE;
        // Instantiate a new http object
        Http h = new Http();
        
        //Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPointUrl);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept-Version', ApplicationConstants.ACCEPT_VERSION);
        req.setHeader('Authorization', 'Bearer ' + getAuthenticationToken());
        req.setMethod(ApplicationConstants.HTTPPOST);
        req.setBody(reqJson);
        
        //Send the request, and return a response
        HttpResponse res;
        if(!Test.isRunningTest()){
            res = h.send(req);
        }else{
             //Call to get dummy HttpResponse for Unit Test Running.
            Map<String,String> responseMap = new Map<string,String>();
            responseMap.put('location','http://www.mycompany.com/qrcode.jpg');
            String s = ApplicationUtil.getJsonBody(responseMap);
            res = ApplicationUtil.getDummyHttpResponse(s);
        }
        //Call JSON parser & get Token values.
        List<ApplicationUtil.eventIniviteToken> eventTokens = ApplicationUtil.getTokens(res.getBody());
        return eventTokens;
    }
    
    public static List<SelectOption> getSites(){
    	List<SelectOption> locations = new List<SelectOption>();
    	// Get the endpoint url
    	Brivo_Labs_SAM_Connection_Settings__c customSetting = Brivo_Labs_SAM_Connection_Settings__c.getOrgDefaults(); 
        endPointUrl = customSetting.Server_Url__c;
        
        //set default url if not defined in Custom settings.
        if(endPointUrl == null){
            endPointUrl = DEFAULT_URL;    
        }
        //service to callout
        endPointUrl = endPointUrl + ApplicationConstants.SITES;
        
        // Instantiate the request
    	HttpRequest req = new HttpRequest();
    	req.setEndpoint(endPointUrl);
    	req.setHeader('Accept-Version', ApplicationConstants.ACCEPT_VERSION);
		req.setHeader('Authorization', 'Bearer ' + getAuthenticationToken());
		req.setMethod(ApplicationConstants.HTTPGET);
		HttpResponse res = new Http().send(req);
		
		List<ApplicationUtil.sites> locationsList = ApplicationUtil.getSites(res.getBody());
		// Get the location
		if (!locationsList.isEmpty()){
			for (ApplicationUtil.sites location : locationsList){
				locations.add(new SelectOption(location.id, location.name));
			}
		}
		return ApplicationUtil.selectOptionSortByLabel(locations); 
    }
}