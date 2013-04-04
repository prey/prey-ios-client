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
extern NSString * const DEFAULT_CONTROL_PANEL_HOST;
extern NSString * const DEFAULT_CHECK_PATH;
extern BOOL const DEFAULT_SEND_CRASH_REPORTS;
extern NSString * const DEFAULT_EXCEPTIONS_ENDPOINT;
extern NSString * const DEFAULT_DATA_ENDPOINT_LOCATION;

extern NSString * const PREY_PANEL_URL;
extern BOOL const ASK_FOR_LOGIN;
extern BOOL const USE_CONTROL_PANEL_DELAY;
extern BOOL const SHOULD_LOG;



+(NSString *) appName;
+(NSString *) appVersion;
+(NSString *) appBuildVersion;
+(NSString *) appLabel;

@end
