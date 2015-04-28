//
//  Wifi-Info.m
//  Prey
//
//  Created by Javier Cala 28-04-15.
//  Copyright (c) 2015 Fork Ltd. All rights reserved.
//

#import "Wifi-Info.h"
#import <SystemConfiguration/CaptiveNetwork.h>

@implementation Wifi_Info

- (void) get {
}

- (NSString *) getName {
	return @"wifi-info";
}

+ (NSDictionary *)getSSIDInfo
{
    NSArray *interfaceNames = CFBridgingRelease(CNCopySupportedInterfaces());
    //NSLog(@"%s: Supported interfaces: %@", __func__, interfaceNames);
    
    NSDictionary *SSIDInfo;
    for (NSString *interfaceName in interfaceNames)
    {
        SSIDInfo = CFBridgingRelease(CNCopyCurrentNetworkInfo((__bridge CFStringRef)interfaceName));
        
        //NSLog(@"%s: %@ => %@", __func__, interfaceName, SSIDInfo);
        
        BOOL isNotEmpty = (SSIDInfo.count > 0);
        if (isNotEmpty)
            break;        
    }    
    return SSIDInfo;
}

@end
