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
#import <sys/utsname.h>
#import "MKStore/MKSKProduct.h"

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
    iphoneInfo.model = [self deviceModel];
	iphoneInfo.version = [[UIDevice currentDevice] systemVersion];
	iphoneInfo.macAddress = [[UIDevice currentDevice] macaddress] != NULL ? [[UIDevice currentDevice] macaddress] :@"";
	iphoneInfo.uuid = [MKSKProduct deviceId];
	return iphoneInfo;
}

+ (NSString *)deviceModel
{
    struct utsname systemInfo;
    
    uname(&systemInfo);
    
    NSString *machineName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    NSDictionary *commonNamesDictionary =
    @{
      @"i386":     @"iPhone Simulator",
      @"x86_64":   @"iPad Simulator",
      
      @"iPhone1,1":    @"iPhone",
      @"iPhone1,2":    @"iPhone 3G",
      @"iPhone2,1":    @"iPhone 3GS",
      @"iPhone3,1":    @"iPhone 4",
      @"iPhone3,2":    @"iPhone 4(Rev A)",
      @"iPhone3,3":    @"iPhone 4(CDMA)",
      @"iPhone4,1":    @"iPhone 4S",
      @"iPhone5,1":    @"iPhone 5(GSM)",
      @"iPhone5,2":    @"iPhone 5(GSM+CDMA)",
      @"iPhone5,3":    @"iPhone 5c(GSM)",
      @"iPhone5,4":    @"iPhone 5c(GSM+CDMA)",
      @"iPhone6,1":    @"iPhone 5s(GSM)",
      @"iPhone6,2":    @"iPhone 5s(GSM+CDMA)",
      
      @"iPad1,1":  @"iPad",
      @"iPad2,1":  @"iPad 2(WiFi)",
      @"iPad2,2":  @"iPad 2(GSM)",
      @"iPad2,3":  @"iPad 2(CDMA)",
      @"iPad2,4":  @"iPad 2(WiFi Rev A)",
      @"iPad2,5":  @"iPad Mini(WiFi)",
      @"iPad2,6":  @"iPad Mini(GSM)",
      @"iPad2,7":  @"iPad Mini(GSM+CDMA)",
      @"iPad3,1":  @"iPad 3(WiFi)",
      @"iPad3,2":  @"iPad 3(GSM+CDMA)",
      @"iPad3,3":  @"iPad 3(GSM)",
      @"iPad3,4":  @"iPad 4(WiFi)",
      @"iPad3,5":  @"iPad 4(GSM)",
      @"iPad3,6":  @"iPad 4(GSM+CDMA)",
      
      @"iPod1,1":  @"iPod Touch 1G",
      @"iPod2,1":  @"iPod Touch 2G",
      @"iPod3,1":  @"iPod Touch 3G",
      @"iPod4,1":  @"iPod Touch 4G",
      @"iPod5,1":  @"iPod Touch 5G",
      };
    
    NSString *deviceName = commonNamesDictionary[machineName];
    
    if (deviceName == nil) {
        deviceName = machineName;
    }
    
    return deviceName;
}


@end
