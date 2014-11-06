//
//  JsonConfigParser.h
//  Prey
//
//  Created by Carlos Yaconi on 18-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NewModulesConfig.h"
#import "User.h"

@interface JsonConfigParser : NSObject {
    
    
}

- (NewModulesConfig*) parseModulesConfig:(NSString *)request parseError:(NSError **)err;
- (NSString*)parseKey:(NSString *)request parseError:(NSError **)err;
- (void)parseRequest:(NSString *)request forUser:(User *)user parseError:(NSError **)err;

@end
