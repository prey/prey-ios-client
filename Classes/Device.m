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
#import "PreyConfig.h"

@implementation Device

@synthesize deviceKey, name, type, vendor, model, os, version, macAddress, uuid;


+(Device*) newDeviceForApiKey: (NSString*) apiKey{

	Device *newDevice = [[Device alloc] init];
	IphoneInformationHelper *iphoneInfo = [IphoneInformationHelper initializeWithValues];
	[newDevice setOs: [iphoneInfo os]];
	[newDevice setVersion: [iphoneInfo version]];
	[newDevice setType: [iphoneInfo type]];
	[newDevice setMacAddress: [iphoneInfo macAddress]];
	[newDevice setName: [iphoneInfo name]];
    [newDevice setVendor: [iphoneInfo vendor]];
    [newDevice setModel: [iphoneInfo model]];
    [newDevice setUuid: [iphoneInfo uuid]];
	
	PreyRestHttp *http = [[PreyRestHttp alloc] init];
	@try {
		[newDevice setDeviceKey:[http createDeviceKeyForDevice:newDevice usingApiKey:apiKey]];
	}
	@catch (NSException * e) {
		@throw;
	}
	[http release];
			
	return newDevice;
}

+(Device*) allocInstance{
	PreyConfig* preyConfig = [PreyConfig instance];
	Device* dev = [[Device alloc]init];
	[dev setDeviceKey:[preyConfig deviceKey]];
	return dev;
}

-(void) detachDevice {
	PreyRestHttp *http = [[PreyRestHttp alloc] init];
	[http deleteDevice: self];
	[http release];
	//[[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
}

@end
