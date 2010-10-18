//
//  Device.m
//  prey-installer-cocoa
//
//  Created by Carlos Yaconi on 18-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//

#import "Device.h"
#import "PreyRestHttp.h"
#import "IphoneInformationHelper.h"


@implementation Device

@synthesize deviceKey, name, type, os, version, macAddress;


+(Device*) newDeviceForApiKey: (NSString*) apiKey{

	Device *newDevice = [[Device alloc] init];
	IphoneInformationHelper *iphoneInfo = [IphoneInformationHelper initializeWithValues];
	[newDevice setOs: [iphoneInfo os]];
	[newDevice setVersion: [iphoneInfo version]];
	[newDevice setType: [iphoneInfo type]];
	[newDevice setMacAddress: [iphoneInfo macAddress]];
	[newDevice setName: [iphoneInfo name]];
	
	PreyRestHttp *http = [[PreyRestHttp alloc] init];
	@try {
		[newDevice setDeviceKey:[http createDeviceKeyForDevice:newDevice usingApiKey:apiKey]];
	}
	@catch (NSException * e) {
		@throw;
	}
			
	return newDevice;


}

@end
