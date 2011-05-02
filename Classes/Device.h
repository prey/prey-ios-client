//
//  Device.h
//  prey-installer-cocoa
//
//  Created by Carlos Yaconi on 18-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Device : NSObject {
	
	NSString *deviceKey;
	NSString *name;
	NSString *type;
	NSString *model;
    NSString *vendor;
    NSString *os;
    NSString *version;
	NSString *macAddress;
    NSString *uuid;
    
}

@property (nonatomic,retain) NSString *deviceKey;
@property (nonatomic,retain) NSString *name;
@property (nonatomic,retain) NSString *type;
@property (nonatomic,retain) NSString *vendor;
@property (nonatomic,retain) NSString *model;
@property (nonatomic,retain) NSString *os;
@property (nonatomic,retain) NSString *version;
@property (nonatomic,retain) NSString *macAddress;
@property (nonatomic,retain) NSString *uuid;


+(Device*) newDeviceForApiKey: (NSString*) apiKey;
+(Device*) allocInstance;
-(void) detachDevice;

@end
