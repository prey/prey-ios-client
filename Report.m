//
//  Report.m
//  Prey
//
//  Created by Carlos Yaconi on 14/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "Report.h"
#import "PreyModule.h"
#import "PreyRestHttp.h"
#import "LocationController.h"

@implementation Report

@synthesize modules,waitForLocation,url;

- (id) init {
    self = [super init];
    if (self != nil) {
		waitForLocation = NO;
		reportData = [[NSMutableDictionary alloc] init];
    }
    return self;
}
- (void) send {
	LogMessageCompat(@"Sending report...");
	if (waitForLocation) {
		LogMessageCompat(@"...but have to wait for a location");
		[[NSNotificationCenter defaultCenter] addObserver:self
			selector:@selector(locationUpdated:)
			name:@"locationUpdated" object:nil];
	} else {
		LogMessageCompat(@"... right now.");
		PreyRestHttp *userHttp = [[[PreyRestHttp alloc] init] autorelease];
		[userHttp sendReport:self];
	}

}

//parameters: {geo[lng]=-122.084095, geo[alt]=0.0, geo[lat]=37.422006, geo[acc]=0.0, api_key=rod8vlf13jco}

- (NSMutableDictionary *) getReportData {
	PreyModule* module;
	for (module in modules){
		if ([module reportData] != nil)
			[reportData addEntriesFromDictionary:[module reportData]];
	}
	return reportData;
}

- (void)locationUpdated:(NSNotification *)notification
{
    CLLocation *newLocation = (CLLocation*)[notification object];
	LogMessageCompat(@"New location notificaion arrived.");
	NSMutableDictionary *data = [[[NSMutableDictionary alloc] init] autorelease];
	[data setValue:[NSString stringWithFormat:@"%f",newLocation.coordinate.longitude] forKey:[[NSString alloc] initWithFormat:@"%@[%@]",@"geo",@"lng"]];
	[data setValue:[NSString stringWithFormat:@"%f",newLocation.coordinate.latitude] forKey:[[NSString alloc] initWithFormat:@"%@[%@]",@"geo",@"lat"]];
	[data setValue:[NSString stringWithFormat:@"%f",newLocation.altitude] forKey:[[NSString alloc] initWithFormat:@"%@[%@]",@"geo",@"alt"]];
	[data setValue:[NSString stringWithFormat:@"%f",newLocation.horizontalAccuracy] forKey:[[NSString alloc] initWithFormat:@"%@[%@]",@"geo",@"acc"]];
	[reportData addEntriesFromDictionary:data];
	waitForLocation = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"locationUpdated" object:nil];
	[self send];
    
}

- (void) dealloc {
	[super dealloc];
	[reportData release];
}
@end
