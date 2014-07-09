//
//  GoefencingModule.m
//  Prey
//
//  Created by Carlos Yaconi on 06-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import "GeofencingModule.h"
#import "PreyGeofencingController.h"
#import "Constants.h"

@implementation GeofencingModule

- (void)get
{
    NSString *action = [NSString stringWithFormat:@"%@:",[self.options objectForKey:@"action"]];
    NSString *region_id = [self.options objectForKey:@"region_id"];
    CLLocationDegrees center_lat = [[self.options objectForKey:@"center_lat"] doubleValue];
    CLLocationDegrees center_lon = [[self.options objectForKey:@"center_lon"] doubleValue];
    CLLocationDistance radius = [[self.options objectForKey:@"radius"] doubleValue];
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(center_lat, center_lon);
    
    CLRegion *region;
    
    if (IS_OS_7_OR_LATER)
    {
        if ([CLLocationManager isMonitoringAvailableForClass:[CLRegion class]])
        {
            region =  [[CLCircularRegion alloc] initWithCenter:center radius:radius identifier:region_id];
        }
    }
    else
         region = [[CLRegion alloc] initCircularRegionWithCenter:center radius:radius identifier:region_id];
    
    if (region != nil)
    {
        SEL selector = NSSelectorFromString(action);
        IMP imp = [self methodForSelector:selector];
        void (*func)(id, SEL, CLRegion *) = (void *)imp;
        func(self, selector, region);
    }
}

- (void)start: (CLRegion *)region {
    [[PreyGeofencingController instance] addNewregion:region];
}

- (void)stop: (CLRegion *)region {
    [[PreyGeofencingController instance] removeRegion:region.identifier];
}

- (NSString *) getName {
	return @"geofencing";
}

- (NSMutableDictionary *) reportData {
    return nil;
}

@end
