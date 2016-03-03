<cfcomponent>
	<cfscript>
	
		function init() {
			variables.sandboxAuthKey = "";
			variables.sandboxAuthSecret = "";
			variables.SandboxBaseUrl = "https://platform.devtest.ringcentral.com/restapi/";
			variables.sandboxUsername = "";
			variables.sandboxExtension = "";
			variables.sandboxPassword = "";
			variables.sandboxAccount = "";
			
			variables.authKey = "";
			variables.authSecret = "";
			variables.baseUrl = "https://platform.ringcentral.com/restapi/";
			variables.username = "";
			variables.extension = "";
			variables.password = "";
			variables.account = "~";
			return this;
		}
		
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
		
		function getPhoneLogs(page=1,startTimestamp){
			if(!isNumeric(page)){
				return page;
			}
			
			if(dateDiff("d",startTimestamp,now()) > 30){
				startTimestamp = dateAdd("d",-30,now());
			}
			//return maxLogDate;
			var startDateUtc = dateConvert("local2Utc",startTimestamp);
			startDateUtc = dateFormat(startDateUtc,"yyyy-mm-dd") & "T" & timeFormat(startDateUtc,"HH:nn:ss.000Z");
			var token = getBearerToken();
			httpRequest = new http();
			httpRequest.setUrl(variables.baseUrl & "v1.0/account/#variables.account#/call-log");
			httpRequest.addParam(type="header",name="Authorization",value="#token.token_type# #token.access_token#");
			httpRequest.addParam(type="URL",name="dateFrom",value=startDateUtc);
			httpRequest.addParam(type="URL",name="direction",value="Outbound");
			httpRequest.addParam(type="URL",name="view",value="Simple");
			httpRequest.addParam(type="URL",name="page",value=page);
			var result = httpRequest.send();
			var resultStruct = deserializeJSON(result.getPrefix().filecontent);
			return resultStruct;
		}
		
		
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