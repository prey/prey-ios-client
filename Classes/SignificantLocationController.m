//
//  SignificantLocationController.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 28/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "SignificantLocationController.h"
#import "PreyRunner.h"
#import "DeviceModulesConfig.h"
#import "PreyRestHttp.h"
#import "PreyConfig.h"

@implementation SignificantLocationController

@synthesize significantLocationManager;

- (id) init {
    self = [super init];
    if (self != nil) {
		PreyLogMessage(@"Prey SignificantLocationController", 5, @"Initializing Significant LocationManager...");
		self.significantLocationManager = [[CLLocationManager alloc] init];
		self.significantLocationManager.delegate = self;		
    }
    return self;
}

+(SignificantLocationController *)instance  {
	static SignificantLocationController *instance;
	@synchronized(self) {
		if(!instance) {
			instance = [[SignificantLocationController alloc] init];
		}
	}
	return instance;
}


- (void)startMonitoringSignificantLocationChanges {
    if ([[PreyConfig instance] intervalMode]){
        [self.significantLocationManager startMonitoringSignificantLocationChanges];
        PreyLogMessageAndFile(@"Prey SignificantLocationController", 5, @"Significant location updating started.");
    } else {
        PreyLogMessageAndFile(@"Prey SignificantLocationController", 5, @"Significant location not started because user disabled it.");
    }
    
}

- (void)stopMonitoringSignificantLocationChanges {
	[self.significantLocationManager stopMonitoringSignificantLocationChanges];
    [self.significantLocationManager stopUpdatingLocation];
	PreyLogMessageAndFile(@"Prey SignificantLocationController", 5, @"Significant location updating stopped.");
}


- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
	
	NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0){
		PreyLogMessageAndFile(@"Prey SignificantLocationController", 3, @"New location received. Checking device's missing status on the control panel");
        PreyRestHttp *http = [[PreyRestHttp alloc] init];
        PreyConfig *config = [PreyConfig instance];
        DeviceModulesConfig *modulesConfig = nil;
        //if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground){
            UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication]
                                                 beginBackgroundTaskWithExpirationHandler:^{}];
            
            modulesConfig = [[http getXMLforUser:[config apiKey] device:[config deviceKey]] retain]; 
            if (modulesConfig.missing){
                PreyLogMessageAndFile(@"Prey SignificantLocationController", 5, @"[bg task] Missing device! Starting Prey service now!");
                [[PreyRunner instance] startPreyService];                  
            } else
                PreyLogMessageAndFile(@"Prey SignificantLocationController", 5, @"[bg task] Device NOT marked as missing!");
            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
    /*    
    }
        else {
            modulesConfig = [[http getXMLforUser:[config apiKey] device:[config deviceKey]] retain];
            if (modulesConfig.missing){
                PreyLogMessageAndFile(@"Prey SignificantLocationController", 5, @"Missing device! Starting Prey now!");
                [[PreyRunner instance] startPreyService];                  
            } else
                PreyLogMessageAndFile(@"Prey SignificantLocationController", 5, @"Device NOT marked as missing!");
        }*/
        
        [modulesConfig release];
        [http release];
    }
	else
		PreyLogMessageAndFile(@"Prey SignificantLocationController", 10, @"Location received too old, discarded!");
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	
    NSString *errorString;
    //[manager stopUpdatingLocation];
    NSLog(@"Error: %@",[error localizedDescription]);
    switch([error code]) {
        case kCLErrorDenied:
            //Access denied by user
            errorString = NSLocalizedString(@"Unable to access Location Services.\n You need to grant Prey access if you wish to track your device.",nil);
            //Do something...
            break;
        case kCLErrorLocationUnknown:
            //Probably temporary...
            errorString = NSLocalizedString(@"Unable to fetch location data. Is this device on airplane mode?",nil);
            //Do something else...
            break;
        default:
            errorString = NSLocalizedString(@"An unknown error has occurred",@"Regarding getting the device's location");
            break;
    }

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:errorString delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
    [alert release];
    PreyLogMessageAndFile(@"Prey SignificantLocationController", 0, @"Error getting location: %@", [error description]);
}


- (void)dealloc {
	[self.significantLocationManager release];
    [super dealloc];
}

@end
