//
//  LocationModule.m
//  Prey
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "LocationModule.h"
#import "PreyRunner.h"


@implementation LocationModule

- (void)main {
	locationController = [[LocationController alloc] init];
	locationController.delegate = self;
    [locationController.locationManager startUpdatingLocation];
}

- (NSString *) getName {
	return @"geo";
}

- (void)locationUpdate:(CLLocation *)location {
	PreyRunner *runner = [PreyRunner instance];
	[runner setLastLocation:location];
}

- (void)locationError:(NSError *)error {
    //see what to do here
}

- (void)dealloc {
	[super dealloc];
	[locationController release];
}
@end
