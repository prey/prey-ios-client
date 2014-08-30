//
//  NewModulesConfig.h
//  Prey
//
//  Created by Carlos Yaconi on 11-01-13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NewModulesConfig : NSObject {

    NSMutableArray *dataModules;
	NSMutableArray *actionModules;
    NSMutableArray *settingModules;
}


- (void) addModule: (NSDictionary *) jsonModuleConfig;
- (void) runAllModules;
- (BOOL) checkAllModulesEmpty;

@end
