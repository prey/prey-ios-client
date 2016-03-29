//
//  DeviceAuth.h
//  Prey
//
//  Created by Javier Cala Uribe on 6/7/15.
//  Copyright (c) 2015 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface DeviceAuth : NSObject

@property (nonatomic) BOOL cameraAuth;
@property (nonatomic) BOOL locationAuth;
@property (nonatomic) BOOL notifyAuth;
@property (nonatomic) CLLocationManager *authLocation;

+ (DeviceAuth*)instance;
- (BOOL)checkAllDeviceAuthorization:(UIViewController*)viewController;
- (BOOL)checkNotifyDeviceAuthorizationStatus:(UIViewController*)viewController;
- (BOOL)checkLocationDeviceAuthorizationStatus:(UIViewController*)viewController;
- (BOOL)checkCameraDeviceAuthorizationStatus:(UIViewController*)viewController;

@end
