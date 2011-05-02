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
#import "Reachability.h"

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
    [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
	[request setUseSessionPersistence:NO];
	[request setShouldRedirect:NO];
	[request setValidatesSecureCertificate:NO];
	
	@try {
		[request startSynchronous];
		NSError *error = [request error];
		int statusCode = [request responseStatusCode];
		LogMessage(@"PreyRestHttp", 10, @"GET profile.xml: %@",[request responseStatusMessage]);
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
		@throw e;
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
    [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
	[request setRequestMethod:@"POST"];
	[request addRequestHeader:@"User-Agent" value:PREY_USER_AGENT];
	[request setPostValue:[device name] forKey:@"device[title]"];
	[request setPostValue:[device type] forKey:@"device[device_type]"];
	[request setPostValue:[device version] forKey:@"device[os_version]"];
    [request setPostValue:[device model] forKey:@"device[model_name]"];
    [request setPostValue:[device vendor] forKey:@"device[vendor_name]"];
	[request setPostValue:[device os] forKey:@"device[os]"];
	[request setPostValue:[device macAddress] forKey:@"device[physical_address]"];
    [request setPostValue:[device uuid] forKey:@"device[uuid]"];
	
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
			LogMessage(@"PreyRestHttp", 10, @"POST devices.xml: %@",response);
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
    [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
	[request setUseSessionPersistence:NO];
	[request setShouldRedirect:NO];
	
	@try {
		[request startSynchronous];
		NSError *error = [request error];
		int statusCode = [request responseStatusCode];
		//NSString *statusMessage = [request responseStatusMessage];
		//NSString *response = [request responseString];
		LogMessage(@"PreyRestHttp", 10, @"GET devices/%@.xml: %@",deviceKey,[request responseStatusMessage]);
        //LogMessage(@"PreyRestHttp", 20, @"GET devices/%@.xml response: %@",deviceKey,[request responseString]);
		if (statusCode == 401){
			NSString *errorMessage = NSLocalizedString(@"There was a problem getting your account information. Please make sure the email address you entered is valid, as well as your password.",nil);
			@throw [NSException exceptionWithName:@"GetApiKeyException" reason:errorMessage userInfo:nil];
		}
		
		if (!error) {
			NSError *error = nil;
			ConfigParserDelegate *configParser = [[ConfigParserDelegate alloc] init];
			NSData *respData = [request responseData];
			DeviceModulesConfig *modulesConfig = [configParser parseModulesConfig:respData parseError:&error];
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

- (BOOL) isMissingTheDevice: (NSString *) device ofTheUser: (NSString *) apiKey{
	return [self getXMLforUser:apiKey device:device].missing;
}

- (BOOL) changeStatusToMissing: (BOOL) missing forDevice:(NSString *) deviceKey fromUser: (NSString *) apiKey {
	NSURL *url = [NSURL URLWithString:[PREY_URL stringByAppendingFormat: @"devices/%@.xml", deviceKey]];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setShouldContinueWhenAppEntersBackground:YES];
	[request setUsername:apiKey];
	[request setPassword: @"x"];
    [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
	[request setRequestMethod:@"PUT"];
	if (missing)
		[request setPostValue:@"1" forKey:@"device[missing]"];
	else
		[request setPostValue:@"0" forKey:@"device[missing]"];
	[request addRequestHeader:@"User-Agent" value:PREY_USER_AGENT];
	[request setUseSessionPersistence:NO];
	[request setShouldRedirect:NO];
	
	
	@try {
        LogMessage(@"PreyRestHttp", 10, @"Attempting to change status on Control Panel");
		[request startSynchronous];
        LogMessage(@"PreyRestHttp", 10, @"PUT devices/%@.xml [missing=%@] response: %@",deviceKey,missing?@"YES":@"NO",[request responseStatusMessage]);
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
    [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
	
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
	PreyConfig* preyConfig = [PreyConfig instance];
	NSURL *url = [NSURL URLWithString:[PREY_URL stringByAppendingFormat: @"devices/%@.xml", [device deviceKey]]];
	__block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setUsername:[preyConfig apiKey]];
	[request setPassword: @"x"];
    [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
	[request setRequestMethod:@"DELETE"];
	[request addRequestHeader:@"User-Agent" value:PREY_USER_AGENT];
	[request setUseSessionPersistence:NO];
	[request setShouldRedirect:NO];
    
    @try {
		[request startSynchronous];
		NSError *error = [request error];
		if (!error) {
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

- (void) sendReport: (Report *) report {
	PreyConfig *preyConfig = [PreyConfig instance];
	//NSURL *url = [NSURL URLWithString:[PREY_URL stringByAppendingFormat: @"devices/%@.xml", [preyConfig deviceKey]]];
	NSURL *url = [NSURL URLWithString:report.url];
	__block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setShouldContinueWhenAppEntersBackground:YES];
	[request setUsername:[preyConfig apiKey]];
	[request setPassword: @"x"];
    [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
	[request setRequestMethod:@"POST"];
	[request addRequestHeader:@"User-Agent" value:PREY_USER_AGENT];
	
    /*
	[[report getReportData] enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
		//LogMessage(@"PreyRestHttp", 10, @"Adding to report: %@ = %@", key, object);
		[request addPostValue:(NSString*)object forKey:(NSString *) key];
	}];
     */
    [report fillReportData:request];

	[request setUseSessionPersistence:NO];
	[request setShouldRedirect:NO];
    [request setNumberOfTimesToRetryOnTimeout:5];
    //[request setDelegate:self];
    
    [request setCompletionBlock:^{
        int statusCode = [request responseStatusCode];
        if (statusCode != 200)
            PreyLogMessageAndFile(@"PreyRestHttp", 0, @"Report wasn't sent: %@", [request responseStatusMessage]);
            //@throw [NSException exceptionWithName:@"ReportNotSentException" reason:NSLocalizedString(@"Report couldn't be sent",nil) userInfo:nil];
        else
            PreyLogMessageAndFile(@"PreyRestHttp", 10, @"Report: POST %@ response: %@",report.url,[request responseStatusMessage]);
    }];
    [request setFailedBlock:^{
        /*@throw [NSException exceptionWithName:@"ReportNotSentException" reason:[[request error] localizedDescription] userInfo:nil]; 
         */
        PreyLogMessageAndFile(@"PreyRestHttp", 0, @"Report couldn't be sent: %@", [[request error] localizedDescription]);
    }];
    [request startAsynchronous];
	/*** USED FOR SYNC SENDING **/
    /*
	@try {
		[request startAsynchronous];
		NSError *error = [request error];
		if (!error) {
			int statusCode = [request responseStatusCode];
			if (statusCode != 200)
				@throw [NSException exceptionWithName:@"ReportNotSentException" reason:NSLocalizedString(@"Report couldn't be sent",nil) userInfo:nil];
			NSString *response = [request responseString];
			LogMessage(@"PreyRestHttp", 10, @"Report sent response: %@",response);
		}	
		else {
			@throw [NSException exceptionWithName:@"ReportNotSentException" reason:[error localizedDescription] userInfo:nil];
			
		} 
	} 
	@catch (NSException *e) {
		@throw;
	}
     */
	
}


- (NSString *) getErrorMessageFromXML: (NSData*) response {
	
	NSError *error = nil;
	ErrorParserDelegate *errorsParser = [[ErrorParserDelegate alloc] init];
	NSMutableArray *errors = [errorsParser parseErrors:response parseError:&error];
	[errorsParser release];
	return (NSString*)[errors objectAtIndex:0];
	
}

+(BOOL)checkInternet{
	//Test for Internet Connection
	LogMessage(@"PreyRestHttp", 10, @"Checking for Internet connection.");
	Reachability *r = [Reachability reachabilityWithHostName:@"control.preyproject.com"];
	NetworkStatus internetStatus = [r currentReachabilityStatus];
	BOOL internet;
	if ((internetStatus != ReachableViaWiFi) && (internetStatus != ReachableViaWWAN)) {
		internet = NO;
		LogMessage(@"PreyRestHttp", 10, @"Internet connection NOT FOUND!");
	} else {
		internet = YES;
		LogMessage(@"PreyRestHttp", 10, @"Internet connection FOUND!");
	}
	return internet;
}

- (void) setPushRegistrationId: (NSString *) id {
    PreyConfig *preyConfig = [PreyConfig instance];
    NSURL *url = [NSURL URLWithString:[PREY_URL stringByAppendingFormat: @"devices/%@.xml", [preyConfig deviceKey]]];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setShouldContinueWhenAppEntersBackground:YES];
	[request setUsername:[preyConfig apiKey]];
	[request setPassword: @"x"];
    [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
	[request setRequestMethod:@"PUT"];
	[request setPostValue:id forKey:@"device[notification_id]"];
	[request addRequestHeader:@"User-Agent" value:PREY_USER_AGENT];
	[request setUseSessionPersistence:NO];
	[request setShouldRedirect:NO];
	
	
	@try {
        
		[request startSynchronous];
		NSError *error = [request error];
		if (error)
			@throw [NSException exceptionWithName:@"CouldntSetRegIdException" reason:[error localizedDescription] userInfo:nil];
        LogMessage(@"PreyRestHttp", 10, @"Device notification_id updated OK on the Control Panel");
	}
	@catch (NSException * e) {
		 LogMessage(@"PreyRestHttp", 10, @"ERROR Updating device reg_id on the Control Panel: %@", [e reason]);
	}
}

@end
