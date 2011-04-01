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

+(LocationController *) instance;
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;


@end
