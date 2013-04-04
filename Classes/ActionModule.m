//
//  ActionModule.m
//  Prey
//
//  Created by Carlos Yaconi on 11-01-13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "ActionModule.h"
#import "PreyConfig.h"
#import "PreyRestHttp.h"

@implementation ActionModule

- (id) init {
	self = [super init];
	if (self != nil)
		self.type = ActionModuleType;
	return self;
}

- (void) notifyEvent:(NSString *) name withInfo: (NSString*) info  {
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [data setObject:name forKey:@"name"];
    [data setObject:info forKey:@"info"];
    [dict setObject:data forKey:@"event"];
    
    PreyRestHttp* http = [[PreyRestHttp alloc] init];
    [http notifyEvent:dict];
}

@end
