//
//  Report.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 14/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "ReportModule.h"
#import "PreyModule.h"
#import "PreyRestHttp.h"
#import "PicturesController.h"

#import "Location.h"

@implementation ReportModule

@synthesize modules,waitForLocation,waitForPicture,url, picture, reportData, location, runReportTimer;

- (void) get
{
    lastExecution = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastExecutionKey"];
    
    if (lastExecution != nil)
    {
        NSInteger delayReport = [[NSUserDefaults standardUserDefaults] integerForKey:@"delayReport"];
        NSTimeInterval lastRunInterval = -[lastExecution timeIntervalSinceNow];
        PreyLogMessage(@"Prey Runner", 0, @"Checking if delay of %i secs. is less than last running interval: %f secs.", delayReport, lastRunInterval);
        if (lastRunInterval < delayReport)
        {
            PreyLogMessage(@"Prey Runner", 0, @"Trying to get device's status but interval hasn't expired. (%f secs. since last execution). Aborting!", lastRunInterval);
            return;
        }
    }
    lastExecution = [[NSDate date] retain];
    [[NSUserDefaults standardUserDefaults] setObject:lastExecution forKey:@"lastExecutionKey"];
    
    
    waitForLocation = YES;
    waitForPicture  = YES;
    reportData = [[NSMutableDictionary alloc] init];

    if (!runReportTimer)
    {
        NSInteger interval = [[super.options objectForKey:@"interval"] intValue]*60;
        
        if (interval == 0)
            interval = [[NSUserDefaults standardUserDefaults] integerForKey:@"delayReport"];
        else
            [[NSUserDefaults standardUserDefaults] setInteger:interval forKey:@"delayReport"];
        
        PreyLogMessage(@"Report", 10, @"Intervalo = %d",interval);

        runReportTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(runReportModule:) userInfo:nil repeats:YES];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SendReport"];
        
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:interval];
    }
    
    [self send];
}

- (NSString *) getName {
	return @"report";
}


- (void)runReportModule:(NSTimer *)timer
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SendReport"])
        [self get];
    else
    {
        [runReportTimer invalidate];
        runReportTimer = nil;
        
        lastExecution = nil;
        [[NSUserDefaults standardUserDefaults] setObject:lastExecution forKey:@"lastExecutionKey"];
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    }
}


- (void) send
{
    PreyLogMessage(@"Report", 5, @"Attempting to send the report.");
    
	if (waitForLocation) {
		PreyLogMessage(@"Report", 5, @"Have to wait for a location before send the report.");
        
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(locationUpdated:)
                                                     name:@"locationUpdated"
                                                   object:nil];
        location = [[Location alloc] init];
        [location getLocationForReport];
	}
    
    if (waitForPicture) {
		PreyLogMessage(@"Report", 5, @"Have to wait the picture be taken before send the report.");
        
        //Can't take pictures if in bg
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
            [[PicturesController instance]takePictureAndNotifyTo:@selector(pictureReady:) onTarget:self];
        else
            waitForPicture = NO;
	}
    
    [self sendIfConditionsMatch];
}

- (void) sendIfConditionsMatch
{
    if (!waitForPicture && !waitForLocation) {
        @try {
            PreyLogMessageAndFile(@"Report", 5, @"Sending report now!");
            
            PreyRestHttp *userHttp = [[[PreyRestHttp alloc] init] autorelease];
            [userHttp sendReport:self];
            
            self.picture = nil;
        }
        @catch (NSException *exception) {
            PreyLogMessageAndFile(@"Report", 0, @"Report couldn't be sent: %@", [exception reason]);
        }
    }
}

- (void) pictureReady:(UIImage *) pictureTaken
{
    if (pictureTaken != nil)
    {
        //UIImageWriteToSavedPhotosAlbum(pictureTaken, nil, nil, nil);
        self.picture = pictureTaken;
    }
    else
    {
        UIImage *lastPicture = [[[PicturesController instance]lastPicture] copy];
        if (lastPicture != nil)
            self.picture = lastPicture;
            
        [lastPicture release];
    }
    
    waitForPicture = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"pictureReady" object:nil];

    [self sendIfConditionsMatch];
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
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"locationUpdated" object:nil];
    waitForLocation = NO;
	[self sendIfConditionsMatch];
}



- (NSMutableDictionary *) getReportData {
	PreyModule* module;
	for (module in modules){
		if ([module reportData] != nil)
			[reportData addEntriesFromDictionary:[module reportData]];
	}
	return reportData;
}

- (void) fillReportData:(ASIFormDataRequest*) request {
    PreyModule* module;
	for (module in modules){
		if ([module reportData] != nil)
			[reportData addEntriesFromDictionary:[module reportData]];
	}
    
    [reportData enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
		[request addPostValue:(NSString*)object forKey:(NSString *) key];
	}];
    if (picture != nil)
        [request addData:UIImagePNGRepresentation(picture) withFileName:@"picture.png" andContentType:@"image/png" forKey:@"webcam[picture]"];
    picture = nil;
} 



- (void) dealloc {
	[super dealloc];
	[reportData release];
    [modules release];
    [url release];
    [picture release];
    [location release];
    [runReportTimer release];
}
@end
