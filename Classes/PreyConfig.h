//
//  PreyConfig.h
//  Prey
//
//  Created by Carlos Yaconi on 01/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
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
	
	
}
@property (nonatomic,retain) NSString *apiKey;
@property (nonatomic,retain) NSString *deviceKey;
@property (nonatomic,retain) NSString *checkUrl;
@property (nonatomic,retain) NSString *email;
@property BOOL alreadyRegistered;
@property (nonatomic) double desiredAccuracy;
@property (nonatomic) int delay;
@property BOOL missing;
@property (nonatomic) BOOL askForPassword;
@property (nonatomic) BOOL alertOnReport;
@property (nonatomic) BOOL camouflageMode;

+ (PreyConfig*) instance;
+ (PreyConfig*) initWithUser:(User*)user andDevice:(Device*)device;
- (void) updateMissingStatus; //get status from Control Panel
- (void) loadDefaultValues;
- (void) saveValues;
- (void) detachDevice;
@end
