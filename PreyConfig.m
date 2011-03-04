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
static NSString *const ALERT_ON_REPORT=@"alert_on_report";

@implementation PreyConfig

@synthesize apiKey, deviceKey, checkUrl, email, alreadyRegistered, desiredAccuracy, delay, missing, alertOnReport;
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
	self.delay = delaySet > 0 ? delaySet : 20*60;
	self.alreadyRegistered =[defaults boolForKey:ALREADY_REGISTERED];
	self.alertOnReport = [defaults boolForKey:ALERT_ON_REPORT];
	self.missing = NO;
	
}

- (void) updateMissingStatus {
	LogMessageCompat(@"Updating missing status");
	PreyRestHttp *http = [[PreyRestHttp alloc] init];
	self.missing = [http isMissingTheDevice:self.deviceKey ofTheUser:self.apiKey];
	[http release];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"missingUpdated" object:self];
}

- (void) saveValues
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[self apiKey] forKey:API_KEY];
	[defaults setObject:[self deviceKey] forKey:DEVICE_KEY];
	[defaults setObject:[self email] forKey:EMAIL];
	[defaults setObject:[self checkUrl] forKey:CHECK_URL];
	[defaults setBool:YES forKey:ALREADY_REGISTERED];
	[defaults setBool:NO forKey:ALERT_ON_REPORT];
	[defaults setDouble:[self desiredAccuracy] forKey:ACCURACY];
	[defaults setInteger:[self delay] forKey:DELAY];
	[defaults synchronize]; // this method is optional
	
}

- (void) detachDevice {
	[[Device getInstance] detachDevice];
	instance=nil;
	[instance release];
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

- (void) setAlertOnReport:(BOOL) isAlertOnReport { 
	alertOnReport = isAlertOnReport;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:isAlertOnReport forKey:ALERT_ON_REPORT];
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
