//
//  DataModule.m
//  Prey
//
//  Created by Carlos Yaconi on 18-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import "DataModule.h"


@implementation DataModule

NSString * const DATA_URL = @"http://newpanel.share.cl:3000/devices/%@/data";

- (void) get {/* To be overriden */}

- (void) sendData: (NSDictionary*) data {
    if (endpoint == nil){
        PreyConfig* preyConfig = [PreyConfig instance];
        endpoint = [NSString stringWithFormat:DATA_URL, [preyConfig deviceKey]];
    }
    PreyRestHttp* http = [[PreyRestHttp alloc] init];
    [http sendData:data toEndpoint:endpoint];
}

- (void) setEndpoint: (NSString*) url {
    endpoint = url;
}

@end
