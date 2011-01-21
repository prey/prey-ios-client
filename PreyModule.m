//
//  PreyModule.m
//  Prey
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "PreyModule.h"
#import "LocationModule.h"
#import "AlarmModule.h"
#import "AlertModule.h"

@implementation PreyModule

@synthesize configParms, reportToFill, type;

- (id) init {
	self = [super init];
	if(self != nil)
		configParms = [[NSMutableDictionary alloc] init];
	return self;
}

+ (PreyModule *) getModuleForName: (NSString *) moduleName {
	if ([moduleName isEqualToString:@"geo"]) {
		return [[LocationModule alloc] init];
	}
	if ([moduleName isEqualToString:@"alarm"]) {
		return [[AlarmModule alloc] init];
	}
	if ([moduleName isEqualToString:@"alert"]) {
		return [[AlertModule alloc] init];
	}
	return nil;
}

- (NSString *) getName {
	return nil; //must be overriden;
}

- (NSMutableDictionary *) reportData {
	return nil; //must be overriden;
}

@end
