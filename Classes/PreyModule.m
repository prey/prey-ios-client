//
//  PreyModule.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "PreyModule.h"
#import "LocationModule.h"
#import "AlarmModule.h"
#import "AlertModule.h"
#import "PictureModule.h"
#import "GeofencingModule.h"
#import "SettingModule.h"
#import "PublicIp.h"
#import "PrivateIp.h"
#import "MacAddress.h"
#import "FirmwareInfo.h"
#import "BatteryStatus.h"
#import "ProcessorInfo.h"
#import "Uptime.h"
#import "RemainingStorage.h"
#import "Location.h"

@implementation PreyModule

@synthesize options, type, command;

- (id) init {
	self = [super init];
	if(self != nil)
		options = [[NSMutableDictionary alloc] init];
	return self;
}

+ (PreyModule *) newModuleForName: (NSString *) moduleName andCommand: (NSString *) command{
	if ([moduleName isEqualToString:@"geo"]) {
		return [[LocationModule alloc] init];
	}
    if ([moduleName isEqualToString:@"geofencing"]) {
		return [[GeofencingModule alloc] init];
	}
	if ([moduleName isEqualToString:@"alarm"]) {
		return [[AlarmModule alloc] init];
	}
	if ([moduleName isEqualToString:@"alert"]) {
		return [[AlertModule alloc] init];
	}
    // JavierCode
    //if ([moduleName isEqualToString:@"webcam"]) {
	//	return [[PictureModule alloc] init];
    if ([moduleName isEqualToString:@"picture"]) {
		return [[[PictureModule alloc] init] autorelease];
	}
    if ([moduleName isEqualToString:@"public_ip"]) {
		return [[[PublicIp alloc] init] autorelease];
	}
    if ([moduleName isEqualToString:@"private_ip"]) {
		return [[[PrivateIp alloc] init] autorelease];
	}
    if ([moduleName isEqualToString:@"first_mac_address"]) {
		return [[[MacAddress alloc] init] autorelease];
	}
    if ([moduleName isEqualToString:@"firmware_info"]) {
		return [[[FirmwareInfo alloc] init] autorelease];
	}
    if ([moduleName isEqualToString:@"battery_status"]) {
		return [[[BatteryStatus alloc] init] autorelease];
	}
    if ([moduleName isEqualToString:@"processor_info"]) {
		return [[[ProcessorInfo alloc] init] autorelease];
	}
    if ([moduleName isEqualToString:@"uptime"]) {
		return [[[Uptime alloc] init] autorelease];
	}
    if ([moduleName isEqualToString:@"remaining_storage"]) {
		return [[[RemainingStorage alloc] init] autorelease];
	}
    if ([moduleName isEqualToString:@"location"]) {
		return [[[Location alloc] init] autorelease];
	}
    
    if ([command isEqualToString:@"read"] || [command isEqualToString:@"update"] || [command isEqualToString:@"toggle"]) { //Setting Module
        SettingModule *settingModule = [[[SettingModule alloc]init] autorelease];
        settingModule.setting = moduleName;
    }
	return nil;
}

- (NSString *) getName {
	return nil; //must be overriden;
}




-(void)dealloc {
    [super dealloc];
    [options release];
}

@end
