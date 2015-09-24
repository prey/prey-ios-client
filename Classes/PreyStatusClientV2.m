//
//  PreyStatusClientV2.m
//  Prey
//
//  Created by Javier Cala Uribe on 6/4/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

#import "PreyStatusClientV2.h"
#import "Constants.h"
#import "PreyConfig.h"

@implementation PreyStatusClientV2

+ (PreyStatusClientV2 *)sharedClient {
    static PreyStatusClientV2 *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseURL = [NSURL URLWithString:DEFAULT_CONTROL_PANEL_HOST];
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        [config setHTTPAdditionalHeaders:@{ @"User-Agent" : [self userAgent]}];
        [config setHTTPAdditionalHeaders:@{ @"Content-Type" : @"application/json"}];
        
        _sharedClient.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
        _sharedClient.requestSerializer  = [AFJSONRequestSerializer serializer];
        [_sharedClient.requestSerializer setAuthorizationHeaderFieldWithUsername:[[PreyConfig instance] apiKey] password:@"x"];
        
        _sharedClient = [[PreyStatusClientV2 alloc] initWithBaseURL:baseURL sessionConfiguration:config];
    });
    
    return _sharedClient;
}

+ (NSString *)userAgent {
    //NSString *deviceName;
    //NSString *OSName;
    NSString *OSVersion;
    //NSString *locale = [[NSLocale currentLocale] localeIdentifier];
    
    UIDevice *device = [UIDevice currentDevice];
    //deviceName = [device model];
    //OSName = [device systemName];
    OSVersion = [device systemVersion];
    
    // Takes the form "My Application 1.0 (Macintosh; Mac OS X 10.5.7; en_GB)"
    //return [NSString stringWithFormat:@"Prey/%@ (%@; %@ %@; %@)", [Constants appVersion], deviceName, OSName, OSVersion, locale];
    return [NSString stringWithFormat:@"Prey/%@ (iOS %@)", [Constants appVersion], OSVersion];
}

@end
