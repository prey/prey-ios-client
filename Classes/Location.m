//
//  Location.m
//  Prey
//
//  Created by Carlos Yaconi on 23-01-13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "Location.h"

@implementation Location

@synthesize locManager;
@synthesize bestEffortAtLocation;

+(Location *)instance  {
	static Location *instance;
    
	@synchronized(self)
    {
		if(!instance)
        {
			instance = [[Location alloc] init];
            PreyLogMessage(@"Location Module", 0,@"Registering Location to receive location updates notifications");
		}
	}
    
	return instance;
}


- (void)testLocation
{
    locManager = [[CLLocationManager alloc] init];
    locManager.delegate = self;
	locManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locManager startUpdatingLocation ];
    [locManager stopUpdatingLocation];    
}

- (void) get
{
    NSInteger requestNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"requestNumber"] + 1;
    [[NSUserDefaults standardUserDefaults] setInteger:requestNumber forKey:@"requestNumber"];
    
    [self initLocation];
    
    PreyLogMessage(@"Location", 10,@"Location Command: Get");
}

- (void)initLocation
{
    bestEffortAtLocation = nil;
	locManager = [[CLLocationManager alloc] init];
    locManager.delegate = self;
	locManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locManager startUpdatingLocation ];
}

- (void) locationReceived: (CLLocation*) location {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[NSString stringWithFormat:@"%f",location.coordinate.longitude] forKey:@"lng"];
	[dict setObject:[NSString stringWithFormat:@"%f",location.coordinate.latitude] forKey:@"lat"];
	[dict setObject:[NSString stringWithFormat:@"%f",location.altitude] forKey:@"alt"];
	[dict setObject:[NSString stringWithFormat:@"%f",location.horizontalAccuracy] forKey:@"acc"];
    
    [super sendHttp:[super createResponseFromObject:dict withKey:[self getName]]];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	PreyLogMessage(@"Prey location module", 3, @"New location received[%@]: %@",[manager description], [newLocation description]);
    
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) return;
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) return;
    
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) return;
    
    // test the measurement to see if it is more accurate than the previous measurement
    if (bestEffortAtLocation == nil || bestEffortAtLocation.horizontalAccuracy > newLocation.horizontalAccuracy) {
        // store the location as the "best effort"
        bestEffortAtLocation = newLocation;
        
        // test the measurement to see if it meets the desired accuracy
        //
        // IMPORTANT!!! kCLLocationAccuracyBest should not be used for comparison with location coordinate or altitidue
        // accuracy because it is a negative value. Instead, compare against some predetermined "real" measure of
        // acceptable accuracy, or depend on the timeout to stop updating. This sample depends on the timeout.
        //
        if (newLocation.horizontalAccuracy <= 500)
        {
            [self performSelector:@selector(locationReceived:) withObject:newLocation];
            
            [locManager stopUpdatingLocation];
            locManager.delegate = nil;
        }
    }
    
        /*
	NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"locationUpdated" object:newLocation];
        [self performSelector:@selector(locationReceived:) withObject:newLocation];
        [locManager stopUpdatingLocation];
    }
	else
		PreyLogMessage(@"Prey location module", 10, @"Location received too old, discarded!");*/
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
    BOOL showAlertLocation = YES;
    
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
            showAlertLocation = NO;
            //Do something else...
            break;
        default:
            errorString = NSLocalizedString(@"An unknown error has occurred",@"Regarding getting the device's location");
            break;
    }
    
    if (showAlertLocation)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:errorString delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
    PreyLogMessage(@"Prey Location", 0, @"Error getting location: %@", [error description]);
}

- (NSString *) getName {
	return @"location";
}

@end
