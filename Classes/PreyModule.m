//
//  PreyModule.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "PreyModule.h"
#import "LocationModule.h"
#import "AlarmModule.h"
#import "AlertModule.h"
#import "PictureModule.h"

@implementation PreyModule

@synthesize configParms, reportToFill, type;

- (id) init {
	self = [super init];
	if(self != nil)
		configParms = [[NSMutableDictionary alloc] init];
	return self;
}

+ (PreyModule *) newModuleForName: (NSString *) moduleName {
	if ([moduleName isEqualToString:@"geo"]) {
		return [[[LocationModule alloc] init] autorelease];
	}
	if ([moduleName isEqualToString:@"alarm"]) {
		return [[[AlarmModule alloc] init] autorelease];
	}
	if ([moduleName isEqualToString:@"alert"]) {
		return [[[AlertModule alloc] init] autorelease];
	}
    if ([moduleName isEqualToString:@"webcam"]) {
		return [[[PictureModule alloc] init] autorelease];
	}
	return nil;
}

- (NSString *) getName {
	return nil; //must be overriden;
}

- (NSMutableDictionary *) reportData {
	return nil; //must be overriden;
}

- (void) fillReportData:(ASIFormDataRequest*) request {
    //must be overriden;
}

-(void)dealloc {
    [super dealloc];
    [reportToFill release];
    [configParms release];
}

@end
