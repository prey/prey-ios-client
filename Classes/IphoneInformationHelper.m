//
//  IphoneInformationHelper.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 30/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "IphoneInformationHelper.h"
#import "UIDevice-Hardware.h"

@implementation IphoneInformationHelper

@synthesize name, type, os, version, macAddress,vendor,model, uuid;

+(IphoneInformationHelper*) initializeWithValues{ 
	IphoneInformationHelper *iphoneInfo = [[[IphoneInformationHelper alloc] init] autorelease];
	iphoneInfo.name = [[UIDevice currentDevice] name];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        iphoneInfo.type = @"Tablet";
    else
        iphoneInfo.type = @"Phone";
	
	iphoneInfo.os = @"iOS";
    iphoneInfo.vendor = @"Apple";
    iphoneInfo.model = [[UIDevice currentDevice] platformString];
	iphoneInfo.version = [[UIDevice currentDevice] systemVersion];
	iphoneInfo.macAddress = [[UIDevice currentDevice] macaddress] != NULL ? [[UIDevice currentDevice] macaddress] :@"";
	iphoneInfo.uuid = [[UIDevice currentDevice] uniqueIdentifier];
	return iphoneInfo;
}

@end
