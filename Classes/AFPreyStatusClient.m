//
//  AFPreyStatusClient.m
//  Prey
//
//  Created by Javier Cala Uribe on 6/4/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

#import "AFPreyStatusClient.h"
#import "AFHTTPRequestOperation.h"
#import "Constants.h"
#import "PreyConfig.h"

@implementation AFPreyStatusClient

+ (AFPreyStatusClient *)sharedClient {
    static AFPreyStatusClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[AFPreyStatusClient alloc] initWithBaseURL:[NSURL URLWithString:DEFAULT_CONTROL_PANEL_HOST]];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    [self setDefaultHeader:@"User-Agent" value:[self userAgent]];
    [self setDefaultHeader:@"Content-Type" value:@"application/json"];
    [self setParameterEncoding:AFFormURLParameterEncoding];
    [self setAuthorizationHeaderWithUsername:[[PreyConfig instance] apiKey] password:@"x"];
    
    return self;
}

-(NSString *)userAgent {
    NSString *deviceName;
    NSString *OSName;
    NSString *OSVersion;
    //NSString *locale = [[NSLocale currentLocale] localeIdentifier];
    
    UIDevice *device = [UIDevice currentDevice];
    deviceName = [device model];
    OSName = [device systemName];
    OSVersion = [device systemVersion];
    
    // Takes the form "My Application 1.0 (Macintosh; Mac OS X 10.5.7; en_GB)"
    //return [NSString stringWithFormat:@"Prey/%@ (%@; %@ %@; %@)", [Constants appVersion], deviceName, OSName, OSVersion, locale];
    return [NSString stringWithFormat:@"Prey/%@ (iOS %@)", [Constants appVersion], OSVersion];
}

@end
