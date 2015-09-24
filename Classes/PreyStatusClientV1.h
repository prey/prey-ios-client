//
//  PreyStatusClientV1.h
//  Prey
//
//  Created by Javier Cala Uribe on 6/4/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPClient.h"

@interface PreyStatusClientV1 : AFHTTPClient

+ (PreyStatusClientV1 *)sharedClient;
- (NSString *)userAgent;

@end
