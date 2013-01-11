//
//  JsonConfigParser.m
//  Prey
//
//  Created by Carlos Yaconi on 18-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import "JsonConfigParser.h"


@implementation JsonConfigParser


- (DeviceModulesConfig*) parseModulesConfig:(NSData *)request parseError:(NSError **)err {
    
    SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
    NSArray *jsonObjects = (NSArray*)[jsonParser objectWithData:[request responseData] error:&err];
    for (NSDictionary *dict in jsonObjects)
    {
        //Every json array element
    }
    [jsonParser release], jsonParser = nil;
}

@end
