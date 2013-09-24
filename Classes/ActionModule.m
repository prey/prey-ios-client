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

- (void) notifyCommandResponse:(NSString *)target withStatus: (NSString*)status
{
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:status forKey:@"status"];
    [data setObject:target forKey:@"target"];
    [data setObject:@"start" forKey:@"command"];
    
    PreyRestHttp* http = [[PreyRestHttp alloc] init];
    [http notifyCommandResponse:data];
}

@end
