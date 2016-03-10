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
#import "Constants.h"

@implementation IphoneInformationHelper

@synthesize name, type, os, version, macAddress,vendor,model, uuid;

+ (IphoneInformationHelper *)instance {
    static IphoneInformationHelper *instance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[IphoneInformationHelper alloc] init];
        instance.name = [[UIDevice currentDevice] name];
        instance.type = (IS_IPAD) ? @"Tablet" : @"Phone";
        instance.os = @"iOS";
        instance.vendor = @"Apple";
        instance.model = [self deviceModel];
        instance.version = [[UIDevice currentDevice] systemVersion];
        instance.macAddress = [[UIDevice currentDevice] macaddress] != NULL ? [[UIDevice currentDevice] macaddress] :@"";
        instance.uuid = (IS_OS_6_OR_LATER) ? [[[UIDevice currentDevice] identifierForVendor] UUIDString] : [IphoneInformationHelper deviceId];
    });
    
    return instance;
}

+ (NSString*)deviceId
{
    NSString *uniqueID;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id uuid = [defaults objectForKey:@"uniqueID"];
    
    if (uuid)
        uniqueID = (NSString *)uuid;
    else
    {
        CFUUIDRef cfUuid = CFUUIDCreate(NULL);
        CFStringRef cfUuidString = CFUUIDCreateString(NULL, cfUuid);
        CFRelease(cfUuid);
        uniqueID = (__bridge NSString *)cfUuidString;
        [defaults setObject:uniqueID forKey:@"uniqueID"];
        CFRelease(cfUuidString);
    }
    
    return uniqueID;
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
      @"iPhone7,1":    @"iPhone 6 Plus",
      @"iPhone7,2":    @"iPhone 6",
      @"iPhone8,1":    @"iPhone 6S",
      @"iPhone8,2":    @"iPhone 6S Plus",
      
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
      @"iPad4,1":  @"iPad Air",
      @"iPad4,2":  @"iPad Air (Wifi+Cellular)",
      @"iPad4,3":  @"iPad Air (Wifi+Cellular CN)",
      @"iPad4,4":  @"iPad Mini Retina(WiFi)",
      @"iPad4,5":  @"iPad Mini Retina(WiFi+Cellular)",
      @"iPad4,6":  @"iPad Mini Retina(WiFi+Cellular CN)",
      @"iPad4,7":  @"iPad Mini 3(WiFi)",
      @"iPad4,8":  @"iPad Mini 3(WiFi+Cellular)",
      @"iPad4,9":  @"iPad Mini 3(WiFi+Cellular CN)",
      @"iPad5,1":  @"iPad Mini 4(WiFi)",
      @"iPad5,2":  @"iPad Mini 4(WiFi+Cellular)",
      @"iPad5,3":  @"iPad Air 2 (Wifi)",
      @"iPad5,4":  @"iPad Air 2 (Wifi+Cellular)",
      @"iPad6,7":  @"iPad Pro (Wifi)",
      @"iPad6,8":  @"iPad Pro (Wifi+Cellular)",
      
      @"iPod1,1":  @"iPod Touch 1G",
      @"iPod2,1":  @"iPod Touch 2G",
      @"iPod3,1":  @"iPod Touch 3G",
      @"iPod4,1":  @"iPod Touch 4G",
      @"iPod5,1":  @"iPod Touch 5G",
      @"iPod7,1":  @"iPod Touch 6G",
      };
    
    NSString *deviceName = commonNamesDictionary[machineName];
    
    if (deviceName == nil) {
        deviceName = machineName;
    }
    
    return deviceName;
}


@end
