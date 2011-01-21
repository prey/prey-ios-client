//
//  RestHttpUser.m
//  prey-installer-cocoa
//
//  Created by Carlos Yaconi on 18-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//
//

#import "PreyRestHttp.h"
#import "KeyParserDelegate.h"
#import "ErrorParserDelegate.h"
#import "ConfigParserDelegate.h"
#import "PreyConfig.h"


@implementation PreyRestHttp

@synthesize responseData;
@synthesize baseURL;




- (NSString *) getCurrentControlPanelApiKey: (User *) user
{
	
	NSURL *url = [NSURL URLWithString:[PREY_SECURE_URL stringByAppendingFormat: @"profile.xml"]];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request addRequestHeader:@"User-Agent" value:PREY_USER_AGENT];
	[request setUsername:[user email]];
	[request setPassword: [user password]];
	[request setUseSessionPersistence:NO];
	[request setShouldRedirect:NO];
	[request setValidatesSecureCertificate:NO];
	
	@try {
		[request startSynchronous];
		NSError *error = [request error];
		int statusCode = [request responseStatusCode];
		//NSString *statusMessage = [request responseStatusMessage];
		NSString *response = [request responseString];
		LogMessageCompat(@"GET profile.xml: %@",response);
		if (statusCode == 401){
			NSString *errorMessage = NSLocalizedString(@"There was a problem getting your account information. Please make sure the email address you entered is valid, as well as your password.",nil);
			@throw [NSException exceptionWithName:@"GetApiKeyException" reason:errorMessage userInfo:nil];
		}
		
		if (!error) {	
			
			KeyParserDelegate *keyParser = [[KeyParserDelegate alloc] init];
			NSString *key = [keyParser parseKey:[request responseData] parseError:&error];
			return key;
		}	
		else {
			@throw [NSException exceptionWithName:@"GetApiKeyException" reason:[error localizedDescription] userInfo:nil];
		}
		
		
	}
	@catch (NSException * e) {
		@throw;
	}
	return nil;
}


- (NSString *) createApiKey: (User *) user
{
	NSURL *url = [NSURL URLWithString:[PREY_SECURE_URL stringByAppendingFormat: @"users.xml"]];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setRequestMethod:@"POST"];
	[request addRequestHeader:@"User-Agent" value:PREY_USER_AGENT];
	[request setUseSessionPersistence:NO];
	[request setShouldRedirect:NO];
	[request setValidatesSecureCertificate:NO];
	[request setPostValue:[user name] forKey:@"user[name]"];
	[request setPostValue:[user email] forKey:@"user[email]"];
	[request setPostValue:[user country] forKey:@"user[country_name]"]; 
	[request setPostValue:[user password] forKey:@"user[password]"];
	[request setPostValue:[user repassword] forKey:@"user[password_confirmation]"];
	[request setPostValue:@"" forKey:@"user[referer_user_id]"];
	
	@try {
		[request startSynchronous];
		NSError *error = [request error];
		if (!error) {
			int statusCode = [request responseStatusCode];
			//NSString *statusMessage = [request responseStatusMessage];
			//NSString *response = [request responseString];
			if (statusCode != 201){
				NSString *errorMessage = [self getErrorMessageFromXML:[request responseData]];
				@throw [NSException exceptionWithName:@"CreateApiKeyException" reason:errorMessage userInfo:nil];
			}
				
			
			KeyParserDelegate *keyParser = [[KeyParserDelegate alloc] init];
			NSString *key = [keyParser parseKey:[request responseData] parseError:&error];
			return key;
		}	
		else {
			@throw [NSException exceptionWithName:@"CreateApiKeyException" reason:[error localizedDescription] userInfo:nil];
			
		}
	}
	@catch (NSException * e) {
		@throw;
	}
	
	return nil;
}

- (NSString *) createDeviceKeyForDevice: (Device *) device usingApiKey: (NSString *) apiKey {
	
	NSURL *url = [NSURL URLWithString:[PREY_URL stringByAppendingFormat: @"devices.xml"]];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setUsername:apiKey];
	[request setPassword: @"x"];
	[request setRequestMethod:@"POST"];
	[request addRequestHeader:@"User-Agent" value:PREY_USER_AGENT];
	//do shell script "curl -i -A '" & userAgent & "' -d 'api_key=" & wsapikey & "&device[title]=" & wsdevname & "&device[device_type]=" & devType & "&device[os_version]=" & osname & "&device[os]=Mac&device[state]=OK&device[physical_address]=" & mac_addr & "' http://" & wsserver & "/devices.xml > /tmp/prey/to_parse.xml"
	
	[request setPostValue:[device name] forKey:@"device[title]"];
	[request setPostValue:[device type] forKey:@"device[device_type]"];
	[request setPostValue:[device version] forKey:@"device[os_version]"];
	[request setPostValue:[device os] forKey:@"device[os]"];
	[request setPostValue:@"OK" forKey:@"device[state]"];
	[request setPostValue:[device macAddress] forKey:@"device[physical_address]"];
	
	
	[request setUseSessionPersistence:NO];
	[request setShouldRedirect:NO];
	
	@try {
		[request startSynchronous];
		NSError *error = [request error];
		if (!error) {
			int statusCode = [request responseStatusCode];
			if (statusCode == 302)
				@throw [NSException exceptionWithName:@"NoMoreDevicesAllowed" reason:NSLocalizedString(@"It seems you've reached your limit for devices on the Control Panel. Try removing this device from your account if you had already added.",nil) userInfo:nil];
			
			//NSString *statusMessage = [request responseStatusMessage];
			NSString *response = [request responseString];
			LogMessageCompat(@"POST devices.xml: %@",response);
			KeyParserDelegate *keyParser = [[KeyParserDelegate alloc] init];
			NSString *deviceKey = [keyParser parseKey:[request responseData] parseError:&error];
			return deviceKey;
		}	
		else {
			@throw [NSException exceptionWithName:@"CreateDeviceKeyException" reason:[error localizedDescription] userInfo:nil];
			
		} 
	} 
	@catch (NSException *e) {
		@throw;
	}
	
	return nil;
	
}

- (DeviceModulesConfig *) getXMLforUser: (NSString *) apiKey device:(NSString *) deviceKey;
{
	
	NSURL *url = [NSURL URLWithString:[PREY_URL stringByAppendingFormat: @"devices/%@.xml", deviceKey]];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request addRequestHeader:@"User-Agent" value:PREY_USER_AGENT];
	[request setUsername:apiKey];
	[request setPassword: @"x"];
	[request setUseSessionPersistence:NO];
	[request setShouldRedirect:NO];
	
	@try {
		[request startSynchronous];
		NSError *error = [request error];
		int statusCode = [request responseStatusCode];
		//NSString *statusMessage = [request responseStatusMessage];
		NSString *response = [request responseString];
		LogMessageCompat(@"GET devices/%@.xml: %@",deviceKey,response);
		if (statusCode == 401){
			NSString *errorMessage = NSLocalizedString(@"There was a problem getting your account information. Please make sure the email address you entered is valid, as well as your password.",nil);
			@throw [NSException exceptionWithName:@"GetApiKeyException" reason:errorMessage userInfo:nil];
		}
		
		if (!error) {
			NSError *error = nil;
			ConfigParserDelegate *configParser = [[ConfigParserDelegate alloc] init];
			NSData *responseData = [request responseData];
			DeviceModulesConfig *modulesConfig = [configParser parseModulesConfig:responseData parseError:&error];
			[configParser release];			
			return modulesConfig;
		}	
		else {
			@throw [NSException exceptionWithName:@"GetXMLforDeviceException" reason:[error localizedDescription] userInfo:nil];
		}
		
		
	}
	@catch (NSException * e) {
		@throw;
	}
	return nil;
}

- (BOOL) changeStatusToMissing: (BOOL) missing forDevice:(NSString *) deviceKey fromUser: (NSString *) apiKey {
	NSURL *url = [NSURL URLWithString:[PREY_URL stringByAppendingFormat: @"devices/%@.xml", deviceKey]];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setUsername:apiKey];
	[request setPassword: @"x"];
	[request setRequestMethod:@"PUT"];
	if (missing)
		[request setPostValue:@"1" forKey:@"device[missing]"];
	else
		[request setPostValue:@"0" forKey:@"device[missing]"];
	[request addRequestHeader:@"User-Agent" value:PREY_USER_AGENT];
	[request setUseSessionPersistence:NO];
	[request setShouldRedirect:NO];
	
	
	@try {
		[request startSynchronous];
		NSError *error = [request error];
		if (!error) {
			/*
			 int statusCode = [request responseStatusCode];
			 NSString *statusMessage = [request responseStatusMessage];
			 NSString *response = [request responseString];
			 //LogMessageCompat(@"URL: %@ response status: %@ with data: %@", url, statusMessage, response );
			 */
			return NO;
		}
		
		else {
			return YES;
			
		}
	}
	@catch (NSException * e) {
		@throw;
	}
	
	return NO;
	
}

- (BOOL) validateIfExistApiKey: (NSString *) apiKey andDeviceKey: (NSString *) deviceKey
{
	
	NSURL *url = [NSURL URLWithString:[PREY_URL stringByAppendingFormat: @"devices.xml"]];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request addRequestHeader:@"User-Agent" value:PREY_USER_AGENT];
	[request setUseSessionPersistence:NO];
	[request setShouldRedirect:NO];
	[request setUsername:apiKey];
	[request setPassword:@"x"];
	
	@try {
		[request startSynchronous];
		NSError *error = [request error];
		/*
		int statusCode = [request responseStatusCode];
		NSString *statusMessage = [request responseStatusMessage];
		 */
		NSString *response = [request responseString];
		if (!error) {
			NSString *extractedDeviceKey = NULL;
			[response getCapturesWithRegexAndReferences:deviceKey,	 @"$0", &extractedDeviceKey, nil];	
			//LogMessageCompat(@"Extracted key from response: %@", extractedDeviceKey);
			return [extractedDeviceKey isEqual:deviceKey];
		}
		
		else {
			return NO;
			
		}
	}
	@catch (NSException * e) {
		@throw;
	}
	
	return NO;
}

- (BOOL) deleteDevice: (Device*) device{
	PreyConfig* preyConfig = [PreyConfig getInstance];
	NSURL *url = [NSURL URLWithString:[PREY_URL stringByAppendingFormat: @"devices/%@.xml", [device deviceKey]]];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setUsername:[preyConfig apiKey]];
	[request setPassword: @"x"];
	[request setRequestMethod:@"DELETE"];
	[request addRequestHeader:@"User-Agent" value:PREY_USER_AGENT];
	[request setUseSessionPersistence:NO];
	[request setShouldRedirect:NO];

	
	@try {
		[request startSynchronous];
		NSError *error = [request error];
		if (!error) {
			/*
			int statusCode = [request responseStatusCode];
			NSString *statusMessage = [request responseStatusMessage];
			NSString *response = [request responseString];
			//LogMessageCompat(@"URL: %@ response status: %@ with data: %@", url, statusMessage, response );
			 */
			return NO;
		}
		
		else {
			return YES;
			
		}
	}
	@catch (NSException * e) {
		@throw;
	}
	@finally {
		[preyConfig release];
	}
	
	return NO;
	
}

- (void) sendReport: (Report *) report {
	PreyConfig *preyConfig = [PreyConfig getInstance];
	//NSURL *url = [NSURL URLWithString:[PREY_URL stringByAppendingFormat: @"devices/%@.xml", [preyConfig deviceKey]]];
	NSURL *url = [NSURL URLWithString:report.url];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setUsername:[preyConfig apiKey]];
	[request setPassword: @"x"];
	[request setRequestMethod:@"POST"];
	[request addRequestHeader:@"User-Agent" value:PREY_USER_AGENT];
	

	[[report getReportData] enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
		LogMessageCompat(@"adding to report: %@ = %@", key, object);
		[request setPostValue:(NSString*)object forKey:(NSString *) key];
	}];

	[request setUseSessionPersistence:NO];
	[request setShouldRedirect:NO];
	
	@try {
		[request startSynchronous];
		NSError *error = [request error];
		if (!error) {
			int statusCode = [request responseStatusCode];
			if (statusCode != 200)
				@throw [NSException exceptionWithName:@"ReportNotSentException" reason:NSLocalizedString(@"Report couldn't be sent",nil) userInfo:nil];
			NSString *response = [request responseString];
			LogMessageCompat(@"Report sent response: %@",response);
		}	
		else {
			@throw [NSException exceptionWithName:@"ReportNotSentException" reason:[error localizedDescription] userInfo:nil];
			
		} 
	} 
	@catch (NSException *e) {
		@throw;
	}
	[preyConfig release];
	
}

- (NSString *) getErrorMessageFromXML: (NSData*) response {
	
	NSError *error = nil;
	ErrorParserDelegate *errorsParser = [[ErrorParserDelegate alloc] init];
	NSMutableArray *errors = [errorsParser parseErrors:response parseError:&error];
	[errorsParser release];
	return (NSString*)[errors objectAtIndex:0];
	
}

@end
