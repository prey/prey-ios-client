//
//  RegionAnnotation.m
//  Prey
//
//  Created by Javier Cala Uribe on 16/02/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

#import "RegionAnnotation.h"

@implementation RegionAnnotation

// Initialize the annotation object.
- (instancetype)init {
    self = [super init];
    if (self != nil) {
    }
    
    return self;
}

// Initialize the annotation object with the monitored region.
- (instancetype)initWithCLRegion:(CLCircularRegion *)newRegion withTitle:(NSString*)titleRegion {
    self = [self init];
    
    if (self != nil) {
        _region = newRegion;
        _coordinate = newRegion.center;
        _radius = newRegion.radius;
        _title = titleRegion;
    }
    
    return self;
}


/*
 This method provides a custom setter so that the model is notified when the subtitle value has changed, which is derived from the radius.
 */
- (void)setRadius:(CLLocationDistance)newRadius {
    [self willChangeValueForKey:@"subtitle"];
    
    _radius = newRadius;
    
    [self didChangeValueForKey:@"subtitle"];
}


- (NSString *)subtitle {
    return [NSString stringWithFormat: @"Lat: %.4F, Lon: %.4F, Rad: %.1fm", self.coordinate.latitude, self.coordinate.longitude, self.radius];
}




@end
