//
//  LocationController.m
//  Prey
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "LocationController.h"
#import "PreyConfig.h"


@implementation LocationController

@synthesize accurateLocationManager,significantLocationManager;

- (id) init {
    self = [super init];
    if (self != nil) {
		LogMessageCompat(@"Initializing Accurate LocationManager...");
		PreyConfig *config = [PreyConfig instance];
		self.accurateLocationManager = [[CLLocationManager alloc] init];
		self.accurateLocationManager.delegate = self;
		self.accurateLocationManager.desiredAccuracy = config.desiredAccuracy;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accuracyUpdated:) name:@"accuracyUpdated" object:nil];
		//self.locationManager.distanceFilter = 1;
	
		LogMessageCompat(@"Initializing Significant LocationManager...");
		self.significantLocationManager = [[CLLocationManager alloc] init];
		self.significantLocationManager.delegate = self;		
    }
    return self;
}

+(LocationController *)instance  {
	static LocationController *instance;
	@synchronized(self) {
		if(!instance) {
			instance = [[LocationController alloc] init];
		}
	}
	return instance;
}

- (void)startUpdatingLocation {
	[self.accurateLocationManager startUpdatingLocation];
	LogMessageCompat(@"Accurate location updating started.");
}
- (void)startMonitoringSignificantLocationChanges {
	[self.significantLocationManager startMonitoringSignificantLocationChanges];
	LogMessageCompat(@"Significant location updating started.");
}

- (void)stopUpdatingLocation {
	[self.accurateLocationManager stopUpdatingLocation];
	LogMessageCompat(@"Accurate location updating stopped.");
}
- (void)stopMonitoringSignificantLocationChanges {
	[self.significantLocationManager stopUpdatingLocation];
	LogMessageCompat(@"Significant location updating stopped.");
}


- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    LogMessageCompat(@"---> New location received: %@", [newLocation description]);
	NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"locationUpdated" object:newLocation];
	else
		LogMessageCompat(@"Location received too old, discarded!");
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	LogMessageCompat(@"Error getting location: %@", [error description]);
}

- (void)accuracyUpdated:(NSNotification *)notification
{
	LogMessage(@"Prey Location Controller", 0, @"Accuracy has been modified. Updating location manager.");
	self.accurateLocationManager.desiredAccuracy = ((PreyConfig*) notification).desiredAccuracy;
	
}

- (void)dealloc {
	LogMessageCompat(@"LocationController is going to be released...");
    [self.accurateLocationManager release];
	[self.significantLocationManager release];
    [super dealloc];
}
@end
