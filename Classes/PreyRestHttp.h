//
//  RestHttpUser.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 18-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>


#import "User.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "RegexKitLite.h"
#import "Constants.h"
#import "Device.h"
#import "DeviceModulesConfig.h"
#import "KeyParserDelegate.h"
#import "UserParserDelegate.h"
#import "ErrorParserDelegate.h"
#import "JsonConfigParser.h"
#import "PreyConfig.h"
#import "Reachability.h"
#import "SBJson.h"



@interface PreyRestHttp : NSObject {
	NSMutableData *responseData;
	NSURL *baseURL;
}

@property (retain) NSMutableData *responseData;
@property (retain) NSURL *baseURL;


- (NSString *) getCurrentControlPanelApiKey: (User *) user;
- (NSString *) userAgent;
- (NSString *) createApiKey: (User *) user;
- (NSString *) createDeviceKeyForDevice: (Device*) device usingApiKey: (NSString *) apiKey;
- (BOOL) deleteDevice: (Device*) device;
- (BOOL) validateIfExistApiKey: (NSString *) apiKey andDeviceKey: (NSString *) deviceKey;
- (NSString *) getErrorMessageFromXML: (NSData *) response;
- (DeviceModulesConfig *) getXMLforUser;
- (BOOL) changeStatusToMissing: (BOOL) missing forDevice:(NSString *) deviceKey fromUser: (NSString *) apiKey;
- (BOOL) isMissingTheDevice: (NSString *) device ofTheUser: (NSString *) apiKey;
- (void) sendReport: (Report *) report;
+ (BOOL) checkInternet;
- (void) getAppstoreConfig: (id) delegate inURL: (NSString *) URL;
- (void) setPushRegistrationId: (NSString *) id;

#pragma mark -
#pragma mark New panel API

- (DeviceModulesConfig *) checkStatusForDevice: (NSString *) deviceKey andApiKey: (NSString *) apiKey;
- (void) notifyEvent: (NSDictionary*) data;
- (void) sendSetting: (NSDictionary*) data;
- (void) sendData: (NSDictionary*) data;

@end
