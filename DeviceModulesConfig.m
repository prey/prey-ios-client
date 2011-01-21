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

@synthesize missing,delay,reportModules,actionModules,reportToFill;

- (id) init {
	self = [super init];
	if (self != nil) {
		self.reportModules = [[NSMutableArray alloc] init];
		self.actionModules = [[NSMutableArray alloc] init];
		self.reportToFill = [[Report alloc] init];
	}
	return self;
}
- (void) addModuleName: (NSString *) name ifActive: (NSString *) isActive ofType: (NSString *) type {

	if ([isActive isEqualToString:@"true"]) {
		PreyModule *module = [PreyModule getModuleForName:name];
		if (module != nil){
			if ([type isEqualToString:@"report"]){
				module.type = ReportModuleType;
				[self.reportModules addObject:module];
			}
			else if ([type isEqualToString:@"action"]){
				module.type = ActionModuleType;
				[self.actionModules addObject:module];
			}
			[module setReportToFill:self.reportToFill];
		}
	}
}

- (void) addConfigValue: (NSString *) value withKey: (NSString *) key forModuleName: (NSString *) name {
	PreyModule *module;
	for (module in reportModules){
        if ([[module getName] isEqualToString:name])
			[module.configParms setObject:value forKey:key];
	}
	for (module in actionModules){
        if ([[module getName] isEqualToString:name])
			[module.configParms setObject:value forKey:key];
	}
}

- (BOOL) willRequireLocation{
	PreyModule *module;
	for (module in reportModules){
		if ([[module getName] isEqualToString:@"geo"])
			return YES;
	}
	return NO;
}

- (NSString *) postUrl {
	return postUrl;
}
- (void) setPostUrl: (NSString *) newUrl{
	postUrl = newUrl;
	self.reportToFill.url = newUrl;
}

@end
