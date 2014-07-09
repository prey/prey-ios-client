//
//  Device.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 18-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

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

@property (nonatomic) NSString *deviceKey;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *type;
@property (nonatomic) NSString *vendor;
@property (nonatomic) NSString *model;
@property (nonatomic) NSString *os;
@property (nonatomic) NSString *version;
@property (nonatomic) NSString *macAddress;
@property (nonatomic) NSString *uuid;

+ (void)newDeviceForApiKey:(User*)userKey withBlock:(void (^)(User *user, Device *dev, NSError *error))block;

@end
