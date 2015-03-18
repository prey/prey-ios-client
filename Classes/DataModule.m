//
//  DataModule.m
//  Prey
//
//  Created by Carlos Yaconi on 18-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import "DataModule.h"
#import "PreyRestHttp.h"
#import "PreyConfig.h"
#import "Constants.h"
#import "AFPreyStatusClient.h"

@implementation DataModule

- (id) init {
	self = [super init];
	if (self != nil)
		self.type = DataModuleType;
	return self;
}

- (void) get {/* To be overriden by each data modules */}


- (NSMutableDictionary*) createResponseFromString: (NSString*) value withKey: (NSString*) key {
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [data setObject:value forKey:key];
    [dict setObject:data forKey:@"data"];

    return data;
}

- (NSMutableDictionary*) createResponseFromObject: (NSDictionary*) dict {
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:dict forKey:@"data"];
    
    return data;
}

- (NSMutableDictionary*) createResponseFromObject: dict withKey:(NSString *) key{
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:dict forKey:key];
    
    return data;
}

- (NSMutableDictionary*) createResponseFromData: (NSData*) rawData withKey: (NSString*) key {
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:rawData forKey:key];
    
    return data;
}

- (void)sendHttpEvent:(NSMutableDictionary*)event withParameters:(NSMutableDictionary*)parameters
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:event options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString;
    
    if (jsonData)
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [[AFPreyStatusClient sharedClient] setDefaultHeader:@"X-Prey-Status" value:jsonString];
    
    [PreyRestHttp sendJsonData:5 withData:parameters
                    toEndpoint:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@/events",[[PreyConfig instance] deviceKey]]
                     withBlock:^(NSHTTPURLResponse *response, NSError *error) {
                         if (error) {
                             PreyLogMessage(@"DataModule", 10,@"Error: %@",error);
                         } else {
                             PreyLogMessage(@"DataModule", 10,@"DataModule: OK events");
                         }
                     }];
}

- (void)notifyCommandResponse:(NSString*)action withTarget:(NSString *)target withStatus:(NSString*)status withReason:(NSString*)reason
{
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:status forKey:@"status"];
    [data setObject:target forKey:@"target"];
    [data setObject:action forKey:@"command"];
    [data setObject:reason forKey:@"reason"];
    
    NSLog(@"info: %@", [data description]);
    
    [PreyRestHttp sendJsonData:5 withData:data
                    toEndpoint:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@/response",[[PreyConfig instance] deviceKey]]
                     withBlock:^(NSHTTPURLResponse *response, NSError *error) {
                         if (error) {
                             PreyLogMessage(@"DataModule", 10,@"Error: %@",error);
                         } else {
                             PreyLogMessage(@"DataModule", 10,@"DataModule: OK response");
                         }
                     }];
}


- (void)sendHttp:(NSMutableDictionary*)data
{
    [PreyRestHttp sendJsonData:5 withData:data
                    toEndpoint:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@/data",[[PreyConfig instance] deviceKey]]
                     withBlock:^(NSHTTPURLResponse *response, NSError *error) {
        if (error) {
            PreyLogMessage(@"DataModule", 10,@"Error: %@",error);
        } else {
            PreyLogMessage(@"DataModule", 10,@"DataModule: OK data");
        }
    }];
}

- (void)sendHttp:(NSMutableDictionary*)data andRaw:(NSMutableDictionary*) rawData
{
    [PreyRestHttp sendJsonData:5 withData:data andRawData:rawData
                    toEndpoint:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@/reports",[[PreyConfig instance] deviceKey]]
                     withBlock:^(NSHTTPURLResponse *response, NSError *error) {
                         if (error) {
                             PreyLogMessage(@"DataModule", 10,@"Error: %@",error);
                         } else {
                             PreyLogMessage(@"DataModule", 10,@"DataModule: OK report");
                         }
                     }];
}

@end
