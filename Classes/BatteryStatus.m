//
//  BatteryStatus.m
//  Prey
//
//  Created by Carlos Yaconi on 22-01-13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "BatteryStatus.h"

@implementation BatteryStatus

- (void) get
{
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    NSArray *batteryStatus = [NSArray arrayWithObjects: @"discharging", @"discharging", @"charging", @"charging", nil];
    
    if ([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateUnknown)
        state = [batteryStatus objectAtIndex:0];
    else
        state = [batteryStatus objectAtIndex:[[UIDevice currentDevice] batteryState]];

    remaining = [NSString stringWithFormat: @"%0.2f%%", [[UIDevice currentDevice] batteryLevel] * 100];
    
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:state forKey:@"state"];
    [data setObject:remaining forKey:@"percentage_remaining"];
    
    NSMutableDictionary *battery_status = [[NSMutableDictionary alloc] init];
    [battery_status setObject:data forKey:@"battery_status"];

    NSMutableDictionary *status = [[NSMutableDictionary alloc] init];
    [status setObject:battery_status forKey:@"status"];
    
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:@"" forKey:@"info"];
    [parameters setObject:@"ok_battery" forKey:@"name"];
    
    
    [super sendHttpEvent:status withParameters:parameters];
    
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:NO];
}

- (NSString *) getName {
	return @"battery_status";
}

@end
