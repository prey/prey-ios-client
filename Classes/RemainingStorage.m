//
//  RemainingStorage.m
//  Prey
//
//  Created by Carlos Yaconi on 22-01-13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "RemainingStorage.h"
#import "UIDevice-Hardware.h"

@implementation RemainingStorage

- (void) get {
    
    NSNumber *totalDiskSpace = [[UIDevice currentDevice] totalDiskSpace];
    NSNumber *freeDiskSpace = [[UIDevice currentDevice] freeDiskSpace];
    NSNumber *usedDiskSpace = [NSNumber numberWithFloat:([totalDiskSpace floatValue] - [freeDiskSpace floatValue])];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[NSString stringWithFormat:@"\n\n%.2f GB",[totalDiskSpace floatValue] / 1024 / 1024 / 1024] forKey:@"total"];
    [dict setObject:[NSString stringWithFormat:@"\n\n%.2f GB",[freeDiskSpace floatValue] / 1024 / 1024 / 1024] forKey:@"free"];
    [dict setObject:[NSString stringWithFormat:@"\n\n%.2f GB",[usedDiskSpace floatValue] / 1024 / 1024 / 1024] forKey:@"used"];

    [super sendHttp:[super createResponseFromObject:dict]];
    
}

- (NSString *) getName {
	return @"remaining_storage";
}


@end
