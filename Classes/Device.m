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
#import "UIDevice-Hardware.h"

@implementation Device

@synthesize deviceKey, name, type, vendor, model, os, version, macAddress, uuid, cpu_model, cpu_cores, cpu_speed, ram_size;


+ (void)newDeviceForApiKey:(User*)userKey withBlock:(void (^)(User *user, Device *dev, NSError *error))block
{
    Device *newDevice = [[Device alloc] init];
	IphoneInformationHelper *iphoneInfo = [IphoneInformationHelper instance];
	[newDevice setOs: [iphoneInfo os]];
	[newDevice setVersion: [iphoneInfo version]];
	[newDevice setType: [iphoneInfo type]];
	[newDevice setMacAddress: [iphoneInfo macAddress]];
	[newDevice setName: [iphoneInfo name]];
    [newDevice setVendor: [iphoneInfo vendor]];
    [newDevice setModel: [iphoneInfo model]];
    [newDevice setUuid: [iphoneInfo uuid]];

    float frequency_cpu = [[UIDevice currentDevice] cpuFrequency] / 1000000;
    
    [newDevice setCpu_model:[[UIDevice currentDevice] hwmodel]];
    [newDevice setCpu_cores:[NSString stringWithFormat:@"%lu",(unsigned long)[[UIDevice currentDevice] cpuCount]]];
    [newDevice setCpu_speed:[NSString stringWithFormat:@"%f",frequency_cpu]];
    
    [newDevice setRam_size:[NSString stringWithFormat:@"%lu",(unsigned long)([[UIDevice currentDevice] totalMemory]/1024/1024)]];

    
    [[PreyRestHttp getClassVersion] createDeviceKeyForDevice:5 withDevice:newDevice usingApiKey:[userKey apiKey]
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
