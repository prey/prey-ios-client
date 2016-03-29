//
//  PreyConfig.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 01/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "Device.h"


@interface PreyConfig : NSObject {
    NSString *apiKey;
	NSString *deviceKey;
	NSString *checkUrl;
	NSString *email;
	double desiredAccuracy;
	int	delay;
	BOOL alreadyRegistered;
	BOOL missing;
    BOOL askForPassword;
	BOOL alertOnReport;
    BOOL camouflageMode;
    BOOL intervalMode;
    BOOL isTouchIDEnabled;
    BOOL hideTourWeb;
}

@property (nonatomic) NSString *checkUrl;
@property (nonatomic) NSString *controlPanelHost;
@property (nonatomic) NSString *checkPath;
@property (nonatomic) NSString *exceptionsEndpoint;
@property (nonatomic) NSString *dataEndpoint;
@property (nonatomic) NSString *apiKey;
@property (nonatomic) NSString *deviceKey;
@property (nonatomic) NSString *email;

@property BOOL sendCrashReports;
@property BOOL alreadyRegistered;
@property BOOL missing;
@property (nonatomic) double desiredAccuracy;
@property (nonatomic) BOOL askForPassword;
@property (nonatomic) BOOL camouflageMode;
@property (nonatomic) BOOL intervalMode;
@property (nonatomic) BOOL alertOnReport;
@property (nonatomic) BOOL isTouchIDEnabled;
@property (nonatomic) BOOL hideTourWeb;
@property (nonatomic) int delay;
@property (getter = isPro) BOOL pro;

+ (PreyConfig*) instance;
+ (PreyConfig*) initWithUser:(User*)user andDevice:(Device*)device;
+ (PreyConfig*) initWithApiKey:(NSString*)apiKeyUser andDevice:(Device*)device;
- (NSString *) deviceCheckPathWithExtension: (NSString *) extension;
- (NSString *) readConfigValueForKey: (NSString *) key;
- (void) loadDefaultValues;
- (void) saveValues;
- (void)resetValues;
@end
