//
//  Config.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 25-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//

#import "Constants.h"


@implementation Constants
/*
	NSString * const DEFAULT_CONTROL_PANEL_HOST = @"https://panel.preyproject.com/";
	NSString * const PREY_URL = @"http://control.preyproject.com/";
	NSString * const PREY_SECURE_URL = @"https://control.preyproject.com/";
    NSString * const PREY_API_URL = @"https://panel.preyproject.com/";
	BOOL  const ASK_FOR_LOGIN = YES;
	BOOL const	USE_CONTROL_PANEL_DELAY=YES; //use the preferences page's instead.
    BOOL const	SHOULD_LOG=NO;
*/


//NSString * const DEFAULT_CONTROL_PANEL_HOST = @"https://control.preyapp.com/api/v2";  // STG
//NSString * const DEFAULT_CONTROL_PANEL_HOST = @"https://solid.preyproject.com/api/v2";  // PRD
NSString * const DEFAULT_CONTROL_PANEL_HOST = @"https://panel.preyproject.com/api/v2";  // PRD


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
