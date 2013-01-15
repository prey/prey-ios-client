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
		return [[[LocationModule alloc] init] autorelease];
	}
    if ([moduleName isEqualToString:@"geofencing"]) {
		return [[[GeofencingModule alloc] init] autorelease];
	}
	if ([moduleName isEqualToString:@"alarm"]) {
		return [[[AlarmModule alloc] init] autorelease];
	}
	if ([moduleName isEqualToString:@"alert"]) {
		return [[[AlertModule alloc] init] autorelease];
	}
    if ([moduleName isEqualToString:@"webcam"]) {
		return [[[PictureModule alloc] init] autorelease];
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
