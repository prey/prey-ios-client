//
//  MacAddress.m
//  Prey
//
//  Created by Carlos Yaconi on 18-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import "MacAddress.h"
#import "UIDevice-Hardware.h"

@implementation MacAddress

- (void) get {
    NSString* macAddress = [[UIDevice currentDevice]  macaddress] != NULL ? [[UIDevice currentDevice] macaddress] :@"";
    [super sendData:macAddress forKey:[self getName]];
}

- (NSString *) getName {
	return @"first_mac_address";
}

@end
