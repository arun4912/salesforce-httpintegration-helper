/*****************************************************************************************************************************************************************************************
  @description: To set end point urls, methods, content-type, authentication, headers, static values etc
****************************************************************************************************************************************************************************************/
public without sharing class IntegrationHelper {

	//company profile details
	public static Organization oObject;

	//Loggined user details
	public static User uObject;

	//Map to store integration service name and endpoint urls
	public static Map<String, Integration_Setting__mdt> SettingsMap;

	//Endpoint URL
	public static string endpointUrl;


	/**********************************************************
		Query Loggined user details
	***********************************************************/
	public static user getCurrentUser(){
		return [SELECT Id, FederationIdentifier, Name FROM User WHERE Id = :UserInfo.getUserId()];
	}

	/**********************************************************
		Query Organization deatils to find whether org is sandbox or production
	***********************************************************/
	public static Organization getOrganizationDetails(){
		return [SELECT IsSandbox FROM Organization LIMIT 1];
	}

	/******************************************************************************************************************
		Get Endpoint URL
	*******************************************************************************************************************/
	public static string getEndURL(String webserviceName){
		return getEndpointUrl(webserviceName);
	}

	/****************************************************************************************************************
		Get endpoint URL from Integration Setting custom metadata
	 ***************************************************************************************************************/
	public static string getEndpointUrl(String webserviceName){
		if(oObject == null){
			oObject = getOrganizationDetails();
		}
		if(SettingsMap == null){
			setStaticHeaderValues();
		}
		Integration_Setting__mdt isObj = SettingsMap.containsKey(webserviceName) ?
			SettingsMap.get(webserviceName) :
			null;
		if(isObj != null && String.isNotBlank(isObj.Webservice_URL__c)){
			return isObj.Webservice_URL__c;
		}
		return '';
	}

	/**********************************************************
		Get all avialable webservices (headers and static values) and add them to a map
	***********************************************************/
	public static void setStaticHeaderValues(){
		//Map to hold webserviceName , custom metadata object
		SettingsMap = new Map<String, Integration_Setting__mdt>();
		//Query Webservice Name , headers and static values
		List<Integration_Setting__mdt> settingsList = [
			SELECT Id, DeveloperName, Name__c, Method__c, Session_Timeout__c, Target_System__c, Webservice_URL__c,
			(SELECT Id, DeveloperName, Integration_Setting__c, Key__c, Type__c, Value__c FROM Integration_Setting_Details__r WHERE Active__c = true)
			FROM Integration_Setting__mdt
			WHERE Active__c = true
			ORDER BY DeveloperName
		];
		//Add Integration Settings to a Map
		for(Integration_Setting__mdt settingObj : settingsList){
			SettingsMap.put(settingObj.DeveloperName, settingObj);
		}
	}

	/**********************************************************
		Get endpoint URL, headers and static(parameters) values related to a specific webservice and assign them for HttpRequest object
	***********************************************************/
	public static HttpRequest getHttpEndPointUrl(HttpRequest reqObject, string webserviceName){

		if(oObject == null){
			oObject = getOrganizationDetails();
		}

		if(SettingsMap == null){
			setStaticHeaderValues();
		}

		//Get endpoint url
		endpointUrl = getEndURL(webserviceName);
		//Get headers and static values
		HttpRequest updatedReqObject = SetHttpRequestMethods(reqObject , webserviceName);

		//Set endPoint to HttpRequest
		updatedReqObject.setEndpoint(endpointUrl);
		//return HttpRequest object
		return updatedReqObject;
	}

	/**********************************************************
		Get Method values related to a specific webservice and assign them for HttpRequest object
	***********************************************************/

	public static HttpRequest SetHttpRequestMethods(HttpRequest reqObject , string webserviceName){

		//Logic to get headers and static values for the webservice
		Integration_Setting__mdt isObj = null;

		//Logic to set Endpoint url, method , certificate , session time out, content-type etc
		if(SettingsMap != null && SettingsMap.size() > 0 && SettingsMap.containsKey(webserviceName)){

			isObj = SettingsMap.get(webserviceName);
			if(isObj != null){

				//add Webservice name/path to endpoint URL if Name__c is used as path suffix
				if(String.isNotBlank(isObj.Name__c) && String.isNotBlank(endpointUrl) && !endpointUrl.endsWith('/')){
					endpointUrl = endpointUrl + '/' + isObj.Name__c;
				} else if(String.isNotBlank(isObj.Name__c) && String.isNotBlank(endpointUrl)){
					endpointUrl = endpointUrl + isObj.Name__c;
				}

				//Logic to add setMethod (Like GET, POST, DELETE etc)
				if(isObj.Method__c != null){
					reqObject.setMethod(isObj.Method__c);
				}

				//Set session timeout
				if(isObj.Session_Timeout__c != null){
					reqObject.setTimeout((Integer)isObj.Session_Timeout__c);
				}

				//Logic to get Headers and static values from custom metadata
				if(isObj.Integration_Setting_Details__r != null && isObj.Integration_Setting_Details__r.size() > 0){
					reqObject = setHttpRequestHeaders(reqObject, isObj.Integration_Setting_Details__r, isObj.Method__c);
				}
			}

		}
		return reqObject;


	}

	/**********************************************************
		Get headers and static(query parameters) values related to a specific webservice and assign them for HttpRequest object
	***********************************************************/
	public static HttpRequest setHttpRequestHeaders(HttpRequest reqObject , List<Integration_Setting_Detail__mdt> headerStaticList, string methodType){

		Integer StaticCount = 0;
		for(Integration_Setting_Detail__mdt headerObj : headerStaticList){
			//If type is Header add it to HttpRequest header
			if(headerObj.Type__c == 'Header'){
				reqObject.setHeader(headerObj.Key__c, String.isBlank(headerObj.Value__c) ? '' : headerObj.Value__c);
			}
			//If type is Static and method is GET, add parameters to the endpoint URL
			else if(headerObj.Type__c == 'Static' && methodType != null && methodType.toUpperCase() == 'GET' && headerObj.Value__c != null && headerObj.Value__c != ''){

				StaticCount++;
				if(StaticCount == 1){
					endpointUrl = endpointUrl + '?'+ headerObj.Key__c + '=' + headerObj.Value__c;
				}
				else{
					endpointUrl = endpointUrl + '&' + headerObj.Key__c + '=' + headerObj.Value__c ;
				}
			}
		}

		return reqObject;

	}

	/**********************************************************
		Get static values related to a specific webservice and add it to HttpRequest body
	***********************************************************/

	public static String setStaticvaluestoPostMethod(string webserviceName){

		String jsonString = ' { ';
		//Logic to get headers and static values for the webservice
		Integration_Setting__mdt isObj = null;
		//Logic to set Endpoint url, method , certificate , session time out, content-type etc
		if(SettingsMap != null && SettingsMap.size() > 0 && SettingsMap.containsKey(webserviceName)){
			isObj = SettingsMap.get(webserviceName);
			System.debug('***Custom metadata***'+isObj);
			if(isObj != null && isObj.Integration_Setting_Details__r != null){
				for(Integration_Setting_Detail__mdt staticObj : isObj.Integration_Setting_Details__r){
					if(staticObj.Type__c == 'Static'){
						jsonString = jsonString + '\"' + staticObj.Key__c + '\" : \"' + staticObj.Value__c +'\" , ';
					}
				}
			}
		}

		system.debug('****json string length'+jsonString.length());
		jsonString = jsonString.removeEnd(' , ');
		jsonString = jsonString + ' } ';
		system.debug('****json string'+jsonString);

		return jsonString;

	}


}
