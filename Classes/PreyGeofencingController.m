//
//  PreyGeofencingController.m
//  Prey
//
//  Created by Carlos Yaconi on 06-12-12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import "PreyGeofencingController.h"
#import "PreyRestHttp.h"
#import "Constants.h"
#import "PreyConfig.h"

@implementation PreyGeofencingController

@synthesize geofencingManager;

- (id) init {
    self = [super init];
    if (self != nil) {
		PreyLogMessage(@"Prey PreyGeofencingController", 5, @"Initializing PreyGeofencingController...");
		geofencingManager = [[CLLocationManager alloc] init];
		geofencingManager.delegate = self;
    }
    return self;
}

+ (PreyGeofencingController *)instance {
    static PreyGeofencingController *instance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[PreyGeofencingController alloc] init];
    });
    
    return instance;
}

- (void)addNewregion:(CLRegion *)region {
    [geofencingManager startMonitoringForRegion:region];
}

- (void)removeRegion:(NSString *)id {
    [geofencingManager.monitoredRegions enumerateObjectsUsingBlock:^(CLRegion *obj, BOOL *stop) {
        if ([obj.identifier localizedCaseInsensitiveCompare:id] == NSOrderedSame) {
            [geofencingManager stopMonitoringForRegion:obj];
            *stop = YES;
        }
    }];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate Protocol methods

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    PreyLogMessage(@"Prey PreyGeofencingController", 5, @"didStartMonitoringForRegion");
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    PreyLogMessage(@"Prey PreyGeofencingController", 5, @"didEnterRegion");
    
    if (region != nil) {
        NSMutableDictionary *infoEvent = [self getParametersToSend:region];
        [self sendNotifyToPanel:infoEvent withZoneInfo:@"geofencing_in"];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    PreyLogMessage(@"Prey PreyGeofencingController", 5, @"didExitRegion");
    
    if (region != nil) {
        NSMutableDictionary *infoEvent = [self getParametersToSend:region];
        [self sendNotifyToPanel:infoEvent withZoneInfo:@"geofencing_out"];
    }
}

- (NSMutableDictionary*)getParametersToSend:(CLRegion*)region
{
    NSString *accuracy  = [NSString stringWithFormat:@"%f",region.radius];
    NSString *latRegion = [NSString stringWithFormat:@"%f",region.center.latitude];
    NSString *lngRegion = [NSString stringWithFormat:@"%f",region.center.longitude];
    
    NSMutableDictionary *infoEvent = [[NSMutableDictionary alloc] init];
    [infoEvent setObject:region.identifier forKey:@"id"];
    [infoEvent setObject:latRegion forKey:@"lat"];
    [infoEvent setObject:lngRegion forKey:@"lng"];
    [infoEvent setObject:accuracy forKey:@"accuracy"];
    [infoEvent setObject:@"native" forKey:@"method"];

    return infoEvent;
}

- (void)sendNotifyToPanel:(NSDictionary*)infoEvent withZoneInfo:(NSString*)zoneInfo
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoEvent options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString;
    
    if (jsonData)
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:jsonString forKey:@"info"];
    [parameters setObject:zoneInfo forKey:@"name"];
    
    [[PreyRestHttp getClassVersion] sendJsonData:5 withData:parameters
                                      toEndpoint:[DEFAULT_CONTROL_PANEL_HOST stringByAppendingFormat: @"/devices/%@/events",[[PreyConfig instance] deviceKey]]
                                       withBlock:^(NSHTTPURLResponse *response, NSError *error) {
                                           if (error) {
                                               PreyLogMessage(@"DataModule", 10,@"Error: %@",error);
                                           } else {
                                               PreyLogMessage(@"DataModule", 10,@"DataModule: OK events");
                                           }
                                       }];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
}


@end
