//
//  DataModule.m
//  Prey
//
//  Created by Carlos Yaconi on 18-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import "DataModule.h"
#import "PreyRestHttp.h"

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
    
    [data setObject:[NSString stringWithFormat:@"data[%@]", key] forKey:@"key"];
    [data setObject:rawData forKey:@"data"];
    
    return data;
}

- (void) sendHttp: (NSMutableDictionary*) data {
    PreyRestHttp* http = [[PreyRestHttp alloc] init];
    [http sendData:data];
}

@end
