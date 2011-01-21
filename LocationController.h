//
//  LocationController.h
//  Prey
//
//  Created by Carlos Yaconi on 18/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocationController : NSObject <CLLocationManagerDelegate> {

}

@property (nonatomic, retain) CLLocationManager *accurateLocationManager;
@property (nonatomic, retain) CLLocationManager *significantLocationManager;

+(LocationController *) instance;
- (void)locationManager:(CLLocationManager *)manager
		   didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation;

- (void)locationManager:(CLLocationManager *)manager
		   didFailWithError:(NSError *)error;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;
- (void)startMonitoringSignificantLocationChanges;
- (void)stopMonitoringSignificantLocationChanges;

@end
