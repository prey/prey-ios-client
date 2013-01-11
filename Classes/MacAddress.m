//
//  MacAddress.m
//  Prey
//
//  Created by Carlos Yaconi on 18-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import "MacAddress.h"

@implementation MacAddress

- (void) get {
    NSString* macAddress = [[UIDevice currentDevice] macaddress] != NULL ? [[UIDevice currentDevice] macaddress] :@"";
//    return macAddress;
}

@end
