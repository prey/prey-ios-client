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
	
}

@property (nonatomic,retain) NSString *checkUrl;
@property (nonatomic) double desiredAccuracy;

@property (nonatomic,retain) NSString *controlPanelHost;
@property (nonatomic,retain) NSString *checkPath;
@property BOOL sendCrashReports;
@property (nonatomic,retain) NSString *exceptionsEndpoint;
@property (nonatomic,retain) NSString *dataEndpoint;

@property (nonatomic,retain) NSString *apiKey;
@property (nonatomic,retain) NSString *deviceKey;
@property (nonatomic,retain) NSString *email;
@property BOOL alreadyRegistered;
@property (nonatomic) int delay;
@property BOOL missing;
@property (getter = isPro) BOOL pro;
@property (nonatomic) BOOL askForPassword;
@property (nonatomic) BOOL camouflageMode;
@property (nonatomic) BOOL intervalMode;
@property (nonatomic) BOOL alertOnReport;

+ (PreyConfig*) instance;
+ (PreyConfig*) initWithUser:(User*)user andDevice:(Device*)device;
+ (PreyConfig*) initWithApiKey:(NSString*)apiKeyUser andDevice:(Device*)device;
- (NSString *) deviceCheckPathWithExtension: (NSString *) extension;
- (NSString *) readConfigValueForKey: (NSString *) key;
- (void) updateMissingStatus; //get status from Control Panel
- (void) loadDefaultValues;
- (void) saveValues;
- (void) detachDevice;
@end
