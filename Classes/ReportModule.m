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
#import "Constants.h"
#import "PicturesController.h"
#import "PreyAppDelegate.h"
#import "LocationController.h"


@implementation ReportModule

@synthesize waitForLocation,waitForPicture,url, picture, reportData, runReportTimer;

+(ReportModule *)instance  {
	static ReportModule *instance;
    
	@synchronized(self)
    {
		if(!instance)
        {
			instance = [[ReportModule alloc] init];
			instance.reportData = [[NSMutableDictionary alloc] init];
            PreyLogMessage(@"Report Module", 0,@"Registering ReportModule to receive location updates notifications");
            
            [[NSNotificationCenter defaultCenter] addObserver:instance
                                                     selector:@selector(locationUpdated:)
                                                         name:@"locationUpdated"
                                                       object:nil];
            
            [[LocationController instance] startUpdatingLocation];
		}
	}
    
	return instance;
}


- (void) get
{
    lastExecution = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastExecutionKey"];
    
    if (lastExecution != nil)
    {
        NSInteger delayReport = [[NSUserDefaults standardUserDefaults] integerForKey:@"delayReport"];
        NSInteger lastRunInterval = ceil(-[lastExecution timeIntervalSinceNow]) ;
        
        PreyLogMessage(@"Report Module", 0, @"Checking if delay of %d secs. is less than last running interval: %d secs.", (int)delayReport, (int)lastRunInterval);
        if (lastRunInterval < delayReport)
        {
            PreyLogMessage(@"Report Module", 0, @"Trying to get device's status but interval hasn't expired. (%d secs. since last execution). Aborting!", (int)lastRunInterval);
            return;
        }
    }
    lastExecution = [[NSDate date] retain];
    [[NSUserDefaults standardUserDefaults] setObject:lastExecution forKey:@"lastExecutionKey"];
    
    
    waitForLocation = YES;
    waitForPicture  = YES;

    if (!runReportTimer)
    {
        NSInteger interval = [[super.options objectForKey:@"interval"] intValue]*60;
        
        if (interval == 0)
            interval = [[NSUserDefaults standardUserDefaults] integerForKey:@"delayReport"];
        else
            [[NSUserDefaults standardUserDefaults] setInteger:interval forKey:@"delayReport"];
        
        PreyLogMessage(@"Report", 10, @"Intervalo = %d",(int)interval);

        runReportTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:[ReportModule instance] selector:@selector(runReportModule:) userInfo:nil repeats:YES];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SendReport"];
        
        if (IS_OS_7_OR_LATER)
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
        [self stopSendReport];
}

- (void)stopSendReport
{
    [runReportTimer invalidate];
    runReportTimer = nil;
    
    lastExecution = nil;
    [[NSUserDefaults standardUserDefaults] setObject:lastExecution forKey:@"lastExecutionKey"];

    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"SendReport"];
    
    if (IS_OS_7_OR_LATER)
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    
    [[NSNotificationCenter defaultCenter] removeObserver:[ReportModule instance] name:@"locationUpdated" object:nil];
    [[LocationController instance] stopUpdatingLocation];
    
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate changeShowFakeScreen:NO];
}


- (void) send
{
    PreyLogMessage(@"Report", 5, @"Attempting to send the report.");
    
    if (waitForLocation) {
        PreyLogMessage(@"Report", 5, @"Have to wait for a location before send the report.");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"accuracyUpdated" object:nil];
    }
    
    if (waitForPicture) {
		PreyLogMessage(@"Report", 5, @"Have to wait the picture be taken before send the report.");
        
        //Can't take pictures if in bg
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
            [[PicturesController instance]takePictureAndNotifyTo:@selector(pictureReady:) onTarget:[ReportModule instance]];
        else
            waitForPicture = NO;
	}
    
    [self sendIfConditionsMatch];
}

- (void) sendIfConditionsMatch
{
    if (!waitForPicture && !waitForLocation) {
        @try {
            waitForLocation = YES;
            waitForPicture  = YES;

            PreyLogMessageAndFile(@"Report", 5, @"Sending report now!");
            
            [super sendHttp:reportData
                     andRaw:[super createResponseFromData:UIImagePNGRepresentation(picture) withKey:@"picture"]];
            
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
        self.picture = pictureTaken;
    else
    {
        UIImage *lastPicture = [[[PicturesController instance]lastPicture] copy];
        if (lastPicture != nil)
            self.picture = lastPicture;
            
        [lastPicture release];
    }
    
    waitForPicture = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:[ReportModule instance] name:@"pictureReady" object:nil];

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

    waitForLocation = NO;
	[self sendIfConditionsMatch];
}

- (void) dealloc {
	[super dealloc];
	[reportData release];
    [url release];
    [picture release];
    [runReportTimer release];
}
@end
