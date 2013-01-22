//
//  Uptime.m
//  Prey
//
//  Created by Carlos Yaconi on 22-01-13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "Uptime.h"
#include "sys/sysctl.h"

@implementation Uptime

- (void) get {
    struct timeval boottime;
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    size_t size = sizeof(boottime);
    time_t now;
    time_t uptime = -1;
    
    (void)time(&now);
    
    if (sysctl(mib, 2, &boottime, &size, NULL, 0) != -1 && boottime.tv_sec != 0)
    {
        uptime = now - boottime.tv_sec;
    }
    
    NSDate *bootTime = [NSDate dateWithTimeIntervalSince1970:uptime];
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
    
    [super sendData:[dateFormatter stringFromDate:bootTime] forKey:[self getName]];
    
    [dateFormatter release];  // delete this line if using ARC
}

- (NSString *) getName {
	return @"uptime";
}

@end
