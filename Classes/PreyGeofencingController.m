//
//  PreyGeofencingController.m
//  Prey
//
//  Created by Carlos Yaconi on 06-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import "PreyGeofencingController.h"

@implementation PreyGeofencingController

@synthesize geofencingManager;

- (id) init {
    self = [super init];
    if (self != nil) {
		PreyLogMessage(@"Prey PreyGeofencingController", 5, @"Initializing PreyGeofencingController...");
		geofencingManager = [[CLLocationManager alloc] init];
		geofencingManager.delegate = self;
    }
    return self;
}

+(PreyGeofencingController *)instance  {
	static PreyGeofencingController *instance;
	@synchronized(self) {
		if(!instance)
			instance = [[PreyGeofencingController alloc] init];
	}
	return instance;
}

- (void)addNewregion: (CLRegion *) region {
    [geofencingManager startMonitoringForRegion:region];
}

- (void)removeRegion: (NSString *) id {
    [geofencingManager.monitoredRegions enumerateObjectsUsingBlock:^(CLRegion *obj, BOOL *stop) {
        if ([obj.identifier localizedCaseInsensitiveCompare:id] == NSOrderedSame) {
            [geofencingManager stopMonitoringForRegion:obj];
            *stop = YES;
        }
    }];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate Protocol methods

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    PreyLogMessage(@"Prey PreyGeofencingController", 5, @"didStartMonitoringForRegion");
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    PreyLogMessage(@"Prey PreyGeofencingController", 5, @"didEnterRegion");
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    PreyLogMessage(@"Prey PreyGeofencingController", 5, @"didExitRegion");
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
}


@end
