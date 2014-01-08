//
//  JsonConfigParser.m
//  Prey
//
//  Created by Carlos Yaconi on 18-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import "JsonConfigParser.h"
#import "NewModulesConfig.h"

@implementation JsonConfigParser


- (NewModulesConfig*) parseModulesConfig:(NSString*)requestString parseError:(NSError **)err {
    
    SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
    NewModulesConfig *modulesConfig = [[NewModulesConfig alloc] init];
    
    NSArray *jsonObjects = (NSArray*)[jsonParser objectWithString:requestString];
    
    for (NSDictionary *dict in jsonObjects)
    {
        [modulesConfig addModule:dict];
    }
    
    [jsonParser release], jsonParser = nil;
    return modulesConfig;
}


@end
