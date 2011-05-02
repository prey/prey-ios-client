//
//  IphoneInformationHelper.m
//  Prey
//
//  Created by Carlos Yaconi on 30/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "IphoneInformationHelper.h"


@implementation IphoneInformationHelper

@synthesize name, type, os, version, macAddress,vendor,model, uuid;

+(IphoneInformationHelper*) initializeWithValues{ 
	IphoneInformationHelper *iphoneInfo = [[[IphoneInformationHelper alloc] init] autorelease];
	iphoneInfo.name = [[UIDevice currentDevice] name];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        iphoneInfo.type = @"Tablet";
    else
        iphoneInfo.type = @"Phone";
	
	iphoneInfo.os = @"Ios"; //change to iOS
    iphoneInfo.vendor = @"Apple";
    iphoneInfo.model = [[UIDevice currentDevice] platformString];
	iphoneInfo.version = [[UIDevice currentDevice] systemVersion];
	iphoneInfo.macAddress = [[UIDevice currentDevice] macaddress] != NULL ? [[UIDevice currentDevice] macaddress] :@"";
	iphoneInfo.uuid = [[UIDevice currentDevice] uniqueIdentifier];
	return iphoneInfo;
}

@end
