//
//  ProcessorInfo.m
//  Prey
//
//  Created by Carlos Yaconi on 22-01-13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "ProcessorInfo.h"
#import "UIDevice-Hardware.h"

@implementation ProcessorInfo

- (void) get {
    NSUInteger speed = [[UIDevice currentDevice] cpuFrequency];
    NSUInteger cores = [[UIDevice currentDevice] cpuCount];
    NSString *model =[[UIDevice currentDevice] hwmodel];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[NSString stringWithFormat:@"%d",speed] forKey:@"speed"];
    [dict setObject:[NSString stringWithFormat:@"%d",cores] forKey:@"cores"];
    [dict setObject:model forKey:@"model"];
    [super sendHttp:[super createResponseFromObject:dict]];
    
}

- (NSString *) getName {
	return @"battery_status";
}

@end
