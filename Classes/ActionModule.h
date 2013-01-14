//
//  ActionModule.h
//  Prey
//
//  Created by Carlos Yaconi on 11-01-13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "PreyModule.h"

@interface ActionModule : PreyModule{

     NSString* endpoint;
}

- (void) notifyExecutionOfAction: (NSString *) action wasSuccessfully: (BOOL) executionResult;

@end
