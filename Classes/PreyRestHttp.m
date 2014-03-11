//
//  RestHttpUser.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 18-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//
//


#import "PreyRestHttp.h"
#import "ReportModule.h"

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
    [request setUserAgentString:[self userAgent]];
    [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
	[request setUseSessionPersistence:NO];
	[request setShouldRedirect:NO];
	[request setValidatesSecureCertificate:NO];
    [request setTimeOutSeconds:30];
}

-(NSString *)userAgent {
    NSString *deviceName;
    NSString *OSName;
    NSString *OSVersion;
    //NSString *locale = [[NSLocale currentLocale] localeIdentifier];
    
    UIDevice *device = [UIDevice currentDevice];
    deviceName = [device model];
    OSName = [device systemName];
    OSVersion = [device systemVersion];

    // Takes the form "My Application 1.0 (Macintosh; Mac OS X 10.5.7; en_GB)"
    //return [NSString stringWithFormat:@"Prey/%@ (%@; %@ %@; %@)", [Constants appVersion], deviceName, OSName, OSVersion, locale];
    return [NSString stringWithFormat:@"Prey/%@ (iOS)", [Constants appVersion]];
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
    ASIHTTPRequest *request = [self createGETrequestWithURL:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/profile.json"]];
    [request setUsername:[user email]];
	[request setPassword:[user password]];
	
	@try {
		[request startSynchronous];
		NSError *error = [request error];
        
		if (!error)
        {
            int statusCode = [request responseStatusCode];
            NSString *statusMessage = [request responseStatusMessage];
            NSString *response = [request responseString];
            
            PreyLogMessage(@"PreyRestHttp", 10, @"GET profile.json: %@ :: %@",statusMessage, response);
            
            if (statusCode == 401){
                NSString *errorMessage = NSLocalizedString(@"There was a problem getting your account information. Please make sure the email address you entered is valid, as well as your password.",nil);
                @throw [NSException exceptionWithName:@"GetApiKeyException" reason:errorMessage userInfo:nil];
            }
            
            NSString *respString = [request responseString];
			JsonConfigParser *configParser = [[JsonConfigParser alloc] init];
            [configParser parseRequest:respString forUser:user parseError:&error];
            
			return user.apiKey;
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
    ASIFormDataRequest *request = [self createPOSTrequestWithURL:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/signup.json"]];
    
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
    [requestData setObject:[user name] forKey:@"name"];
	[requestData setObject:[user email] forKey:@"email"];
	[requestData setObject:[user country] forKey:@"country_name"];
    [requestData setObject:[user password] forKey:@"password"];
	[requestData setObject:[user repassword] forKey:@"password_confirmation"];
	[requestData setObject:@"" forKey:@"referer_user_id"];
    
    [request setNumberOfTimesToRetryOnTimeout:5];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    
    if (requestData != nil)
        [request appendPostData:[NSJSONSerialization dataWithJSONObject:requestData options:0 error:nil ]];

    @try {
		[request startSynchronous];
		NSError *error = [request error];
		if (!error) {
			int statusCode = [request responseStatusCode];
			NSString *statusMessage = [request responseStatusMessage];
			NSString *response = [request responseString];
            
            PreyLogMessage(@"PreyRestHttp", 10, @"POST signup.json: %@ :: %@",statusMessage, response);
            
			if (statusCode != 201){
				@throw [NSException exceptionWithName:@"CreateApiKeyException" reason:[error localizedDescription] userInfo:nil];
			}
            
            NSError *error = nil;
            NSString *respString = [request responseString];
			JsonConfigParser *configParser = [[JsonConfigParser alloc] init];
            NSString *userKey = [configParser parseKey:respString parseError:&error];
			
			return userKey;
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


- (NSString *) createDeviceKeyForDevice: (Device *) device usingApiKey: (NSString *) apiKey
{
  	ASIFormDataRequest *request = [self createPOSTrequestWithURL:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices.json"]];
    
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
    [requestData setObject:[device name] forKey:@"name"];
    [requestData setObject:[device type] forKey:@"device_type"];
    [requestData setObject:[device version] forKey:@"os_version"];
    [requestData setObject:[device model] forKey:@"model_name"];
    [requestData setObject:[device vendor] forKey:@"vendor_name"];
    [requestData setObject:[device os] forKey:@"os"];
    [requestData setObject:[device macAddress] forKey:@"physical_address"];
    [requestData setObject:[device uuid] forKey:@"uuid"];
    
    [request setNumberOfTimesToRetryOnTimeout:5];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
	[request setUsername:apiKey];
	[request setPassword: @"x"];
    
    if (requestData != nil)
        [request appendPostData:[NSJSONSerialization dataWithJSONObject:requestData options:0 error:nil ]];
    
	@try
    {
		[request startSynchronous];
		NSError *error = [request error];
		if (!error)
        {
            int statusCode = [request responseStatusCode];
			NSString *statusMessage = [request responseStatusMessage];
			NSString *response = [request responseString];

			PreyLogMessage(@"PreyRestHttp", 10, @"POST devices.json: %@ :: %@",statusMessage, response);
            
			if ((statusCode == 302) || (statusCode == 403))
				@throw [NSException exceptionWithName:@"NoMoreDevicesAllowed"
                                               reason:NSLocalizedString(@"It seems you've reached your limit for devices on the Control Panel. Try removing this device from your account if you had already added.",nil)
                                             userInfo:nil];
            
            NSError *error = nil;
            NSString *respString = [request responseString];
			JsonConfigParser *configParser = [[JsonConfigParser alloc] init];
            NSString *deviceKey = [configParser parseKey:respString parseError:&error];
			
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

- (BOOL) deleteDevice: (Device*) device{
	PreyConfig* preyConfig = [PreyConfig instance];
	__block ASIHTTPRequest *request = [self createGETrequestWithURL:[preyConfig deviceCheckPathWithExtension:@""]];
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

- (void) sendReport: (ReportModule *) report {
	
    PreyConfig *preyConfig = [PreyConfig instance];
    __block ASIFormDataRequest *request = [self createPOSTrequestWithURL:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@/reports",[preyConfig deviceKey]]];
    
	//__block ASIFormDataRequest *request = [self createPOSTrequestWithURL:report.url];
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
        {
            PreyLogMessageAndFile(@"PreyRestHttp", 0, @"Report wasn't sent: %@", [request responseStatusMessage]);
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"SendReport"];
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"lastExecutionKey"];
            //@throw [NSException exceptionWithName:@"ReportNotSentException" reason:NSLocalizedString(@"Report couldn't be sent",nil) userInfo:nil];
        }
        else
            PreyLogMessageAndFile(@"PreyRestHttp", 10, @"Report: POST response: %@",[request responseStatusMessage]);
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

- (void) getAppstoreConfig: (id) delegate inURL: (NSString *) URL {
    ASIHTTPRequest *request = [self createGETrequestWithURL:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat:@"/%@",URL]];
    [request setDelegate:delegate];
    [request setDidFinishSelector:@selector(receivedData:)];
    [request startAsynchronous];
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
	//__block ASIFormDataRequest *request = [self createPUTrequestWithURL:[preyConfig deviceCheckPathWithExtension:@".xml"]];
    
    __block ASIFormDataRequest *request = [self createPOSTrequestWithURL:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@/data",[preyConfig deviceKey]]];
    
    PreyLogMessageAndFile(@"PreyRestHttp", 10, [DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@/data",[preyConfig deviceKey]]);
    
    
    [request setShouldContinueWhenAppEntersBackground:YES];
	[request setUsername:[preyConfig apiKey]];
	[request setPassword: @"x"];
	[request setPostValue:id forKey:@"notification_id"];
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


#pragma mark -
#pragma mark New panel API

- (NewModulesConfig *) checkStatusForDevice: (NSString *) deviceKey andApiKey: (NSString *) apiKey {
    
    ASIHTTPRequest *request = [self createGETrequestWithURL:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@.json", deviceKey]];
    
    [request setUsername:apiKey];
	[request setPassword: @"x"];
	
    PreyLogMessage(@"PreyRestHttp", 10,@"%@",[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@.json", deviceKey]);
    
	@try {
		[request startSynchronous];
		NSError *error = [request error];
		if (!error)
        {
            int statusCode = [request responseStatusCode];
            PreyLogMessage(@"PreyRestHttp", 21, @"GET devices/%@.json: %@",deviceKey,[request responseStatusMessage]);
            
            if (statusCode == 401)
            {
                NSString *errorMessage = NSLocalizedString(@"There was a problem getting your account information. Please make sure the email address you entered is valid, as well as your password.",nil);
                @throw [NSException exceptionWithName:@"GetApiKeyException" reason:errorMessage userInfo:nil];
            }
            
            //NSData *respData = [request responseData];
            NSString *respString = [request responseString];
			JsonConfigParser *configParser = [[JsonConfigParser alloc] init];

            
            
            //NSString *respString =@"[{\"command\":\"get\",\"target\":\"report\",\"options\":{\"include\":[\"picture\",\"location\",\"screenshot\",\"access_points_list\"],\"interval\":\"5\"}}]";
            
            //NSString *respString =@"[{\"command\":\"get\",\"target\":\"report\"}]";
            //NSString *respString =@"[{\"command\":\"get\",\"target\":\"location\"}]";
            //NSString *respString =@"[{\"command\":\"get\",\"target\":\"public_ip\"},\
            {\"command\":\"get\",\"target\":\"private_ip\"},\
            {\"command\":\"get\",\"target\":\"first_mac_address\"},\
            {\"command\":\"get\",\"target\":\"firmware_info\"},\
            {\"command\":\"get\",\"target\":\"battery_status\"},\
            {\"command\":\"get\",\"target\":\"processor_info\"},\
            {\"command\":\"get\",\"target\":\"uptime\"},\
            {\"command\":\"get\",\"target\":\"remaining_storage\"}\
            ]";
//          NSString *respString =@"[{\"command\":\"start\",\"target\":\"alert\",\"options\":{\"message\":\"asdasd\"}},{\"command\":\"start\",\"target\":\"alarm\",\"options\":null}]";
            
            //NSString *respString =@"[ {\"command\": \"start\",\"target\": \"geofencing\",\"options\": {\"origin\": \"-70.60713481,-36.42372147\",\"radius\":\"100\" }}]";
            
			NewModulesConfig *modulesConfig = [configParser parseModulesConfig:respString parseError:&error];
			[modulesConfig runAllModules];
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

- (void) sendJsonData: (NSDictionary*) jsonData andRawData: (NSDictionary*) rawData toEndpoint: (NSString *) url
{
    PreyConfig *preyConfig = [PreyConfig instance];
	__block ASIFormDataRequest *request = [self createPOSTrequestWithURL:url];
    
    [request setShouldContinueWhenAppEntersBackground:YES];
	[request setUsername:[preyConfig apiKey]];
	[request setPassword: @"x"];
    [request setNumberOfTimesToRetryOnTimeout:5];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    
    PreyLogMessageAndFile(@"PreyRestHttp", 10, url);
    PreyLogMessageAndFile(@"PreyRestHttp", 0, @"jsonData: %@",[jsonData description]);
    
    if (jsonData != nil)
        [request appendPostData:[NSJSONSerialization dataWithJSONObject:jsonData options:0 error:nil ]];
    if (rawData != nil)
        [request addData:[rawData objectForKey:@"data"] withFileName:@"picture.jpg" andContentType:@"image/png" forKey:[rawData objectForKey:@"key"]];
    
    [request setCompletionBlock:^{
        int statusCode = [request responseStatusCode];
        if (statusCode != 200)
            PreyLogMessageAndFile(@"PreyRestHttp", 0, @"Couldn't send data: %@", [request responseStatusMessage]);
        else
            PreyLogMessageAndFile(@"PreyRestHttp", 10, @"Data sent successfully");
    }];
    [request setFailedBlock:^{
        PreyLogMessageAndFile(@"PreyRestHttp", 0, @"ERROR sending data: %@", [[request error] localizedDescription]);
    }];
	[request startAsynchronous];
}

- (void) notifyEvent: (NSDictionary*) data {
    PreyConfig *preyConfig = [PreyConfig instance];
    [self sendJsonData:data andRawData:nil toEndpoint:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@/events",[preyConfig deviceKey]]];
}

- (void) notifyCommandResponse: (NSDictionary*) data {
    PreyConfig *preyConfig = [PreyConfig instance];
    [self sendJsonData:data andRawData:nil toEndpoint:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@/response",[preyConfig deviceKey]]];
}

- (void) sendSetting: (NSDictionary*) data {
    PreyConfig *preyConfig = [PreyConfig instance];
    [self sendJsonData:data andRawData:nil toEndpoint:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@/settings",[preyConfig deviceKey]]];
}

- (void) sendData: (NSDictionary*) data {
    PreyConfig *preyConfig = [PreyConfig instance];
    [self sendJsonData:data andRawData:nil toEndpoint:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@/data",[preyConfig deviceKey]]];
}

- (void) sendData: (NSDictionary*) data andRaw: (NSDictionary*) rawData {
    PreyConfig *preyConfig = [PreyConfig instance];
    [self sendJsonData:data andRawData:rawData toEndpoint:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@/data",[preyConfig deviceKey]]];
}

@end
