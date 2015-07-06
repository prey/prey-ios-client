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

- (void)checkNotifyDeviceAuthorizationStatus:(UISwitch *)notifySwitch
{
    notifyAuth = NO;
    
    [(PreyAppDelegate*)[UIApplication sharedApplication].delegate registerForRemoteNotifications];
    
    if (IS_OS_8_OR_LATER)
    {
        UIUserNotificationSettings *notificationSettings = [[UIApplication sharedApplication]  currentUserNotificationSettings];
        notifyAuth = notificationSettings.types > 0;
        notifySwitch.on = notifyAuth;
        
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"askFirst"]) {
            notifyAuth = YES;
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"askFirst"];
        }
    }
    else
    {
        UIRemoteNotificationType notificationTypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        if (notificationTypes & UIRemoteNotificationTypeAlert) {
            notifyAuth = YES;
            notifySwitch.on = notifyAuth;
        }
    }
    
    if (notifyAuth)
        PreyLogMessage(@"App Delegate", 10, @"Alert notification set. Good!");
    else
    {
        PreyLogMessage(@"App Delegate", 10, @"User has disabled alert notifications");
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert notification disabled",nil)
                                                            message:NSLocalizedString(@"You need to grant Prey access to show alert notifications in order to remotely mark it as missing.",nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    
    [self saveValues];
}

- (void)checkLocationDeviceAuthorizationStatus:(UISwitch *)locationSwitch
{
    if ( [CLLocationManager locationServicesEnabled] &&
        ( [CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined) &&
        ( [CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied) &&
        ( [CLLocationManager authorizationStatus] != kCLAuthorizationStatusRestricted) )
    {
        locationAuth = YES;
        locationSwitch.on = locationAuth;
    }
    else
    {
        authLocation = [[CLLocationManager alloc] init];
        
        if (IS_OS_8_OR_LATER)
        {
            [authLocation requestAlwaysAuthorization];
        }
        else
        {
            [authLocation  startUpdatingLocation];
            [authLocation stopUpdatingLocation];
        }
        locationAuth = NO;
        locationSwitch.on = locationAuth;
    }
    
    [self saveValues];
}

- (void)checkCameraDeviceAuthorizationStatus:(UISwitch *)cameraSwitch
{
    if (IS_OS_7_OR_LATER)
    {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusAuthorized)
        {
            cameraAuth = YES;
            cameraSwitch.on = cameraAuth;
        }
        else if (authStatus == AVAuthorizationStatusNotDetermined)
        {
            // Camera access not determined. Ask for permission
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted)
                {
                    cameraAuth = YES;
                    cameraSwitch.on = cameraAuth;
                }
                else
                {
                    [self cameraDeniedAccess:cameraSwitch];
                }
            }];
        }
        else
        {
            [self cameraDeniedAccess:cameraSwitch];
        }
    }
    else
    {
        cameraAuth = YES;
        cameraSwitch.on = cameraAuth;
    }
    
    [self saveValues];
}

- (void)cameraDeniedAccess:(UISwitch *)cameraSwitch
{
    //Not granted access to mediaType
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[UIAlertView alloc] initWithTitle:@"Camera Authorization"
                                    message:@"Prey doesn't have permission to use Camera, please change privacy settings"
                                   delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        
        cameraAuth = NO;
        cameraSwitch.on = cameraAuth;
        
        [self saveValues];
    });
}


@end
