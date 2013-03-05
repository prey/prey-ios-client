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
    NSString* publicIp = [self whatismyipdotcom];
    [super sendHttp:[super createResponseFromString:publicIp withKey:[self getName]]];
}

- (NSString *) getName {
	return @"public_ip";
}

- (NSString *) whatismyipdotcom
{
	NSError *error;
    NSURL *ipURL = [NSURL URLWithString:@"http://ifconfig.me/ip"];
    NSString *ip = [NSString stringWithContentsOfURL:ipURL encoding:1 error:&error];
	return ip ? ip : [error localizedDescription];
}

@end
