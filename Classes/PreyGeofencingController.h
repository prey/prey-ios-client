//
//  PreyGeofencingController.h
//  Prey
//
//  Created by Carlos Yaconi on 06-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PreyGeofencingController : NSObject <CLLocationManagerDelegate> {
}

+(PreyGeofencingController *) instance;
@property (nonatomic, retain) CLLocationManager *geofencingManager;
- (void)addNewregion: (CLRegion *) region;
- (void)removeRegion: (NSString *) id;

@end


