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
		LogMessage(@"Prey Location Controller", 5, @"Initializing Accurate LocationManager...");
		PreyConfig *config = [PreyConfig instance];
		self.accurateLocationManager = [[CLLocationManager alloc] init];
		self.accurateLocationManager.delegate = self;
		self.accurateLocationManager.desiredAccuracy = config.desiredAccuracy;
		
		//self.locationManager.distanceFilter = 1;
	
		LogMessage(@"Prey Location Controller", 5, @"Initializing Significant LocationManager...");
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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accuracyUpdated:) name:@"accuracyUpdated" object:nil];
	[self.accurateLocationManager startUpdatingLocation];
	LogMessage(@"Prey Location Controller", 5, @"Accurate location updating started.");
}
- (void)startMonitoringSignificantLocationChanges {
	[self.significantLocationManager startMonitoringSignificantLocationChanges];
	LogMessage(@"Prey Location Controller", 5, @"Significant location updating started.");
}

- (void)stopUpdatingLocation {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"accuracyUpdated" object:nil];
	[self.accurateLocationManager stopUpdatingLocation];
	LogMessage(@"Prey Location Controller", 5, @"Accurate location updating stopped.");
}
- (void)stopMonitoringSignificantLocationChanges {
	[self.significantLocationManager stopUpdatingLocation];
	LogMessage(@"Prey Location Controller", 5, @"Significant location updating stopped.");
}


- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
	LogMessage(@"Prey Location Controller", 3, @"New location received[%@]: %@",[manager description], [newLocation description]);
	NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"locationUpdated" object:newLocation];
	else
		LogMessage(@"Prey Location Controller", 10, @"Location received too old, discarded!");
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	LogMessage(@"Prey Location Controller", 0, @"Error getting location: %@", [error description]);
}

- (void)accuracyUpdated:(NSNotification *)notification
{
	LogMessage(@"Prey Location Controller", 5, @"Accuracy has been modified. Updating location manager...");
	self.accurateLocationManager.desiredAccuracy =  ((PreyConfig*)[notification object]).desiredAccuracy;
	[self.accurateLocationManager stopUpdatingLocation];
	[self.accurateLocationManager startUpdatingLocation];
}

- (void)dealloc {
    [self.accurateLocationManager release];
	[self.significantLocationManager release];
    [super dealloc];
}
@end
