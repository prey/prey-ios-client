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
#import "Constants.h"
#import "PreyAppDelegate.h"
//deprecated
static NSString *const CHECK_URL = @"check_url";

#define kiTunesLink_Prey @"https://itunes.apple.com/us/app/apple-store/id456755037?mt=8"
static NSString *const KeyNextTimeToAskForUpdate = @"KeyNextTimeToAskForUpdate";
//
//Settings (can be updated by SettingModule)
static NSString *const CONTROL_PANEL_HOST = @"control_panel_host";
static NSString *const CHECK_PATH = @"check_path";
static NSString *const SEND_CRASH_REPORTS = @"send_crash_reports";
static NSString *const EXCEPTIONS_ENDPOINT = @"exceptions_endpoint";
static NSString *const DATA_ENDPOINT_LOCATION = @"data_endpoint_location";
//

static NSString *const API_KEY = @"api_key";
static NSString *const TOKEN_PANEL = @"token_panel";
static NSString *const DEVICE_KEY = @"device_key";
static NSString *const EMAIL = @"email";
static NSString *const ALREADY_REGISTERED = @"already_registered";
static NSString *const ACCURACY=@"accuracy";
static NSString *const DELAY=@"delay";
static NSString *const ALERT_ON_REPORT=@"alert_on_report";
static NSString *const ASK_FOR_PASSWORD=@"ask_for_pass";
static NSString *const CAMOUFLAGE_MODE=@"camouflage_mode";
static NSString *const INTERVAL_MODE=@"interval_mode";
static NSString *const PRO_ACCOUNT=@"pro_account";
static NSString *const TOUCH_ID=@"touch_id";
static NSString *const TOUR_WEB=@"tour_web";
static NSString *const MISSING=@"is_missing";

@implementation PreyConfig

@synthesize checkUrl, controlPanelHost, checkPath, exceptionsEndpoint, dataEndpoint, apiKey, deviceKey, email;
@synthesize desiredAccuracy,alertOnReport,sendCrashReports,delay,alreadyRegistered,isMissing,askForPassword,camouflageMode,intervalMode,pro;
@synthesize isTouchIDEnabled, hideTourWeb, tokenPanel;

+ (PreyConfig *)instance {
    static PreyConfig *instance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[PreyConfig alloc] init];
        NSUserDefaults *defaults    = [NSUserDefaults standardUserDefaults];
        instance.controlPanelHost   = [defaults stringForKey: CONTROL_PANEL_HOST];
        instance.checkPath          = [defaults stringForKey: CHECK_PATH];
        instance.sendCrashReports   = [defaults boolForKey: SEND_CRASH_REPORTS];
        instance.exceptionsEndpoint = [defaults stringForKey: EXCEPTIONS_ENDPOINT];
        instance.dataEndpoint       = [defaults stringForKey: DATA_ENDPOINT_LOCATION];
        
        instance.apiKey             = [defaults stringForKey: API_KEY];
        instance.tokenPanel         = [defaults stringForKey:TOKEN_PANEL];
        instance.deviceKey          = [defaults stringForKey: DEVICE_KEY];
        instance.email              = [defaults stringForKey: EMAIL];
        instance.camouflageMode     = [defaults boolForKey:CAMOUFLAGE_MODE];
        instance.intervalMode       = [defaults boolForKey:INTERVAL_MODE];
        instance.pro                = [defaults boolForKey:PRO_ACCOUNT];
        instance.isTouchIDEnabled   = [defaults boolForKey:TOUCH_ID];
        instance.hideTourWeb        = [defaults boolForKey:TOUR_WEB];
        instance.isMissing          = [defaults boolForKey:MISSING];
        [instance loadDefaultValues];
    });
    
    return instance;
}

+ (PreyConfig*)initWithUser:(User*)user andDevice:(Device*)device
{
	PreyConfig *newConfig = [PreyConfig instance];
    newConfig.controlPanelHost = DEFAULT_CONTROL_PANEL_HOST;
    newConfig.checkPath = DEFAULT_CHECK_PATH;
    newConfig.sendCrashReports = DEFAULT_SEND_CRASH_REPORTS;
    newConfig.exceptionsEndpoint = DEFAULT_EXCEPTIONS_ENDPOINT;
    newConfig.dataEndpoint = DEFAULT_DATA_ENDPOINT_LOCATION;
    
	newConfig.apiKey = [user apiKey];
    newConfig.pro = user.isPro;
	newConfig.deviceKey = [device deviceKey];
	newConfig.email = [user email];
	[newConfig loadDefaultValues];
    newConfig.alreadyRegistered = YES;
    [newConfig saveValues];

    return newConfig;
}

+ (PreyConfig*)initWithApiKey:(NSString*)apiKeyUser andDevice:(Device*)device
{
	PreyConfig *newConfig = [PreyConfig instance];
    newConfig.controlPanelHost = DEFAULT_CONTROL_PANEL_HOST;
    newConfig.checkPath = DEFAULT_CHECK_PATH;
    newConfig.sendCrashReports = DEFAULT_SEND_CRASH_REPORTS;
    newConfig.exceptionsEndpoint = DEFAULT_EXCEPTIONS_ENDPOINT;
    newConfig.dataEndpoint = DEFAULT_DATA_ENDPOINT_LOCATION;
	
    newConfig.apiKey = apiKeyUser;
    newConfig.pro = YES;
	newConfig.deviceKey = [device deviceKey];
	newConfig.email = apiKeyUser;
	[newConfig loadDefaultValues];
    newConfig.alreadyRegistered = YES;
    [newConfig saveValues];
    
	return newConfig;
}


- (void)loadDefaultValues {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	double accSet = [defaults doubleForKey:ACCURACY];
	self.desiredAccuracy = accSet != 0 ? accSet : kCLLocationAccuracyHundredMeters;
	int delaySet = (int)[defaults integerForKey:DELAY];
	self.delay = delaySet > 0 ? delaySet : 20*60;
	self.alreadyRegistered = [defaults boolForKey:ALREADY_REGISTERED];
    self.isTouchIDEnabled  = [defaults boolForKey:TOUCH_ID];
	self.alertOnReport = [defaults boolForKey:ALERT_ON_REPORT];
    self.isMissing      = [defaults boolForKey:MISSING];
    self.askForPassword = YES;
}

- (void)saveValues
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self controlPanelHost] forKey:CONTROL_PANEL_HOST];
    [defaults setObject:[self checkPath] forKey:CHECK_PATH];
    [defaults setBool:[self sendCrashReports] forKey:SEND_CRASH_REPORTS];
    [defaults setObject:[self exceptionsEndpoint] forKey:EXCEPTIONS_ENDPOINT];
    [defaults setObject:[self dataEndpoint] forKey:DATA_ENDPOINT_LOCATION];
    
	[defaults setObject:[self apiKey] forKey:API_KEY];
    [defaults setObject:[self tokenPanel] forKey:TOKEN_PANEL];
	[defaults setObject:[self deviceKey] forKey:DEVICE_KEY];
	[defaults setObject:[self email] forKey:EMAIL];
    [defaults setBool:[self isPro] forKey:PRO_ACCOUNT];
	[defaults setBool:[self alreadyRegistered] forKey:ALREADY_REGISTERED];
    [defaults setDouble:[self desiredAccuracy] forKey:ACCURACY];
	[defaults setInteger:[self delay] forKey:DELAY];
    [defaults setBool:[self askForPassword] forKey:ASK_FOR_PASSWORD];
    [defaults setBool:[self camouflageMode] forKey:CAMOUFLAGE_MODE];
    [defaults setBool:[self intervalMode] forKey:INTERVAL_MODE];
    [defaults setBool:[self isTouchIDEnabled] forKey:TOUCH_ID];
    [defaults setBool:[self hideTourWeb] forKey:TOUR_WEB];
    [defaults setBool:[self isMissing] forKey:MISSING];
    [defaults synchronize]; // this method is optional
}

-(void)resetValues
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:CONTROL_PANEL_HOST];
    [defaults removeObjectForKey:CHECK_PATH];
    [defaults removeObjectForKey:SEND_CRASH_REPORTS];
    [defaults removeObjectForKey:EXCEPTIONS_ENDPOINT];
    [defaults removeObjectForKey:DATA_ENDPOINT_LOCATION];
    
	[defaults removeObjectForKey:API_KEY];
    [defaults removeObjectForKey:TOKEN_PANEL];
	[defaults removeObjectForKey:DEVICE_KEY];
	[defaults removeObjectForKey:PRO_ACCOUNT];
    [defaults removeObjectForKey:EMAIL];
	[defaults removeObjectForKey:CHECK_URL];
	[defaults removeObjectForKey:ALREADY_REGISTERED];
    [defaults removeObjectForKey:ACCURACY];
	[defaults removeObjectForKey:DELAY];
    [defaults removeObjectForKey:CAMOUFLAGE_MODE];
    [defaults removeObjectForKey:INTERVAL_MODE];
    [defaults removeObjectForKey:TOUCH_ID];
    [defaults removeObjectForKey:TOUR_WEB];
    [defaults removeObjectForKey:MISSING];
    [defaults synchronize]; // this method is optional
    
    [[PreyConfig instance] setEmail:nil];
    [[PreyConfig instance] setApiKey:nil];
    [[PreyConfig instance] setTokenPanel:nil];
    [[PreyConfig instance] setDeviceKey:nil];
    [[PreyConfig instance] setHideTourWeb:NO];
    [[PreyConfig instance] setAlreadyRegistered:NO];
}

- (NSString *) deviceCheckPathWithExtension: (NSString *) extension {
    return [self.controlPanelHost stringByAppendingFormat: self.checkPath , self.deviceKey, extension];
}

- (NSString *) readConfigValueForKey: (NSString *) key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSObject *value = [defaults objectForKey: key];
    if ([value isKindOfClass:[NSString class]])
        return (NSString*)value;
    else
        return (BOOL)value ? @"True" : @"False";
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

// Compare local version with App Store version
- (void)checkLastVersionOnStore
{
    NSString        *appID          = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSURL           *url            = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/lookup?bundleId=%@", appID]];
    NSData          *data           = [NSData dataWithContentsOfURL:url];
    
    if (data) {
        NSError         *error      = nil;
        NSDictionary    *lookup     = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

        if (!error) {
            @try {
                if ([lookup[@"resultCount"] integerValue] == 1) {
                    NSString    *appStoreVersion = lookup[@"results"][0][@"version"];
                    NSString    *currentVersion  = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
                    
                    if ([appStoreVersion compare:currentVersion options:NSNumericSearch] == NSOrderedDescending)
                        [self displayMessageAlert:NSLocalizedString(@"There is a new version available. Do you want to update?", nil)
                                       withCancel:NSLocalizedString(@"Remind me later", nil)];
                }
            } @catch(NSException *theException) {
                PreyLogMessage(@"PreyConfig", 20,  @"An exception occurred: %@", theException.name);
            } 
        }
    }
}

- (void)displayMessageAlert:(NSString *)titleMessage withCancel:(NSString*)cancelOption
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:titleMessage
                                                                 delegate:self
                                                        cancelButtonTitle:cancelOption
                                                   destructiveButtonTitle:NSLocalizedString(@"Download", nil)
                                                        otherButtonTitles:nil];
        PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
        [actionSheet showInView:appDelegate.window.rootViewController.view];
    });
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
            // Download Action
        case 0:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kiTunesLink_Prey]];
            break;
            
            // Remind me later Action
        case 1: {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            const double    nextTime = CFAbsoluteTimeGetCurrent() + 60*60*23*1; // check again in 23 hours
            [defaults setDouble:nextTime forKey:KeyNextTimeToAskForUpdate];
            break;
        }
    }
}

- (bool)shouldAskForUpdateApp
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    const double currentTime = CFAbsoluteTimeGetCurrent();
    if ([defaults objectForKey:KeyNextTimeToAskForUpdate] == nil)
    {
        const double nextTime = currentTime + 60*60*23*1;  // 1 days (minus 2 hours)
        [defaults setDouble:nextTime forKey:KeyNextTimeToAskForUpdate];
        return false;
    }
    
    const double nextTime = [defaults doubleForKey:KeyNextTimeToAskForUpdate];
    if (currentTime < nextTime)
        return false;
    
    return true;
}


@end
