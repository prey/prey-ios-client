//
//  DeviceMapController.m
//  Prey
//
//  Created by Diego Torres on 3/9/12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import "DeviceMapController.h"
@interface DeviceMapController() 
@property (nonatomic) BOOL canUpdateUserLoc;
@end

@implementation DeviceMapController

@synthesize mapa, canUpdateUserLoc;

- (id)init
{
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Current Location", nil);
        mapa = [[MKMapView alloc] initWithFrame:CGRectZero];
        mapa.showsUserLocation = YES;
        self.view = mapa;
        self.canUpdateUserLoc = NO;
        [mapa setDelegate:self];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (![CLLocationManager locationServicesEnabled]) {
        return;
    }
    CLLocationManager * MANG = [[[CLLocationManager alloc] init] autorelease];
    [MANG startMonitoringSignificantLocationChanges];
    if(MANG.location){
        [mapa setRegion:MKCoordinateRegionMakeWithDistance(MANG.location.coordinate, 2000, 2000)];
    }
    [MANG stopMonitoringSignificantLocationChanges];
    [MANG stopUpdatingLocation];
	// Do any additional setup after loading the view.
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    if(!self.canUpdateUserLoc) return;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 200, 200);
    @try {
        [mapa setRegion:region animated:YES];
    } @catch (NSException *e) {
        //Strange exception happens sometimes. This blank catch solves it.
    }
}

-(void)goToUserLocation {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.mapa.userLocation.coordinate, 200, 200);
    [mapa setRegion:region animated:YES];
    self.canUpdateUserLoc = YES;
}

-(void)viewDidAppear:(BOOL)animated {
    [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(goToUserLocation) userInfo:nil repeats:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}
-(void)dealloc {
    [mapa release];
    [super dealloc];
}
@end
