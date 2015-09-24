//
//  PreyStatusClientV2.h
//  Prey
//
//  Created by Javier Cala Uribe on 6/4/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPSessionManager.h"

@interface PreyStatusClientV2 : AFHTTPSessionManager

+ (PreyStatusClientV2 *)sharedClient;
+ (NSString *)userAgent;

@end
