//
//  PreyConfig.m
//  Prey
//
//  Created by Carlos Yaconi on 01/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "PreyConfig.h"

static NSString *const API_KEY = @"api_key";
static NSString *const DEVICE_KEY = @"device_key";
static NSString *const EMAIL = @"email";
static NSString *const CHECK_URL = @"check_url";
static NSString *const ALREADY_REGISTERED = @"already_registered";
static NSString *const ACCURACY=@"accuracy";

@implementation PreyConfig

@synthesize apiKey, deviceKey, checkUrl, email, alreadyRegistered, desiredAccuracy;

+(PreyConfig *)instance  {
	static PreyConfig *instance;
	
	@synchronized(self) {
		if(!instance) {
			instance = [[PreyConfig alloc] init];
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			
			instance.apiKey = [defaults stringForKey: API_KEY];
			instance.deviceKey = [defaults stringForKey: DEVICE_KEY];
			instance.checkUrl = [defaults stringForKey: CHECK_URL];
			instance.email = [defaults stringForKey: EMAIL];
			instance.desiredAccuracy = [NSNumber numberWithDouble:[defaults  doubleForKey:ACCURACY]];
			NSString *isRegistered = [defaults stringForKey:ALREADY_REGISTERED];
			if (isRegistered != nil && [@"YES" isEqualToString:isRegistered])
				instance.alreadyRegistered = YES;
			else
				instance.alreadyRegistered = NO;
		}
	}
	return instance;
}

+ (PreyConfig*) initWithUser:(User*)user andDevice:(Device*)device
{
	PreyConfig *config = [[PreyConfig alloc] init];
	config.apiKey = [user apiKey];
	config.deviceKey = [device deviceKey];
	config.email = [user email];
	[config saveValues];
	return config;
}

- (void) saveValues
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[self apiKey] forKey:API_KEY];
	[defaults setObject:[self deviceKey] forKey:DEVICE_KEY];
	[defaults setObject:[self email] forKey:EMAIL];
	[defaults setObject:[self checkUrl] forKey:CHECK_URL];
	[defaults setObject:@"YES" forKey:ALREADY_REGISTERED];
	[defaults setObject:[self desiredAccuracy] forKey:ACCURACY];
	[defaults synchronize]; // this method is optional
	
}

- (void) detachDevice {
	[[Device getInstance] detachDevice]; 
}

- (void) setDesiredAccuracy:(NSNumber *) acc { 
	desiredAccuracy = acc;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:acc forKey:ACCURACY];
	[defaults synchronize]; // this method is optional
}

- (void) dealloc {
	[super dealloc];
	[apiKey release];
	[deviceKey release];
	[checkUrl release];
	[email release];
}
@end
