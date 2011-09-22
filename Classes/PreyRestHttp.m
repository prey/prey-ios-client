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



@interface PreyRestHttp()

-(ASIHTTPRequest*)createGETrequestWithURL: (NSString*) url;
-(ASIFormDataRequest*)createPOSTrequestWithURL: (NSString*) url;
-(ASIFormDataRequest*)createPUTrequestWithURL: (NSString*) url;
-(void)setupRequest: (ASIHTTPRequest*)request;

@end

@implementation PreyRestHttp
@synthesize responseData;
@synthesize baseURL;

-(void)setupRequest: (ASIHTTPRequest*)request{
    [request addRequestHeader:@"User-Agent" value:PREY_USER_AGENT];
    [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
	[request setUseSessionPersistence:NO];
	[request setShouldRedirect:NO];
	[request setValidatesSecureCertificate:NO];
    [request setTimeOutSeconds:30];
}

-(ASIHTTPRequest*)createGETrequestWithURL: (NSString*) url {
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    [self setupRequest:request];
    return request;
}

-(ASIFormDataRequest*)createPOSTrequestWithURL: (NSString*) url{
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
	[request setRequestMethod:@"POST"];
	[self setupRequest:request];
    return request;
}

-(ASIFormDataRequest*)createPUTrequestWithURL: (NSString*) url{
	ASIFormDataRequest *request = [self createPOSTrequestWithURL:url];
	[request setRequestMethod:@"PUT"];
    return request;
}

- (NSString *) getCurrentControlPanelApiKey: (User *) user
{
    ASIHTTPRequest *request = [self createGETrequestWithURL:[PREY_SECURE_URL stringByAppendingFormat: @"profile.xml"]];
    [request setUsername:[user email]];
	[request setPassword: [user password]];
	
	@try {
		[request startSynchronous];
		NSError *error = [request error];
		int statusCode = [request responseStatusCode];
		PreyLogMessage(@"PreyRestHttp", 10, @"GET profile.xml: %@",[request responseStatusMessage]);
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
			@throw [NSException exceptionWithName:@"GetApiKeyUnknownException" reason:[error localizedDescription] userInfo:nil];
		}		
	}
	@catch (NSException * e) {
		@throw e;
	}
	return nil;
}


- (NSString *) createApiKey: (User *) user
{
	ASIFormDataRequest *request = [self createPOSTrequestWithURL:[PREY_SECURE_URL stringByAppendingFormat: @"users.xml"]];
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
	
	ASIFormDataRequest *request = [self createPOSTrequestWithURL:[PREY_URL stringByAppendingFormat: @"devices.xml"]];
	[request setUsername:apiKey];
	[request setPassword: @"x"];
	[request setPostValue:[device name] forKey:@"device[title]"];
	[request setPostValue:[device type] forKey:@"device[device_type]"];
	[request setPostValue:[device version] forKey:@"device[os_version]"];
    [request setPostValue:[device model] forKey:@"device[model_name]"];
    [request setPostValue:[device vendor] forKey:@"device[vendor_name]"];
	[request setPostValue:[device os] forKey:@"device[os]"];
	[request setPostValue:[device macAddress] forKey:@"device[physical_address]"];
    [request setPostValue:[device uuid] forKey:@"device[uuid]"];
	
	@try {
		[request startSynchronous];
		NSError *error = [request error];
		if (!error) {
			int statusCode = [request responseStatusCode];
			if (statusCode == 302)
				@throw [NSException exceptionWithName:@"NoMoreDevicesAllowed" reason:NSLocalizedString(@"It seems you've reached your limit for devices on the Control Panel. Try removing this device from your account if you had already added.",nil) userInfo:nil];
			
			//NSString *statusMessage = [request responseStatusMessage];
			NSString *response = [request responseString];
			PreyLogMessage(@"PreyRestHttp", 10, @"POST devices.xml: %@",response);
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

    ASIHTTPRequest *request = [self createGETrequestWithURL:[PREY_URL stringByAppendingFormat: @"devices/%@.xml", deviceKey]];
    [request setUsername:apiKey];
	[request setPassword: @"x"];
	
	@try {
		[request startSynchronous];
		NSError *error = [request error];
		int statusCode = [request responseStatusCode];
		//NSString *statusMessage = [request responseStatusMessage];
		//NSString *response = [request responseString];
		PreyLogMessage(@"PreyRestHttp", 10, @"GET devices/%@.xml: %@",deviceKey,[request responseStatusMessage]);
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
	ASIFormDataRequest *request = [self createPUTrequestWithURL:[PREY_URL stringByAppendingFormat: @"devices/%@.xml", deviceKey]];
    [request setShouldContinueWhenAppEntersBackground:YES];
	[request setUsername:apiKey];
	[request setPassword: @"x"];
	if (missing)
		[request setPostValue:@"1" forKey:@"device[missing]"];
	else
		[request setPostValue:@"0" forKey:@"device[missing]"];
	
	@try {
        PreyLogMessage(@"PreyRestHttp", 10, @"Attempting to change status on Control Panel");
		[request startSynchronous];
        PreyLogMessage(@"PreyRestHttp", 10, @"PUT devices/%@.xml [missing=%@] response: %@",deviceKey,missing?@"YES":@"NO",[request responseStatusMessage]);
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
	
	ASIHTTPRequest *request = [self createGETrequestWithURL:[PREY_URL stringByAppendingFormat: @"devices.xml"]];
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
	PreyConfig* preyConfig = [PreyConfig instance];
	__block ASIHTTPRequest *request = [self createGETrequestWithURL:[PREY_URL stringByAppendingFormat: @"devices/%@.xml", [device deviceKey]]];
	[request setUsername:[preyConfig apiKey]];
	[request setPassword: @"x"];
	[request setRequestMethod:@"DELETE"];
    
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
	__block ASIFormDataRequest *request = [self createPOSTrequestWithURL:report.url];
    [request setShouldContinueWhenAppEntersBackground:YES];
	[request setUsername:[preyConfig apiKey]];
	[request setPassword: @"x"];
	
    /*
	[[report getReportData] enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
		//LogMessage(@"PreyRestHttp", 10, @"Adding to report: %@ = %@", key, object);
		[request addPostValue:(NSString*)object forKey:(NSString *) key];
	}];
     */
    [report fillReportData:request];
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
	PreyLogMessage(@"PreyRestHttp", 10, @"Checking for Internet connection.");
	Reachability *r = [Reachability reachabilityWithHostName:@"control.preyproject.com"];
	NetworkStatus internetStatus = [r currentReachabilityStatus];
	BOOL internet;
	if ((internetStatus != ReachableViaWiFi) && (internetStatus != ReachableViaWWAN)) {
		internet = NO;
		PreyLogMessage(@"PreyRestHttp", 10, @"Internet connection NOT FOUND!");
	} else {
		internet = YES;
		PreyLogMessage(@"PreyRestHttp", 10, @"Internet connection FOUND!");
	}
	return internet;
}

- (void) setPushRegistrationId: (NSString *) id {
    PreyConfig *preyConfig = [PreyConfig instance];
	__block ASIFormDataRequest *request = [self createPUTrequestWithURL:[PREY_URL stringByAppendingFormat: @"devices/%@.xml", [preyConfig deviceKey]]];
    [request setShouldContinueWhenAppEntersBackground:YES];
	[request setUsername:[preyConfig apiKey]];
	[request setPassword: @"x"];
	[request setPostValue:id forKey:@"device[notification_id]"];
    [request setNumberOfTimesToRetryOnTimeout:5];
    
    [request setCompletionBlock:^{
        int statusCode = [request responseStatusCode];
        if (statusCode != 200)
            PreyLogMessageAndFile(@"PreyRestHttp", 0, @"Device notification_id WASN't updated on the Control Panel: %@", [request responseStatusMessage]);
        else
            PreyLogMessageAndFile(@"PreyRestHttp", 10, @"Device notification_id updated OK on the Control Panel");
    }];
    [request setFailedBlock:^{
        PreyLogMessageAndFile(@"PreyRestHttp", 0, @"ERROR Updating device reg_id on the Control Panel: %@", [[request error] localizedDescription]);
    }];
	[request startAsynchronous];
}

@end
