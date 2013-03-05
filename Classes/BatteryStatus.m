//
//  BatteryStatus.m
//  Prey
//
//  Created by Carlos Yaconi on 22-01-13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "BatteryStatus.h"

@implementation BatteryStatus

- (void) get {
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    NSArray *batteryStatus = [NSArray arrayWithObjects:
                              @"Battery status is unknown.",
                              @"Battery is in use (discharging).",
                              @"Battery is charging.",
                              @"Battery is fully charged.", nil];
    
    if ([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateUnknown)
        state = [batteryStatus objectAtIndex:0];
    else
        state = [batteryStatus objectAtIndex:[[UIDevice currentDevice] batteryState]];

    remaining = [NSString stringWithFormat: @"%0.2f%%", [[UIDevice currentDevice] batteryLevel] * 100];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:state forKey:@"state"];
    [dict setObject:remaining forKey:@"remaining"];
    [super sendHttp:[super createResponseFromObject:dict]];
}

- (NSString *) getName {
	return @"battery_status";
}

@end
