public class ApplicationUtil {
    /*
        Method returns JSON token value.
        @params: String jsonString : json String retrieved in HttpResponsebody.
        @params: String token : token for which value needs to be find.
        Method called from : Class ServiceCallout`s static methods.
    */
    public static String getJsonTokenValue(String jsonString,String token){
        String tokenValue = '';
        JSONParser parser = JSON.createParser(jsonString);
        // Advance to the next token.
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                (parser.getText().equalsIgnoreCase(token))) {
                //Get the value.
                parser.nextToken();
                //Print Token Value for debugger.
                tokenValue = parser.getText();
                return tokenValue;
            }
        }
        return tokenValue;
    }
    /*
        Method returns JSON string to set in POST method.
        @Params: Map<String,String> jsonMap : key-value pairs to create JSON fields.
        Method Used from : getAuthenticationToken() method in Class ServiceCallout. to set post method body.
    */
    public static String getJsonBody(Map<String,String> jsonMap){
    
        Set<String> keys = jsonMap.keyset();
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
     
        for(String key : keys ){
            gen.writeStringField(key, jsonMap.get(key));
        }
        gen.writeEndObject();
        String jsonResultString = gen.getAsString();
        return jsonResultString;
    }
    /*
        Method returns dummy HttpResponse object.
        We Use this method for Unit tests as SF does not allow to call Apex Class method which calls webservice endpoints.
        @params: String bodyText : response body in Json format. 
        Method Called from : Class ServiceCallout`s Methods when Unit Tests are running.
    */
    public static HttpResponse getDummyHttpResponse(String bodyText){
        HttpResponse httpResponse = new HttpResponse();
        httpResponse.setStatusCode(200);
        httpResponse.setBody(bodyText);
        return httpResponse;
    }
    /*
        Method returns Html body in string format to send in email.
        @Params : String token : generated meeting token.
        @params : String qrImage : URL of genearated QR code.
        Method Called from :  Class MeetingTokenizerController.
    */
    public static String getHtmlBody(String token,String qrImage){
        String bodyTag = '';
        
        bodyTag += '<table border="0" cellspacing="0" cellpadding="0" width="550" align="center">'+
                    +'<tbody>'+
                    +'<tr>'+
                    +'<td>'+
                    +'<span style="font-size: 15px; color: rgb(74, 74, 84);">Meeting Token from:</span>'+
                    +'<h3 style="border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: rgb(204, 204, 204); font-size: 18px; margin: 3px 0px; padding-bottom: 8px;">'+
                    +UserInfo.getName()+' '+UserInfo.getOrganizationName()+
                    '</h3>'+
                    +'<table border="0" cellspacing="0" cellpadding="0" style="padding: 15px 0px 0px;" width="550">'+
                    +'<p style="margin: 0px; padding: 0px;"/>'+
                    +'<table border="0" cellspacing="0" cellpadding="0" style=" font-size:12px; background-color: rgb(255, 255, 255); color: rgb(74, 74, 84); line-height: 15px; margin: 0px; padding: 10px 20px;" width="100%">'+
                    +'<tbody>'+
                    +'<tr  style="margin: 5px; padding: 5px;">'+
                    +'<td> Meeting Token </td>'+
                    +'<td><b>'+token+'</b></td></tr>';
       
        bodyTag +=  '<tr>'+
                    '<td>QR Image</td>'+
                    '<td>'+
                    '<img border="0" src="'+qrImage+'" alt="QR CODE" width="304" height="228">'+
                    '</td></tr></tbody></table>'; 
                    
        bodyTag +=  '<div align="center">'+
                    '<p style="font-size: 12px;border-top-width: 1px; border-top-style: solid; border-top-color: rgb(204, 204, 204);padding-top: 8px;background-color: rgb(23, 151, 192)">'+
                    'Or click here to download QR Code.'+
                    '<a href="'+
                    qrImage+
                    '" style="color: rgb(255, 255, 255); text-decoration: none;" target="_blank">'+
                    'DOWNLOAD QR CODE'+
                    '</a>'+
                    '</p>'+
                    '<p style="font-size: 11px; margin: 20px 0px;">Do not reply to this email</p>'+
                    '</div></td></tr></tbody></table>';
                                       
        return bodyTag;
    }
    
    /*
    *	Get the locations
    */ 
    public static List<sites> getSites(String jsonResponse){
    	List<sites> locationsList = new List<sites>();
    	// Parse entire JSON response.
    	JSONParser parser = JSON.createParser(jsonResponse);
	    while (parser.nextToken() != null) {
	        // Start at the array of invoices.
	        if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
	            while (parser.nextToken() != null) {
	                // Advance to the start object marker to
	                //  find next invoice statement object.
	                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
	                    // Read entire invoice object, including its array of line items.
	                    sites site = (sites)parser.readValueAs(sites.class);
	                    locationsList.add(site);
	                    // Skip the child start array and start object markers.
	                    parser.skipChildren();
	                }
	            }
	        }
	    }
    	return locationsList;
    }
    
    /*
    *	Get the tokens and Qr code from the response 
    */ 
    public static List<eventIniviteToken> getTokens(String jsonResponse){
    	List<eventIniviteToken> eventTokens = new List<eventIniviteToken>();
    	if (!String.isBlank(jsonResponse)){
    		 EventResponse eInvite = (EventResponse)JSON.deserialize(jsonResponse, EventResponse.class);
    		 for (entryRequestsResponse entryRequest : eInvite.eventInvite.entryRequests){
    		 	eventTokens.add(new eventIniviteToken(entryRequest.identities[0].externalId, entryRequest.tokens[0].data, entryRequest.tokens[0].imageURL));
    		 }
    	}
    	return eventTokens;
    }
    
    /* 
	*  Description : Sort the select option by its label
	*  return 	List<SelectOption>	Sorted options by its label
	*/
	public static List<selectOption> selectOptionSortByLabel(list<selectOption> selectOptionsToSort) {
        if(selectOptionsToSort == null || selectOptionsToSort.size() <= 1){
            return selectOptionsToSort;
        }
        List<SelectOption> lessSelectOption = new List<SelectOption>();
        List<SelectOption> greaterSelectOption = new List<SelectOption>();
        integer pivot = selectOptionsToSort.size() / 2;
        
        //save the pivot and remove it from the selectOption list
        SelectOption pivotValue = selectOptionsToSort[pivot];
        selectOptionsToSort.remove(pivot);
        for(selectOption SO : selectOptionsToSort){
            if(SO.getLabel() <= pivotValue.getLabel()){
                lessSelectOption.add(SO);
            }else if(SO.getLabel() > pivotValue.getLabel()){
                greaterSelectOption.add(SO);   
            }
        }
        
        List<selectOption> sortedSelectOptions = new list<selectOption>(); 
        sortedSelectOptions.addAll(selectOptionSortByLabel(lessSelectOption));
        sortedSelectOptions.add(pivotValue);
        sortedSelectOptions.addAll(selectOptionSortByLabel(greaterSelectOption)); 
        return SortedSelectOptions;
    }  
    
    // Wrapper class for getting location 
    public class sites{
    	public String 				id 				{get; set;}
    	public String 				externalId 		{get; set;}
    	public String  				name			{get; set;}
    	public String 				org_id 			{get; set;}
    	public List<entryPoints>	entryPoints		{get; set;}
    	
    	public sites(String id, String externalId, String name, String org_id, List<entryPoints> entryPoints){
    		this.id = id;
    		this.externalId = externalId;
    		this.name = name;
    		this.org_id = org_id;
    		this.entryPoints = entryPoints;
    	}
    }
    
    public class entryPoints{
    	public String id 			{get; set;}
    	public String externalId 	{get; set;}
    	public String  name			{get; set;}
    	public String description 	{get; set;}
    }
    
    // Wrapper class for creating request
    public class requestForm{
    	public String 					externalId		{get; set;}
    	public List<identitiesRequest> 	identities 		{get; set;}
    	public List<schedulesRequest>	schedules 		{get; set;}
    	public Integer 					siteId 			{get; set;}
    	
    	public requestForm(String externalId, List<identitiesRequest> identities, List<schedulesRequest> schedules, Integer siteId){
    		this.externalId = externalId;
    		this.identities = identities;
    		this.schedules = schedules;
    		this.siteId = siteId;
    	}
    }
    
    public class identitiesRequest{
    	public String 	type 		{get; set;}
    	public String 	id 			{get; set;}
    	
    	public identitiesRequest(String type, String id){
    		this.type = type;
    		this.id = id;
    	}
    }
    
    public class schedulesRequest{
    	public String startDateTime		{get; set;}
    	public String endDateTime		{get; set;}
    	
    	public schedulesRequest(String startDateTime, String endDateTime){
    		this.startDateTime = startDateTime;
    		this.endDateTime = endDateTime;
    	}
    }
    
    // Wrapper class in reponse format
    public class EventResponse{
    	public eventInviteResponse	eventInvite		{get; set;}
    	public EventResponse(eventInviteResponse eventInviteResponse){
    		this.eventInvite = eventInvite;
    	}
    }
   
    public class eventInviteResponse{ 
    	public Integer 							id 					{get; set;}
    	public Integer 							org_id 				{get; set;}
    	public String 							externalId			{get; set;}
    	public List<entryRequestsResponse>		entryRequests		{get; set;}
    }
    
    public class entryRequestsResponse{
    	public Integer 						id 				{get; set;}
    	public String 						name 			{get; set;}
    	public List<identitiesResponse>		identities		{get; set;}
    	public List<tokensResponse>			tokens			{get; set;}
    	public List<schedulesResponse>		schedules		{get; set;}
    	public List<entryPointsResponse>	entryPoints		{get; set;}
    }
    
    public class identitiesResponse{
    	public Integer 		id			{get; set;}
    	public String 		firstName 	{get; set;}
    	public String 		lastName 	{get; set;}
    	public String 		email 		{get; set;}
    	public String 		type 		{get; set;}
    	public String 		externalId 	{get; set;}
    }
    
    public class tokensResponse{
    	public Integer 		id 				{get; set;}
    	public String 		tokenType		{get; set;}
    	public String 		data			{get; set;}
    	public String 		imageURL		{get; set;}
    }
    
    public class schedulesResponse{
    	public Integer 		id 				{get; set;}
    	public String 		name 			{get; set;}
    	public String 		startDateTime	{get; set;}
    	public String 		endDateTime		{get; set;}
    }
    
    public class entryPointsResponse{
    	public Integer 		id 				{get; set;}
    	public String 		externalId 		{get; set;}
    	public String 		name 			{get; set;}
    	public String 		description 	{get; set;}
    	public Integer 		site_id			{get; set;}
    }
    
    
    // Get the event token data from the response
    public class eventIniviteToken{
    	public String recordId 			{get; set;}
    	public String token				{get; set;}
    	public String imageUrl 			{get; set;}
    	
    	public eventIniviteToken(String recordId, String token, String imageUrl){
    		this.recordId = recordId;
    		this.token = token;
    		this.imageUrl = imageUrl;
    	}
    }
}