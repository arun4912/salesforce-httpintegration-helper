public without sharing class IntegrationUtility {
	static final String CLASS_NAME = 'IntegrationUtility';
	static final String METHOD_NAME = 'performHttpCallout';
	public static Integer timeout;

	Public class IntegrationException extends Exception {}

	public static HttpResponse performHttpCallout(string requestParms, String serviceName){
		return performHttpCallout(requestParms, serviceName, 200, 299);
	}

	public static HttpResponse performHttpCallout(string requestParms, String serviceName, Integer responseOkLow, Integer responseOkHigh) {
		return performHttpCallout(requestParms, serviceName, responseOkLow, responseOkHigh, true);
	}

	public static HttpResponse performHttpCallout(string requestParms, String serviceName, Integer responseOkLow, Integer responseOkHigh, Boolean loggingOn) {
		return performHttpCallout(requestParms, serviceName, responseOkLow, responseOkHigh, true, false);
	}

	public static HttpResponse performHttpCallout(string requestParms, String serviceName, Boolean containsHCData){
		return performHttpCallout(requestParms, serviceName, 200, 299, true, containsHCData);
	}

	public static HttpResponse performHttpCallout(string requestParms, String serviceName, Integer responseOkLow, Integer responseOkHigh, Boolean loggingOn, Boolean containsHCData) {
		return performHttpCallout(null, requestParms, serviceName, responseOkLow, responseOkHigh, loggingOn, containsHCData);
	}

	public static HttpResponse performHttpCallout(Map<string,string> requestHeaderParams,string requestParms, String serviceName, Integer responseOkLow, Integer responseOkHigh, Boolean loggingOn, Boolean containsHCData) {
		Http http = new Http();
		HttpResponse response;
		HttpRequest request = new HttpRequest();
		if(timeout != null){
			request.setTimeout(timeout);
		}
		try {
			request = IntegrationHelper.getHttpEndPointUrl(request, serviceName);
			if(!String.isBlank(requestParms)){
				request.setBody(requestParms);
			}
			request = setRequestHeaderParams(request,requestHeaderParams);
			response = http.send(request);
			if (response != null && response.getStatusCode() >= responseOkLow && response.getStatusCode() <= responseOkHigh) {
				// SUCCESSful response
				return response;
			} else {
				throw new IntegrationException();
			}
		} catch(Exception e) {
			System.debug(LoggingLevel.ERROR, '***Integration Exception caught.');
			String errorMessage = e.getStackTraceString();
			errorMessage += '\n User: ' + UserInfo.getUserId() + ' | ' + UserInfo.getName();
			if (response != null) {
				errorMessage = errorMessage + ' *** Status Code '+ response.getStatusCode()+' '+response.getBody();
			}
			if (loggingOn){
				Map<String, String> ieValues = new Map<String, String>{
					'summary'=>'Integration Utility callout to ' + serviceName,
					'message'=>errorMessage,
					'endPoint'=>request.getEndpoint(),
					'type'=>request.getMethod(),
					'details'=>(String.isBlank(request.getBody()))?
						'Request body is null.':
						request.getBody(),
					'serviceName'=>serviceName,
					'Http_Code_Status__c'=>String.valueOf(response != null ? response.getStatusCode() : null)
				};
				logIntegrationErr(ieValues, containsHCData);
			}
			throw new IntegrationException(errorMessage, e);
		}
	}

	public static HttpRequest setRequestHeaderParams(HttpRequest request, Map<String,String> requestHeaderParams){
		if(requestHeaderParams!= null && !requestHeaderParams.isEmpty()){
			for(String headerName :requestHeaderParams.keySet()){
				request.setheader(headerName,requestHeaderParams.get(headerName));
			}
		}
		return request;
	}

	public static Boolean validateRequestType (String serviceName) {
		// Simplified - no Integration_Error__c dependency in this org
		return true;
	}

	public static void logIntegrationErr(Map<String, String> paramMap) {
		logIntegrationErr(paramMap, false);
	}

	public static void logIntegrationErr(Map<String, String> paramMap, Boolean containsHCData) {
///NEBULA LOGGER
		String serviceName = paramMap.get('serviceName');

		try {
			String httpCodeString = paramMap.get('Http_Code_Status__c');
			Integer httpCodeStatus = (!String.isBlank(httpCodeString) && httpCodeString != 'null' && httpCodeString.isNumeric()) ?
				Integer.valueOf(paramMap.get('Http_Code_Status__c')):
				null;

			// Log to debug - platform event Integration_Exception__e not available in this org
			System.debug(LoggingLevel.ERROR, 'Integration Error - Summary: ' + paramMap.get('summary'));
			System.debug(LoggingLevel.ERROR, 'Integration Error - Message: ' + paramMap.get('message'));
			System.debug(LoggingLevel.ERROR, 'Integration Error - Endpoint: ' + paramMap.get('endPoint'));
			System.debug(LoggingLevel.ERROR, 'Integration Error - Method: ' + paramMap.get('type'));
			System.debug(LoggingLevel.ERROR, 'Integration Error - Service: ' + serviceName + ' | HTTP Status: ' + httpCodeStatus);

		} catch (Exception ex) {
			System.debug(LoggingLevel.ERROR, CLASS_NAME + '.' + METHOD_NAME + ': ' + ex.getMessage());
			System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
		}
	}
}
