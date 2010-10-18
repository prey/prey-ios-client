//
//  DeviceModulesConfig.m
//  Prey
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "DeviceModulesConfig.h"
#import "PreyModule.h"


@implementation DeviceModulesConfig

@synthesize missing,postUrl,delay,modules;

- (id) init {
	self = [super init];
	if (self != nil) {
		self.modules = [[NSMutableArray alloc] init];
	}
	return self;
}
- (void) addModuleName: (NSString *) name ifActive: (NSString *) isActive {

	if ([isActive isEqualToString:@"true"]) {
		PreyModule *module = [PreyModule getModuleForName:name];
		if (module != nil)
			[self.modules addObject:module];
	}
}

- (void) addConfigValue: (NSString *) value withKey: (NSString *) key forModuleName: (NSString *) name {
	PreyModule *module;
	for (module in modules){
        if ([[module getName] isEqualToString:name])
			[module.configParms setObject:value forKey:key];
	}
}

@end
