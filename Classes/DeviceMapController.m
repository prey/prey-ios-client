//
//  DeviceMapController.m
//  Prey
//
//  Created by Diego Torres on 3/9/12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import "DeviceMapController.h"
#import "PreyAppDelegate.h"

@implementation DeviceMapController

@synthesize mapa, canUpdateUserLoc, MANG;

- (void)viewDidLoad
{
    self.screenName = @"Device Map";
    
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Current Location", nil);
    mapa = [[MKMapView alloc] initWithFrame:self.view.bounds];
    //mapa.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    mapa.showsUserLocation = YES;
    [self.view addSubview:mapa];
    canUpdateUserLoc = NO;
    [mapa setDelegate:self];
    
    
    if (![CLLocationManager locationServicesEnabled]) {
        return;
    }
    MANG = [[CLLocationManager alloc] init];
    [MANG startMonitoringSignificantLocationChanges];
    if(MANG.location){
        [mapa setRegion:MKCoordinateRegionMakeWithDistance(MANG.location.coordinate, 2000, 2000)];
    }
    [MANG stopMonitoringSignificantLocationChanges];
    [MANG stopUpdatingLocation];
	// Do any additional setup after loading the view.
    
    [self goToUserLocation];
    
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.labelText = NSLocalizedString(@"Please wait",nil);
}

- (void)goToUserLocation {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(mapa.userLocation.coordinate, 200, 200);
    @try {
        [mapa setRegion:region animated:YES];
        canUpdateUserLoc = YES;
    } @catch (NSException *e) {
        //Strange exception happens sometimes. This blank catch solves it.
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    if(!canUpdateUserLoc) return;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 200, 200);
    @try {
        [mapa setRegion:region animated:YES];
    } @catch (NSException *e) {
        //Strange exception happens sometimes. This blank catch solves it.
    }
}

- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView{
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView{
    [MBProgressHUD hideHUDForView:self.view animated:NO];
}

- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error{
    [MBProgressHUD hideHUDForView:self.view animated:NO];
    UIAlertView *alerta = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"We have a situation!",nil)
                                                     message:NSLocalizedString(@"Error loading map, please try again.",nil)
                                                    delegate:nil
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
    [alerta show];
}

@end