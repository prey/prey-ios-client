//
//  UserParserDelegate.h
//  Prey
//
//  Created by Diego Torres on 3/14/12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

enum UserProfileNode {
    UserProfileNodeUnknown = 0,
    UserProfileNodeKey,
    UserProfileNodeProAccount
};

@interface UserParserDelegate : NSObject <NSXMLParserDelegate> {
    
@private
    User *user;
	enum UserProfileNode currentNode;
}

- (NSString*) parseRequest:(NSData *)request forUser:(User*)user parseError:(NSError **)err;

@end