//
//  DeviceMapController.h
//  Prey
//
//  Created by Diego Torres on 3/9/12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/Mapkit.h>
@interface DeviceMapController : UIViewController {
    MKMapView *mapa;
}

@property (nonatomic, retain) MKMapView *mapa;
@end
