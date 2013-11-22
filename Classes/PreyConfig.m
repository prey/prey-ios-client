//
//  PreyConfig.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 01/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
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
static NSString *const ASK_FOR_PASSWORD=@"ask_for_pass";
static NSString *const CAMOUFLAGE_MODE=@"camouflage_mode";
static NSString *const INTERVAL_MODE=@"interval_mode";
static NSString *const PRO_ACCOUNT=@"pro_account";

@implementation PreyConfig

@synthesize apiKey, deviceKey, checkUrl, email, alreadyRegistered, desiredAccuracy, delay, missing, alertOnReport, askForPassword, camouflageMode, intervalMode, pro;
static PreyConfig *_instance = nil;

+(PreyConfig *)instance  {
	
	
	@synchronized([PreyConfig class]) {
		if(!_instance) {
			_instance = [[PreyConfig alloc] init];
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			_instance.apiKey = [defaults stringForKey: API_KEY];
            _instance.pro = [defaults boolForKey:PRO_ACCOUNT];
			_instance.deviceKey = [defaults stringForKey: DEVICE_KEY];
			_instance.checkUrl = [defaults stringForKey: CHECK_URL];
			_instance.email = [defaults stringForKey: EMAIL];
            _instance.camouflageMode = [defaults boolForKey:CAMOUFLAGE_MODE];
            _instance.intervalMode = [defaults boolForKey:INTERVAL_MODE];
			[_instance loadDefaultValues];
		}
	}
	return _instance;
}

+ (PreyConfig*) initWithUser:(User*)user andDevice:(Device*)device
{
	PreyConfig *newConfig = [[PreyConfig alloc] init];
	newConfig.apiKey = [user apiKey];
    newConfig.pro = user.isPro;
	newConfig.deviceKey = [device deviceKey];
	newConfig.email = [user email];
	[newConfig loadDefaultValues];
    [newConfig saveValues];
    newConfig.alreadyRegistered = YES;
    _instance = nil; //to force config reload on next +instance call.
	return [newConfig autorelease];
}

+ (PreyConfig*) initWithApiKey:(NSString*)apiKeyUser andDevice:(Device*)device
{
	PreyConfig *newConfig = [[PreyConfig alloc] init];
	newConfig.apiKey = apiKeyUser;
    newConfig.pro = NO;
	newConfig.deviceKey = [device deviceKey];
#warning != ¿? falta el email con el apiKey para el Deployment
	newConfig.email = nil;
	[newConfig loadDefaultValues];
    [newConfig saveValues];
    newConfig.alreadyRegistered = YES;
    _instance = nil; //to force config reload on next +instance call.
	return [newConfig autorelease];
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
    self.askForPassword = YES;
	
}

- (void) saveValues
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[self apiKey] forKey:API_KEY];
	[defaults setObject:[self deviceKey] forKey:DEVICE_KEY];
	[defaults setObject:[self email] forKey:EMAIL];
	[defaults setObject:[self checkUrl] forKey:CHECK_URL];
    [defaults setBool:[self isPro] forKey:PRO_ACCOUNT];
	[defaults setBool:YES forKey:ALREADY_REGISTERED];
	[defaults setBool:NO forKey:ALERT_ON_REPORT];
	[defaults setDouble:[self desiredAccuracy] forKey:ACCURACY];
	[defaults setInteger:[self delay] forKey:DELAY];
    [defaults setBool:[self askForPassword] forKey:ASK_FOR_PASSWORD];
    [defaults setBool:[self camouflageMode] forKey:CAMOUFLAGE_MODE];
    [defaults setBool:[self intervalMode] forKey:INTERVAL_MODE];
	[defaults synchronize]; // this method is optional
	
}

-(void)resetValues
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:API_KEY];
	[defaults removeObjectForKey:DEVICE_KEY];
	[defaults removeObjectForKey:PRO_ACCOUNT];
    [defaults removeObjectForKey:EMAIL];
	[defaults removeObjectForKey:CHECK_URL];
	[defaults removeObjectForKey:ALREADY_REGISTERED];
	[defaults removeObjectForKey:ALERT_ON_REPORT];
	[defaults removeObjectForKey:ACCURACY];
	[defaults removeObjectForKey:DELAY];
    [defaults removeObjectForKey:CAMOUFLAGE_MODE];
    [defaults removeObjectForKey:INTERVAL_MODE];
	[defaults synchronize]; // this method is optional

}

- (void) updateMissingStatus {
	if (self.deviceKey != nil && ![self.deviceKey isEqualToString:@""]){
		PreyLogMessage(@"PreyConfig", 10, @"Updating missing status...");
		PreyRestHttp *http = [[PreyRestHttp alloc] init];
		self.missing = [http isMissingTheDevice:self.deviceKey ofTheUser:self.apiKey];
		[http release];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"missingUpdated" object:self];
	}
}



- (void) detachDevice {
    [self resetValues];
	Device *dev = [Device allocInstance];
	[dev detachDevice];
	_instance=nil;
	[_instance release];
	[dev release];
}

- (void) setDesiredAccuracy:(double) acc { 
	desiredAccuracy = acc;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setDouble:acc forKey:ACCURACY];
	[defaults synchronize]; // this method is optional
	[[NSNotificationCenter defaultCenter] postNotificationName:@"accuracyUpdated" object:self];
}

- (void) setAskForPassword:(BOOL)askForPass { 
	askForPassword = askForPass;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:[self askForPassword] forKey:ASK_FOR_PASSWORD];
	[defaults synchronize]; // this method is optional
}

- (void) setDelay:(int) newDelay { 
	delay = newDelay;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:newDelay forKey:DELAY];
	[defaults synchronize]; // this method is optional
    [[NSNotificationCenter defaultCenter] postNotificationName:@"delayUpdated" object:self];
}

- (void) setAlertOnReport:(BOOL) isAlertOnReport { 
	alertOnReport = isAlertOnReport;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:isAlertOnReport forKey:ALERT_ON_REPORT];
	[defaults synchronize]; // this method is optional
}

- (void) setCamouflageMode:(BOOL) isCamouflage { 
	camouflageMode = isCamouflage;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:isCamouflage forKey:CAMOUFLAGE_MODE];
	[defaults synchronize]; // this method is optional
}

- (void) setIntervalMode:(BOOL) isInterval { 
	intervalMode = isInterval;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:isInterval forKey:INTERVAL_MODE];
	[defaults synchronize];
}

- (void) dealloc {
	[super dealloc];
	[apiKey release];
	[deviceKey release];
	[checkUrl release];
	[email release];
    

}
@end
