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


- (NewModulesConfig*) parseModulesConfig:(NSString*)request parseError:(NSError **)err
{
    PreyLogMessage(@"JsonConfigParser", 10,@"Parse Modules Config");
    NSError *error = nil;
    NSData *jsonData = [request dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *jsonObjects = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    
    NewModulesConfig *modulesConfig = [[NewModulesConfig alloc] init];
    
    for (NSDictionary *dict in jsonObjects)
    {
        [modulesConfig addModule:dict];
    }
    
    return modulesConfig;
}

- (NSMutableSet *)parseStore:(NSString*)request parseError:(NSError **)err
{
    NSError *error = nil;
    NSData *jsonData = [request dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonObjects = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    
    NSMutableSet *products;
    
    if (jsonObjects != nil)
    {
        products = [[[NSMutableSet alloc] init] autorelease];
        
        for (NSMutableDictionary *item in [jsonObjects objectForKey:@"products"])
            [products addObject:item];
        
        [[NSUserDefaults standardUserDefaults] setObject:[jsonObjects objectForKey:@"landing_url"] forKey:@"LandingURL"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return products;
}

- (void)parseRequest:(NSString *)request forUser:(User *)user parseError:(NSError **)err
{
    NSError *error = nil;
    NSData *jsonData = [request dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonObjects = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];

    if (jsonObjects != nil)
    {
        user.apiKey = [jsonObjects objectForKey:@"key"];
        user.pro = [[jsonObjects objectForKey:@"pro_account"] boolValue];
    }
}

- (NSString*)parseKey:(NSString *)request parseError:(NSError **)err
{
    NSError *error = nil;
    NSData *jsonData = [request dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonObjects = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    
    return [jsonObjects objectForKey:@"key"];
}

@end
