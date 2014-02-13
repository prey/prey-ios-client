//
//  NewModulesConfig.m
//  Prey
//
//  Created by Carlos Yaconi on 11-01-13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "NewModulesConfig.h"
#import "PreyModule.h"

@implementation NewModulesConfig

- (id) init {
	self = [super init];
	if (self != nil) {
		dataModules = [[NSMutableArray alloc] init];
		actionModules = [[NSMutableArray alloc] init];
        settingModules = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) addModule: (NSDictionary *) jsonModuleConfig {
    
    PreyLogMessage(@"NewModulesConfig", 10, @"target:%@  command:%@",[jsonModuleConfig objectForKey:@"target"] ,[jsonModuleConfig objectForKey:@"command"]);
    
    PreyModule *module = [[PreyModule newModuleForName:[jsonModuleConfig objectForKey:@"target"] andCommand:[jsonModuleConfig objectForKey:@"command"]] retain] ;
    if (module != nil){
        module.command = [jsonModuleConfig objectForKey:@"command"];
        module.options = [jsonModuleConfig objectForKey:@"options"];
        
        if (module.type == DataModuleType)
            [dataModules addObject:module];
        else if (module.type == ActionModuleType)
            [actionModules addObject:module];
        else if (module.type == SettingModuleType)
            [settingModules addObject:module];
    }
    
    [module release];
}

- (void) runAllModules {
    PreyModule *module;
    
	for (module in dataModules){
        [module performSelectorOnMainThread:NSSelectorFromString(module.command) withObject:nil waitUntilDone:YES];
        //[module performSelector:NSSelectorFromString(module.command)];
	}
    for (module in actionModules){
        [module performSelectorOnMainThread:NSSelectorFromString(module.command) withObject:nil waitUntilDone:YES];
        //[module performSelector:NSSelectorFromString(module.command)];
	}
    for (module in settingModules){
        [module performSelectorOnMainThread:NSSelectorFromString(module.command) withObject:nil waitUntilDone:YES];
        //[module performSelector:NSSelectorFromString(module.command)];
	}
}

@end
