//
//  GeofenceMapController.m
//  Prey
//
//  Created by Javier Cala Uribe on 17/02/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

#import "GeofenceMapController.h"
#import "PreyCoreData.h"
#import "GeofenceZones.h"
#import "RegionAnnotation.h"
#import "Constants.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@implementation GeofenceMapController

@synthesize colorsGeofence;

- (void)viewDidLoad
{
    self.screenName = @"Geofence Map";
    
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Geofence", nil);
    mapa = [[MKMapView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:mapa];
    canUpdateUserLoc = NO;
    [mapa setDelegate:self];
    
    if (![CLLocationManager locationServicesEnabled])
        return;

    MANG = [[CLLocationManager alloc] init];
    [MANG startMonitoringSignificantLocationChanges];
    if(MANG.location)
        [mapa setRegion:MKCoordinateRegionMakeWithDistance(MANG.location.coordinate, 2000, 2000)];
    
    [MANG stopMonitoringSignificantLocationChanges];
    [MANG stopUpdatingLocation];
    // Do any additional setup after loading the view.
    
    [self goToUserLocation];
    
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.labelText = NSLocalizedString(@"Please wait",nil);

    [self addGeofenceZones];
}

- (void)addGeofenceZones
{
    [self resetColorGeofence];
    NSArray *geofenceZones  = [[PreyCoreData instance] getCurrentGeofenceZones];
    if (geofenceZones)
    {
        for (GeofenceZones *info in geofenceZones)
        {
            // Add MKCircle to MKMapView
            CLLocationDegrees       center_lat  = [info.lat doubleValue];
            CLLocationDegrees       center_lon  = [info.lng doubleValue];
            CLLocationDistance      radius      = [info.radius doubleValue];
            CLLocationCoordinate2D  center      = CLLocationCoordinate2DMake(center_lat, center_lon);
            NSString                *zoneID     = [NSString stringWithFormat:@"%f",[info.zone_id floatValue]];
            
            MKCircle *circleOverlay = [MKCircle circleWithCenterCoordinate:center radius:radius];
            circleOverlay.title     = zoneID;
            [mapa addOverlay:circleOverlay];
            
            // Save geofence color on colorsGeofence
            [self saveColorGeofence:info.color withZone:zoneID];
            
            // Add MKAnnotation to MKMapView
            CLCircularRegion        *region;
            if ([CLLocationManager isMonitoringAvailableForClass:[CLRegion class]])
                region =  [[CLCircularRegion alloc] initWithCenter:center radius:radius identifier:zoneID];
            
            RegionAnnotation *annotation = [[RegionAnnotation alloc] initWithCLRegion:region withTitle:info.name];
            [mapa addAnnotation:annotation];
        }
    }
}

- (void)saveColorGeofence:(NSString*)color withZone:(NSString*)zone
{
    if (colorsGeofence == nil)
        colorsGeofence = [[NSMutableDictionary alloc] init];
    
    [colorsGeofence setObject:color forKey:zone];
}

- (void)resetColorGeofence
{
    if (colorsGeofence != nil)
        [colorsGeofence removeAllObjects];
    
    colorsGeofence = nil;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKCircle class]])
    {
        NSString *colorHex    = [colorsGeofence objectForKey:overlay.title];
        NSString *colorString = [[colorHex stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];
        
        unsigned result       = 0;
        NSScanner *scanner    = [NSScanner scannerWithString:colorString];
        [scanner scanHexInt:&result];
        
        
        MKCircleRenderer* aRenderer = [[MKCircleRenderer alloc] initWithCircle:(MKCircle *)overlay];
        
        aRenderer.fillColor     = [UIColorFromRGB(result) colorWithAlphaComponent:0.3];
        aRenderer.strokeColor   = [UIColorFromRGB(result) colorWithAlphaComponent:0.9];
        aRenderer.lineWidth     = 3;
        
        return aRenderer;
    }
    else
        return nil;
}

- (void)goToUserLocation {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(mapa.userLocation.coordinate, 1000, 1000);
    @try {
        [mapa setRegion:region animated:YES];
        canUpdateUserLoc = YES;
    } @catch (NSException *e) {
        //Strange exception happens sometimes. This blank catch solves it.
    }
}

#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    if(!canUpdateUserLoc) return;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 1000, 1000);
    @try {
        [mapa setRegion:region animated:YES];
    } @catch (NSException *e) {
        //Strange exception happens sometimes. This blank catch solves it.
    }
}

@end
