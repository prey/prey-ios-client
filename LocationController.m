//
//  LocationController.m
//  Prey
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "LocationController.h"


@implementation LocationController

@synthesize locationManager;
@synthesize delegate;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.locationManager = [[[CLLocationManager alloc] init] autorelease];
        self.locationManager.delegate = self; // send loc updates to myself
    }
    return self;
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"New location received: %@", [newLocation description]);
	[self.delegate locationUpdate:newLocation];
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	NSLog(@"Error getting location: %@", [error description]);
	 [self.delegate locationError:error];
}

- (void)dealloc {
    [self.locationManager release];
    [super dealloc];
}
@end
