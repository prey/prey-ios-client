//
//  FirmwareInfo.m
//  Prey
//
//  Created by Carlos Yaconi on 15-01-13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "FirmwareInfo.h"


@implementation FirmwareInfo

- (void) get {
    NSString* uuid = [[UIDevice currentDevice] uniqueIdentifier] != NULL ? [[UIDevice currentDevice] uniqueIdentifier] :@"";
    [super sendData:uuid forKey:@"uuid"];
}

- (NSString *) getName {
	return @"firmware_info";
}

@end
