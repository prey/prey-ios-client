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
#import "PreyConfig.h"

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
	if (waitForLocation) {
		LogMessage(@"Report", 5, @"Have to wait for a location before send the report.");
		[[NSNotificationCenter defaultCenter] addObserver:self
			selector:@selector(locationUpdated:)
			name:@"locationUpdated" object:nil];
	} else {
		LogMessage(@"Report", 5, @"I've a valid location to send. Sending report now!");
		PreyRestHttp *userHttp = [[[PreyRestHttp alloc] init] autorelease];
		[userHttp sendReport:self];
		[self performSelectorOnMainThread:@selector(alertReportSent) withObject:nil waitUntilDone:NO];
	}

}

- (void) alertReportSent {
	if ([PreyConfig instance].alertOnReport){

		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Prey" message:NSLocalizedString(@"A new report has been sent to your Control Panel",nil) delegate:self cancelButtonTitle:nil otherButtonTitles:nil] autorelease];
		[alert addButtonWithTitle:@"OK"];
		[alert show];		
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
	NSMutableDictionary *data = [[[NSMutableDictionary alloc] init] autorelease];
	[data setValue:[NSString stringWithFormat:@"%f",newLocation.coordinate.longitude] forKey:[NSString stringWithFormat:@"%@[%@]",@"geo",@"lng"]];
	[data setValue:[NSString stringWithFormat:@"%f",newLocation.coordinate.latitude] forKey:[NSString stringWithFormat:@"%@[%@]",@"geo",@"lat"]];
	[data setValue:[NSString stringWithFormat:@"%f",newLocation.altitude] forKey:[NSString stringWithFormat:@"%@[%@]",@"geo",@"alt"]];
	[data setValue:[NSString stringWithFormat:@"%f",newLocation.horizontalAccuracy] forKey:[NSString stringWithFormat:@"%@[%@]",@"geo",@"acc"]];
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
