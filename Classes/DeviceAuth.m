//
//  DeviceAuth.m
//  Prey
//
//  Created by Javier Cala Uribe on 6/7/15.
//  Copyright (c) 2015 Fork Ltd. All rights reserved.
//

#import "DeviceAuth.h"
#import "PreyAppDelegate.h"
#import "Constants.h"

static NSString *const CAMERA_AUTH   = @"cameraAuth";
static NSString *const LOCATION_AUTH = @"locationAuth";
static NSString *const NOTIFY_AUTH   = @"notifyAuth";

@implementation DeviceAuth

@synthesize cameraAuth, locationAuth, notifyAuth, authLocation;

#pragma mark Init

+ (DeviceAuth *)instance
{
    static DeviceAuth *instance = nil;
    static dispatch_once_t onceToken = 0;

    dispatch_once(&onceToken, ^{
        instance = [[DeviceAuth alloc] init];

        [instance loadDefaultValues];
    });
    
    return instance;
}

- (void)loadDefaultValues
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.cameraAuth          = [defaults boolForKey:CAMERA_AUTH];
    self.locationAuth        = [defaults boolForKey:LOCATION_AUTH];
    self.notifyAuth          = [defaults boolForKey:NOTIFY_AUTH];
    
    [defaults synchronize];
}

- (void)saveValues
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.cameraAuth   forKey:CAMERA_AUTH];
    [defaults setBool:self.locationAuth forKey:LOCATION_AUTH];
    [defaults setBool:self.notifyAuth   forKey:NOTIFY_AUTH];
    
    [defaults synchronize];
}

-(void)resetValues
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:CAMERA_AUTH];
    [defaults removeObjectForKey:LOCATION_AUTH];
    [defaults removeObjectForKey:NOTIFY_AUTH];
    
    [defaults synchronize];
}

#pragma mark Check Auth

- (BOOL)checkAllDeviceAuthorization:(UIViewController*)viewController {
    
    BOOL isAllAuthAvailable = NO;
    
    if ( ([self checkNotifyDeviceAuthorizationStatus:viewController])   &&
         ([self checkLocationDeviceAuthorizationStatus:viewController]) &&
         ([self checkCameraDeviceAuthorizationStatus:viewController]) ) {
        isAllAuthAvailable = YES;
    }
    
    return isAllAuthAvailable;
}

- (BOOL)checkNotifyDeviceAuthorizationStatus:(UIViewController*)viewController
{
    notifyAuth = NO;
    
    if (IS_OS_8_OR_LATER) {
        UIUserNotificationSettings *notificationSettings = [[UIApplication sharedApplication]  currentUserNotificationSettings];
        notifyAuth = notificationSettings.types > 0;
    }
    else {
        UIRemoteNotificationType notificationTypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        if (notificationTypes & UIRemoteNotificationTypeAlert)
            notifyAuth = YES;
    }
    
    if (notifyAuth)
        PreyLogMessage(@"App Delegate", 10, @"Alert notification set. Good!");
    else
    {
        PreyLogMessage(@"App Delegate", 10, @"User has disabled alert notifications");
        
        [self displayErrorAlert:NSLocalizedString(@"You need to grant Prey access to show alert notifications in order to remotely mark it as missing.",nil)
                          title:NSLocalizedString(@"Alert notification disabled",nil)
                       delegate:viewController];
    }
    
    [self saveValues];
    
    return notifyAuth;
}

- (BOOL)checkLocationDeviceAuthorizationStatus:(UIViewController*)viewController
{
    if ( [CLLocationManager locationServicesEnabled] &&
        ( [CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined) &&
        ( [CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied) &&
        ( [CLLocationManager authorizationStatus] != kCLAuthorizationStatusRestricted) )
    {
        locationAuth = YES;
    }
    else
        locationAuth = NO;
    
    
    if (locationAuth)
        PreyLogMessage(@"App Delegate", 10, @"Location Services set Good!");
    else
    {
        PreyLogMessage(@"App Delegate", 10, @"User has disabled Location services");
        
        [self displayErrorAlert:NSLocalizedString(@"Location services are disabled for Prey. Reports will not be sent.",nil)
                          title:NSLocalizedString(@"Enable Location",nil)
                       delegate:viewController];
    }

    
    [self saveValues];
    
    return locationAuth;
}

- (BOOL)checkCameraDeviceAuthorizationStatus:(UIViewController*)viewController
{
    cameraAuth = NO;
    
    if (IS_OS_7_OR_LATER)
    {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusAuthorized)
            cameraAuth = YES;
    }
    else
        cameraAuth = YES;
    
    
    if (cameraAuth)
        PreyLogMessage(@"App Delegate", 10, @"Camera set Good!");
    else
    {
        PreyLogMessage(@"App Delegate", 10, @"User has disabled Location services");
        
        [self displayErrorAlert:NSLocalizedString(@"Camera is disabled for Prey. Reports will not be sent.",nil)
                          title:NSLocalizedString(@"Enable Camera",nil)
                       delegate:viewController];
    }
    
    [self saveValues];
    
    return cameraAuth;
}

- (void)displayErrorAlert:(NSString *)alertMessage title:(NSString*)titleMessage delegate:(UIViewController*)viewController
{
    NSString *acceptBtn = (IS_OS_8_OR_LATER) ? NSLocalizedString(@"Go to Settings",nil) : NSLocalizedString(@"OK",nil);
    NSString *cancelBtn = (IS_OS_8_OR_LATER) ? NSLocalizedString(@"Cancel",nil) : nil;
    
    UIAlertView * anAlert = [[UIAlertView alloc] initWithTitle:titleMessage
                                                       message:alertMessage
                                                      delegate:viewController
                                             cancelButtonTitle:acceptBtn
                                             otherButtonTitles:cancelBtn,nil];
    anAlert.tag = kTagAlertViewAuthDevice;
    [anAlert show];
}


@end
