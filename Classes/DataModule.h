//
//  DataModule.h
//  Prey
//
//  Created by Carlos Yaconi on 18-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PreyRestHttp.h"
#import "PreyConfig.h"
#import "PreyModule.h"

@interface DataModule : PreyModule {

    NSString* endpoint;
}

- (void) get;
- (void) sendData: (NSString*) data;
- (void) setEndpoint: (NSString*) url;

@end
