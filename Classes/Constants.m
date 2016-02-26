//
//  Config.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 25-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//

#import "Constants.h"


@implementation Constants

//NSString * const DEFAULT_CONTROL_PANEL_HOST = @"https://control.preyhq.com/api/v2";  // STG
NSString * const DEFAULT_CONTROL_PANEL_HOST = @"https://solid.preyproject.com/api/v2";  // PRD

NSString * const URL_LOGIN_PANEL  = @"https://panel.preyproject.com/login?embeddable=true";
NSString * const URL_FORGOT_PANEL = @"https://panel.preyproject.com/forgot?embeddable=true";

NSString * const URL_GEOFENCE_POST = @"https://preyproject.com/blog/2016/01/use-geofencing-to-actively-keep-track-of-your-devices";

NSString * const URL_TERMS_PREY = @"http://www.preyproject.com/terms";
NSString * const URL_PRIVACY_PREY = @"http://www.preyproject.com/privacy";
NSString * const URL_HELP_PREY = @"http://www.preyproject.com/help";

NSString * const DEFAULT_CHECK_PATH = @"/devices/%@%@"; // /devices/abc123.xml
BOOL const DEFAULT_SEND_CRASH_REPORTS = true;
NSString * const DEFAULT_EXCEPTIONS_ENDPOINT = @"http://exceptions.preyproject.com";
NSString * const DEFAULT_DATA_ENDPOINT_LOCATION = @"data_endpoint_location";


BOOL  const ASK_FOR_LOGIN = YES;
BOOL const	USE_CONTROL_PANEL_DELAY=YES; //use the preferences page's instead.
BOOL const	SHOULD_LOG=YES;

+(NSString *) appName {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
}

+(NSString *) appVersion {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

+(NSString *) appBuildVersion {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

+(NSString *) appLabel {
    return [NSString stringWithFormat:@"%@ v%@ (build %@)",[Constants appName],[Constants appVersion],[Constants appBuildVersion]];
}

@end
