//
//  Config.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 25-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Constants : NSObject {
    
	
}

#define kLabelTag	4096

#define IS_IPHONE5 (([[UIScreen mainScreen] bounds].size.height-568)?NO:YES)
#define IS_OS_5_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0)
#define IS_OS_6_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0)
#define IS_OS_7_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)

/*
//extern NSString * const PREY_VERSION;
extern NSString * const DEFAULT_CONTROL_PANEL_HOST;
extern NSString * const PREY_SECURE_URL;
extern NSString * const PREY_URL;
extern NSString * const PREY_API_URL;
//extern NSString * const PREY_USER_AGENT;
*/

extern NSString * const DEFAULT_CONTROL_PANEL_HOST;
extern NSString * const DEFAULT_CHECK_PATH;
extern BOOL const DEFAULT_SEND_CRASH_REPORTS;
extern NSString * const DEFAULT_EXCEPTIONS_ENDPOINT;
extern NSString * const DEFAULT_DATA_ENDPOINT_LOCATION;
extern BOOL  const ASK_FOR_LOGIN;
extern BOOL const USE_CONTROL_PANEL_DELAY;
extern BOOL const SHOULD_LOG;



+(NSString *) appName;
+(NSString *) appVersion;
+(NSString *) appBuildVersion;
+(NSString *) appLabel;

@end
