//
//  DeviceMapController.m
//  Prey
//
//  Created by Diego Torres on 3/9/12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import "DeviceMapController.h"

@implementation DeviceMapController

@synthesize mapa;

- (id)init
{
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Device Location", nil);
        self.mapa = [[MKMapView alloc] initWithFrame:CGRectZero];
        self.mapa.showsUserLocation = YES;
        self.view = self.mapa;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(-33.44375, -70.650344);
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coords, 200, 200);
    [mapa setRegion:region animated:YES];
    if (![CLLocationManager locationServicesEnabled]) {
        NSLog(@"noooo");
        return;
    }
    CLLocationManager * MANG = [[[CLLocationManager alloc] init] autorelease];
    [MANG startMonitoringSignificantLocationChanges];
    if(MANG.location){
        [mapa setCenterCoordinate:MANG.location.coordinate animated:NO];
    }
    [MANG stopMonitoringSignificantLocationChanges];
    [MANG stopUpdatingLocation];
	// Do any additional setup after loading the view.
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
