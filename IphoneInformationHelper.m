//
//  IphoneInformationHelper.m
//  Prey
//
//  Created by Carlos Yaconi on 30/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "IphoneInformationHelper.h"


@implementation IphoneInformationHelper

@synthesize name, type, os, version, macAddress;

+(IphoneInformationHelper*) initializeWithValues{ 
	IphoneInformationHelper *iphoneInfo = [[[IphoneInformationHelper alloc] init] autorelease];
	iphoneInfo.name = [[UIDevice currentDevice] name];
	iphoneInfo.type = @"Phone";
	iphoneInfo.os = @"Android"; //change to iOS
	iphoneInfo.version = [[UIDevice currentDevice] systemVersion];
	iphoneInfo.macAddress = @"";
	
	return iphoneInfo;
}

@end
