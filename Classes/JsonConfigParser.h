//
//  JsonConfigParser.h
//  Prey
//
//  Created by Carlos Yaconi on 18-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NewModulesConfig.h"
#import "SBJsonParser.h"

@interface JsonConfigParser : NSObject {
    
    
}

- (NewModulesConfig*) parseModulesConfig:(NSString *)request parseError:(NSError **)err;

@end
