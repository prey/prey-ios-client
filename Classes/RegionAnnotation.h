//
//  RegionAnnotation.h
//  Prey
//
//  Created by Javier Cala Uribe on 16/02/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/Mapkit.h>

@interface RegionAnnotation : NSObject <MKAnnotation>

@property (nonatomic, strong) CLRegion *region;
@property (nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@property (nonatomic, readwrite) CLLocationDistance radius;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;

- (instancetype)initWithCLRegion:(CLCircularRegion *)newRegion withTitle:(NSString*)titleRegion;


@end


