//
//  DataModule.m
//  Prey
//
//  Created by Carlos Yaconi on 18-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import "DataModule.h"


@implementation DataModule

- (id) init {
	self = [super init];
	if (self != nil)
		self.type = DataModuleType;
	return self;
}

- (void) get {/* To be overriden by each data modules */}

- (void) sendData: (NSString*) value forKey: (NSString*) key {
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [data setObject:value forKey:key];
    [dict setObject:data forKey:@"data"];

    PreyRestHttp* http = [[PreyRestHttp alloc] init];
    [http sendData:dict];
}


@end
