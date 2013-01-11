//
//  JsonConfigParser.h
//  Prey
//
//  Created by Carlos Yaconi on 18-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeviceModulesConfig.h"
#import "SBJsonParser.h"

@interface JsonConfigParser : NSObject {
    
    BOOL inMissing;
    BOOL inDelay;
    BOOL inPostUrl;
    BOOL inModules;
    BOOL inModule;
    BOOL inCameraToUse;
    BOOL inAccuracy;
    DeviceModulesConfig *modulesConfig;
    
}

- (DeviceModulesConfig*) parseModulesConfig:(NSData *)request parseError:(NSError **)err;

@end
