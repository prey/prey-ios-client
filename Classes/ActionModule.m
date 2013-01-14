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

NSString * const POST_ACTION_URL = @"http://newpanel.share.cl:3000/devices/%@/action";

- (id) init {
	self = [super init];
	if (self != nil)
		self.type = ActionModuleType;
	return self;
}

- (void) notifyExecutionOfAction: (NSString *) action wasSuccessfully: (BOOL) executionResult  {
    if (endpoint == nil){
        PreyConfig* preyConfig = [PreyConfig instance];
        endpoint = [NSString stringWithFormat:POST_ACTION_URL, [preyConfig deviceKey]];
    }
    PreyRestHttp* http = [[PreyRestHttp alloc] init];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:action forKey:@"target"];
    [dict setObject:executionResult ? @"True" : @"False" forKey:@"exec_result"];
    
    [http sendData:dict toEndpoint:endpoint];
}

@end
