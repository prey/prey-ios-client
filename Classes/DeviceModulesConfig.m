//
//  DeviceModulesConfig.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "DeviceModulesConfig.h"
#import "PreyModule.h"


@implementation DeviceModulesConfig

@synthesize missing,delay,reportModules,actionModules,reportToFill;

- (id) init {
	self = [super init];
	if (self != nil) {
		reportModules = [[NSMutableArray alloc] init];
		actionModules = [[NSMutableArray alloc] init];
		reportToFill  = [[Report alloc] init];
	}
	return self;
}
- (void) addModuleName: (NSString *) name ifActive: (NSString *) isActive ofType: (NSString *) type {

	if ([isActive isEqualToString:@"true"]) {
		PreyModule *module = [PreyModule newModuleForName:name];
		if (module != nil){
			if ([type isEqualToString:@"report"]){
				module.type = ReportModuleType;
				[reportModules addObject:module];
			}
			else if ([type isEqualToString:@"action"]){
				module.type = ActionModuleType;
				[actionModules addObject:module];
			}
			[module setReportToFill:reportToFill];
			
		}
        [module release];
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
	reportToFill.url = newUrl;
}

-(void) dealloc {
    [super dealloc];
    [delay release];
	[postUrl release];
	[reportModules release];
	[actionModules release];
	[reportToFill release];
}

@end
