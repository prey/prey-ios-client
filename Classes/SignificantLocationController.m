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

@implementation SignificantLocationController

@synthesize significantLocationManager;

- (id) init {
    self = [super init];
    if (self != nil) {
		PreyLogMessage(@"Prey SignificantLocationController", 5, @"Initializing Significant LocationManager...");
		significantLocationManager = [[CLLocationManager alloc] init];
		significantLocationManager.delegate = self;
        significantLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
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
    [significantLocationManager startMonitoringSignificantLocationChanges];
    PreyLogMessageAndFile(@"Prey SignificantLocationController", 5, @"Significant location updating started.");
}

- (void)stopMonitoringSignificantLocationChanges {
	[significantLocationManager stopMonitoringSignificantLocationChanges];
    [significantLocationManager stopUpdatingLocation];
	PreyLogMessageAndFile(@"Prey SignificantLocationController", 5, @"Significant location updating stopped.");
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
	PreyLogMessage(@"Prey SignificantLocationController", 3, @"New location received[%@]: %@",[manager description], [newLocation description]);
	NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"locationUpdated" object:newLocation];
	else
		PreyLogMessage(@"Prey SignificantLocationController", 10, @"Location received too old, discarded!");
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	NSString *errorString;
    //[manager stopUpdatingLocation];
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
	[significantLocationManager release];
    [super dealloc];
}

@end
