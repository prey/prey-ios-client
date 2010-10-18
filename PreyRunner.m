//
//  PreyRunner.m
//  Prey
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "PreyRunner.h"
#import "LocationModule.h"
#import "PreyConfig.h"
#import "PreyRestHttp.h"
#import "DeviceModulesConfig.h"


@implementation PreyRunner

@synthesize lastLocation;

+(PreyRunner *)instance  {
	static PreyRunner *instance;
	
	@synchronized(self) {
		if(!instance) {
			instance = [[PreyRunner alloc] init];
		}
	}
	
	return instance;
}

-(void) goPrey{
	queue = [[NSOperationQueue alloc] init];
	PreyConfig *config = [PreyConfig getInstance];
	PreyRestHttp *preyHttp = [[PreyRestHttp alloc] init];
	BOOL setMissing = [preyHttp changeStatusToMissing:YES forDevice:[config deviceKey] fromUser:[config apiKey]];
	DeviceModulesConfig *modulesConfig = [preyHttp getXMLforUser:[config apiKey] device:[config deviceKey]];
	
	
	/*
	LocationModule *locationModule = [[LocationModule alloc] init];
	[queue addOperation:locationModule];
	[locationModule release];
	 */
	[config release];
	[modulesConfig release];
	[preyHttp release];
	
}

- (void)dealloc {
	[queue release], queue = nil;
    [super dealloc];
}
@end
