//
//  RestHttpUser.h
//  prey-installer-cocoa
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


@interface PreyRestHttp : NSObject {
	NSMutableData *responseData;
	NSURL *baseURL;
}

@property (retain) NSMutableData *responseData;
@property (retain) NSURL *baseURL;


- (NSString *) getCurrentControlPanelApiKey: (User *) user;
- (NSString *) createApiKey: (User *) user;
- (NSString *) createDeviceKeyForDevice: (Device*) device usingApiKey: (NSString *) apiKey;
- (BOOL) deleteDevice: (Device*) device ofUser: (User *) user;
- (BOOL) validateIfExistApiKey: (NSString *) apiKey andDeviceKey: (NSString *) deviceKey;
- (NSString *) getErrorMessageFromXML: (NSData *) response;
- (NSString *) getXMLforUser: (NSString *) user device:(NSString *) device;


@end
