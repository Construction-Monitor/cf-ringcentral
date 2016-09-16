# cf-ringcentral
Coldfusion "wrapper" for working with the RingCentral REST API

Currently not a full fledged wrapper, just shows a basic interaction between Coldfusion and Ringcentral's API.
Needs work to streamline the 

## To Use
- Fill in your API info in the variables sections.
- Fill in sandbox or prod depending on what you are doing.
- If you are using sandbox, the checked in version of the code does not reference it, you will need to replace all variable references

### When you call any of the 3 API calls built:
- getPhoneLogs
- getUserList
- sendSMS
	
It will automatically call the auth endpoint, and create a 60 minute token in the application scope if no token exists
If a token does exist, it'll use that token.
Does not work with multiple extensions as written, but would not be hard to adjust it.
