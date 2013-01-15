//
//  PrivateIp.m
//  Prey
//
//  Created by Carlos Yaconi on 15-01-13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "PrivateIp.h"
#import "UIDevice-Reachability.h"

@implementation PrivateIp

- (void) get {
    NSString* localWiFiIPAddress = [[UIDevice currentDevice] localWiFiIPAddress] != NULL ? [[UIDevice currentDevice] localWiFiIPAddress] :@"0.0.0.0";
    [super sendData:localWiFiIPAddress forKey:[self getName]];
}

- (NSString *) getName {
	return @"private_ip";
}

@end
