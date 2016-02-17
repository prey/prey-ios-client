//
//  GeofenceMapController.h
//  Prey
//
//  Created by Javier Cala Uribe on 17/02/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeviceMapController.h"
#import "GeofenceZones.h"

@interface GeofenceMapController : DeviceMapController <UITextFieldDelegate,UIPickerViewDelegate,UIPickerViewDataSource>

@property (nonatomic, strong) NSMutableDictionary   *colorsGeofence;
@property (nonatomic, strong) UITextField           *zoneInputs;
@property (nonatomic, strong) UIPickerView          *zonePickerView;
@property (nonatomic, strong) NSMutableArray        *zoneDataSourceArray;
@property (nonatomic, strong) GeofenceZones         *currentGeofenceZone;

@end
