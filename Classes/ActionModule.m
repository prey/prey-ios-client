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
#import "Constants.h"

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
    
    [PreyRestHttp sendJsonData:5 withData:data
                    toEndpoint:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@/response",[[PreyConfig instance] deviceKey]]
                     withBlock:^(NSHTTPURLResponse *response, NSError *error) {
                         if (error) {
                             PreyLogMessage(@"ActionModule", 10,@"Error: %@",error);
                         } else {
                             PreyLogMessage(@"ActionModule", 10,@"ActionModule: OK response");
                         }
                     }];
}

@end