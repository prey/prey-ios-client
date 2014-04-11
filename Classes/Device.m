//
//  Device.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 18-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//

#import "Device.h"
#import "PreyRestHttp.h"
#import "IphoneInformationHelper.h"

@implementation Device

@synthesize deviceKey, name, type, vendor, model, os, version, macAddress, uuid;


+ (void)newDeviceForApiKey:(User*)userKey withBlock:(void (^)(User *user, Device *dev, NSError *error))block
{
    Device *newDevice = [[[Device alloc] init] autorelease];
	IphoneInformationHelper *iphoneInfo = [IphoneInformationHelper initializeWithValues];
	[newDevice setOs: [iphoneInfo os]];
	[newDevice setVersion: [iphoneInfo version]];
	[newDevice setType: [iphoneInfo type]];
	[newDevice setMacAddress: [iphoneInfo macAddress]];
	[newDevice setName: [iphoneInfo name]];
    [newDevice setVendor: [iphoneInfo vendor]];
    [newDevice setModel: [iphoneInfo model]];
    [newDevice setUuid: [iphoneInfo uuid]];

    [PreyRestHttp createDeviceKeyForDevice:newDevice usingApiKey:[userKey apiKey]
                                 withBlock:^(NSString *deviceKey, NSError *error)
    {
        if (error)
        {
            if (block) 
                block(nil, nil, error);
            
        } else
        {
            [newDevice setDeviceKey:deviceKey];
            
            if (block) {
                block(userKey, newDevice, nil);
            }
        }
    }];
}

@end
