//
//  PreyConfig.m
//  Prey
//
//  Created by Carlos Yaconi on 01/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "PreyConfig.h"
#import "PreyRestHttp.h"

static NSString *const API_KEY = @"api_key";
static NSString *const DEVICE_KEY = @"device_key";
static NSString *const EMAIL = @"email";
static NSString *const CHECK_URL = @"check_url";
static NSString *const ALREADY_REGISTERED = @"already_registered";
static NSString *const ACCURACY=@"accuracy";
static NSString *const DELAY=@"delay";

@implementation PreyConfig

@synthesize apiKey, deviceKey, checkUrl, email, alreadyRegistered, desiredAccuracy, delay, missing;
static PreyConfig *instance;

+(PreyConfig *)instance  {
	
	
	@synchronized(self) {
		if(!instance) {
			instance = [[PreyConfig alloc] init];
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			instance.apiKey = [defaults stringForKey: API_KEY];
			instance.deviceKey = [defaults stringForKey: DEVICE_KEY];
			instance.checkUrl = [defaults stringForKey: CHECK_URL];
			instance.email = [defaults stringForKey: EMAIL];
			[instance loadDefaultValues];
		}
	}
	return instance;
}

+ (PreyConfig*) initWithUser:(User*)user andDevice:(Device*)device
{
	instance = [[PreyConfig alloc] init];
	instance.apiKey = [user apiKey];
	instance.deviceKey = [device deviceKey];
	instance.email = [user email];
	[instance loadDefaultValues];
	[instance saveValues];
	return instance;
}

- (void) loadDefaultValues {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	double accSet = [defaults doubleForKey:ACCURACY];
	self.desiredAccuracy = accSet != 0 ? accSet : kCLLocationAccuracyHundredMeters; 
	int delaySet = [defaults integerForKey:DELAY];
	self.delay = delaySet > 0 ? delaySet : 20;
	NSString *isRegistered = [defaults stringForKey:ALREADY_REGISTERED];
	if (isRegistered != nil && [@"YES" isEqualToString:isRegistered]) {
		self.alreadyRegistered = YES;
		PreyRestHttp *http = [[PreyRestHttp alloc] init];
		self.missing = [http isMissingTheDevice:self.deviceKey ofTheUser:self.apiKey];
		[http release];
	}
	else {
		self.alreadyRegistered = NO;
		self.missing = NO;
	}
	
}

- (void) saveValues
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[self apiKey] forKey:API_KEY];
	[defaults setObject:[self deviceKey] forKey:DEVICE_KEY];
	[defaults setObject:[self email] forKey:EMAIL];
	[defaults setObject:[self checkUrl] forKey:CHECK_URL];
	[defaults setObject:@"YES" forKey:ALREADY_REGISTERED];
	[defaults setDouble:desiredAccuracy forKey:ACCURACY];
	[defaults setInteger:delay forKey:DELAY];
	[defaults synchronize]; // this method is optional
	
}

- (void) detachDevice {
	[[Device getInstance] detachDevice]; 
}

- (void) setDesiredAccuracy:(double) acc { 
	desiredAccuracy = acc;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setDouble:acc forKey:ACCURACY];
	[defaults synchronize]; // this method is optional
	[[NSNotificationCenter defaultCenter] postNotificationName:@"accuracyUpdated" object:self];
}

- (void) setDelay:(int) newDelay { 
	delay = newDelay;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:newDelay forKey:DELAY];
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
