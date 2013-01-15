//
//  PublicIp.m
//  Prey
//
//  Created by Carlos Yaconi on 15-01-13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "PublicIp.h"
#import "UIDevice-Reachability.h"

@implementation PublicIp

- (void) get {
    NSString* publicIp = [[UIDevice currentDevice] whatismyipdotcom] != NULL ? [[UIDevice currentDevice] whatismyipdotcom] :@"0.0.0.0";
    [super sendData:publicIp forKey:[self getName]];
}

- (NSString *) getName {
	return @"public_ip";
}

@end
