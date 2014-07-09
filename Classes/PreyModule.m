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
#import "ReportModule.h"
#import "Location.h"
#import "CamouflageModule.h"
#import "ContactsModule.h"

@implementation PreyModule

@synthesize options, type, command;

- (id) init {
	self = [super init];
	if(self != nil)
		options = [[NSMutableDictionary alloc] init];
	return self;
}

+ (PreyModule *) newModuleForName: (NSString *) moduleName andCommand: (NSString *) command{
    if ([moduleName isEqualToString:@"geofencing"]) {
		return [[GeofencingModule alloc] init];
	}
	if ([moduleName isEqualToString:@"alarm"]) {
		return [[AlarmModule alloc] init];
	}
	if ([moduleName isEqualToString:@"alert"]) {
		return [[AlertModule alloc] init];
	}
    if ([moduleName isEqualToString:@"camouflage"]) {
		return [[CamouflageModule alloc] init];
	}    
    if ([moduleName isEqualToString:@"report"])
    {
        NSInteger requestNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"requestNumber"] + 1;
        [[NSUserDefaults standardUserDefaults] setInteger:requestNumber forKey:@"requestNumber"];

		return [ReportModule instance];
	}
    if ([moduleName isEqualToString:@"picture"]) {
		return [[PictureModule alloc] init];
	}
    if ([moduleName isEqualToString:@"public_ip"]) {
		return [[PublicIp alloc] init];
	}
    if ([moduleName isEqualToString:@"private_ip"]) {
		return [[PrivateIp alloc] init];
	}
    if ([moduleName isEqualToString:@"first_mac_address"]) {
		return [[MacAddress alloc] init];
	}
    if ([moduleName isEqualToString:@"firmware_info"]) {
		return [[FirmwareInfo alloc] init];
	}
    if ([moduleName isEqualToString:@"battery_status"]) {
		return [[BatteryStatus alloc] init];
	}
    if ([moduleName isEqualToString:@"processor_info"]) {
		return [[ProcessorInfo alloc] init];
	}
    if ([moduleName isEqualToString:@"uptime"]) {
		return [[Uptime alloc] init];
	}    
    if ([moduleName isEqualToString:@"remaining_storage"]) {
		return [[RemainingStorage alloc] init];
	}
    if ([moduleName isEqualToString:@"location"]) {
		return [[Location alloc] init];
	}
    if ([moduleName isEqualToString:@"contacts_backup"]) {
		return [[ContactsModule alloc] init];
	}
    
    
    if ([command isEqualToString:@"read"] || [command isEqualToString:@"update"] || [command isEqualToString:@"toggle"]) { //Setting Module
        SettingModule *settingModule = [[SettingModule alloc]init];
        settingModule.setting = moduleName;
    }
	return nil;
}

- (NSString *) getName {
	return nil; //must be overriden;
}

@end
