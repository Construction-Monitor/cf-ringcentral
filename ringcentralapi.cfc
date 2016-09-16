<cfcomponent>
	<cfscript>
	
		function init() {
			//Sandbox keys, not referenced in the checked in version of the code currently
			//Must replace references to variables.authkey to variables.sandboxAuthKey via find/replace
			//Not Ideal, needs to be managed better. Sorry =(
			//Can be found in the Ringcentral developer platform portal
			//TODO Better Namespacing, and getters/setters for all entities, as well as being able to pass it in via the init function
			variables.sandboxAuthKey = "";
			variables.sandboxAuthSecret = "";
			variables.SandboxBaseUrl = "https://platform.devtest.ringcentral.com/restapi/";
			variables.sandboxUsername = "";
			variables.sandboxExtension = "";
			variables.sandboxPassword = "";
			variables.sandboxAccount = "";
			
			//Production keys, or if easier for you, put all sandbox info in
			//Can be found in the Ringcentral developer platform portal
			variables.authKey = "";
			variables.authSecret = "";
			variables.baseUrl = "https://platform.ringcentral.com/restapi/";
			variables.username = "";
			variables.extension = "";
			variables.password = "";
			variables.account = "~";
			return this;
		}
		
		//Authentation Function, used by other functions below to get a valid token.
		//To switch between sandbox and prod, must switch out all variables. to the sandbox
		//TODO: Move all request construction into one method that can handle sandbox vs production dynamically
		//The way the current code is written, it does not handle multiple extensions, without creating additional instances of this CFC
		//Checks for existing auth, hardcoded to 59 minutes, I believe the API lets you specify a duration you want.
		//Only uses password flow auth type.
		function getBearerToken(){
			if( !isDefined("application.ringcentralToken") || dateDiff("n",application.ringcentralToken.dateCreated,now()) > 59 ){
				var httpRequest = new http();
				var body = "grant_type=password&username=#variables.username#&extension=#variables.extension#&password=#variables.password#";
				httpRequest.setUrl(variables.baseUrl & "oauth/token");
				httpRequest.setUsername(variables.authKey);
				httpRequest.setPassword(variables.authSecret);
				httpRequest.setMethod("POST");
				httpRequest.addParam(type="header",name="Content-Type",value="application/x-www-form-urlencoded;charset=UTF-8");
				httpRequest.addParam(type="BODY",value=body);
				var result = httpRequest.send();
				if(result.getPrefix()["statuscode"] == "200 OK"){
					var resultStruct = deserializeJSON(result.getPrefix()["filecontent"]);
					structInsert(resultStruct,"dateCreated",now());
					application.ringcentralToken = resultStruct;
				} else {
					return result;
				}
			}
			return application.ringcentralToken;
		}
		
		//Sample of access call log data, requires a page and a timestamp,
		//we assume timestamp in local and convert to UTC
		//We take care of moving it from Coldfusion formats to something Ringcentral likes
		//Only could that would need to be switched out is variables.baseURL, as the auth info is accessed via getBearerToken()
		//Pages are 1000 records by default, we assume the calling code outside of this will handle paging.
		//In the future, probably better if the code recurses until there's no more pages
		function getPhoneLogs(page=1,startTimestamp){
			//Ensures page is numeric, probably should be handled by typing the function call
			if(!isNumeric(page)){
				return page;
			}
			
			//Hardcoded to prevent pulling logs from older then 30 days.
			//Mainly used to stop a huge sync of data when we implemented it at first
			//We didn't want to go to the beginning of time
			if(dateDiff("d",startTimestamp,now()) > 30){
				startTimestamp = dateAdd("d",-30,now());
			}
			//return maxLogDate;
			//Convert Local to UTC
			var startDateUtc = dateConvert("local2Utc",startTimestamp);
			//Format timezone with more detailed timezone info
			startDateUtc = dateFormat(startDateUtc,"yyyy-mm-dd") & "T" & timeFormat(startDateUtc,"HH:nn:ss.000Z");
			//Fetch the auth info from here
			var token = getBearerToken();
			httpRequest = new http();
			httpRequest.setUrl(variables.baseUrl & "v1.0/account/#variables.account#/call-log");
			//Check the docs for which attributes you can set. We were only using these,
			//so for our simplicity we didn't end up making it more dynamic
			httpRequest.addParam(type="header",name="Authorization",value="#token.token_type# #token.access_token#");
			httpRequest.addParam(type="URL",name="dateFrom",value=startDateUtc);
			httpRequest.addParam(type="URL",name="direction",value="Outbound");
			httpRequest.addParam(type="URL",name="view",value="Simple");
			httpRequest.addParam(type="URL",name="page",value=page);
			var result = httpRequest.send();
			var resultStruct = deserializeJSON(result.getPrefix().filecontent);
			return resultStruct;
		}
		
		
		//Fetches all users
		//We never set up dynamic page setting, because we have less then a thousand users by a huge margin
		function getUserList(){
			var token = getBearerToken();
			httpRequest = new http();
			httpRequest.setUrl(variables.baseUrl & "v1.0/account/#variables.account#/extension");
			httpRequest.addParam(type="header",name="Authorization",value="#token.token_type# #token.access_token#");
			httpRequest.addParam(type="URL",name="page",value=1);
			var result = httpRequest.send();
			var resultStruct = deserializeJSON(result.getPrefix().filecontent);
			return resultStruct;
		}
		
		//Basic SMS construction
		//Phone Numbers are assumed to be in an array of structs that can take a few params, name, etc. But you can just do phone numbers
		//My use case I just wanted to pass in a comma seperated list of phone numbers, so I made the function build the struct
		//The from phone number must be a phone number on that extension, or you can't send an SMS.
		//Super Admin has some flexibility in this as you can text from any phone numbers not directly assigned to users
		//IE main company number, and direct dial for super admin.
		function sendSMS(to,from,text){
			var messageStruct = {};
			var toArray = [];
			if(listlen(to)){
				for(i in to){
					var iStruct = {"phoneNumber"=i};
					arrayAppend(toArray,iStruct);
				}
			}
			messagestruct["to"] = toArray;
			messagestruct["from"]["phoneNumber"] = from;
			messagestruct["text"] = text;
			var messageBody = serializeJSON(messageStruct);
			var token = getBearerToken();
			httpRequest = new http();
			httprequest.setMethod("post");
			httpRequest.setUrl(variables.baseUrl & "v1.0/account/#variables.account#/extension/~/sms");
			httpRequest.addParam(type="header",name="Authorization",value="#token.token_type# #token.access_token#");
			httpRequest.addParam(type="header",name="Content-Type",value="application/json");
			httpRequest.addParam(type="BODY",value=messageBody);
			var result = httpRequest.send();
			var resultStruct = deserializeJSON(result.getPrefix().filecontent);
			return resultStruct;
		}
	</cfscript>

</cfcomponent>