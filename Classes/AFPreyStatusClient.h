//
//  AFPreyStatusClient.h
//  Prey
//
//  Created by Javier Cala Uribe on 6/4/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPClient.h"

@interface AFPreyStatusClient : AFHTTPClient

+ (AFPreyStatusClient *)sharedClient;
- (NSString *)userAgent;

@end
