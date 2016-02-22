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

@synthesize colorsGeofence, zoneDataSourceArray, zonePickerView, zoneInputs, currentGeofenceZone;

- (void)viewDidLoad
{
    self.screenName = @"Geofence Map";
    
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Geofence", nil);
    mapa = [[MKMapView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:mapa];
    canUpdateUserLoc = NO;
    

    if (!IS_IPAD) {
        HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.labelText = NSLocalizedString(@"Please wait",nil);        
    }

    [self addGeofenceZones];
    
    // Add info button
    UIBarButtonItem *infoBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(showZones)];
    self.navigationController.topViewController.navigationItem.rightBarButtonItem = infoBtn;
}

- (void)viewWillAppear:(BOOL)animated
{
    zoneInputs      = [[UITextField alloc] initWithFrame:CGRectZero];
    [self.view addSubview:zoneInputs];
    
    zonePickerView  = [[UIPickerView alloc] initWithFrame:CGRectZero];
    [zonePickerView setBackgroundColor:[UIColor whiteColor]];
    zonePickerView.dataSource = self;
    zonePickerView.delegate = self;
    
    UIToolbar *doneBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 44)];
    [doneBar setBarStyle:UIBarStyleBlack];
    [doneBar setTranslucent:YES];
    UIBarButtonItem *spacer2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                             target:nil action:nil];
    [doneBar setItems:[NSArray arrayWithObjects:spacer2, [[UIBarButtonItem alloc]
                                                          initWithTitle:NSLocalizedString(@"Done",nil)
                                                          style:UIBarButtonItemStyleDone
                                                          target:zoneInputs
                                                          action:@selector(resignFirstResponder)],nil ] animated:YES];
    
    [zoneInputs setInputAccessoryView:doneBar];
    [zoneInputs setInputView:zonePickerView];
    
    if (IS_IPAD) {
        UITextInputAssistantItem* item = [zoneInputs inputAssistantItem];
        item.leadingBarButtonGroups = @[];
        item.trailingBarButtonGroups = @[];
    }
}


- (void)showZones
{
    [zoneInputs becomeFirstResponder];
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
            
            [mapa selectAnnotation:annotation animated:NO];
        }
        
        [mapa setDelegate:self];
        
        zoneDataSourceArray = [NSMutableArray new];
        [zoneDataSourceArray addObjectsFromArray:geofenceZones];
        
        currentGeofenceZone = (GeofenceZones*)zoneDataSourceArray[0];
        // Add MKCircle to MKMapView
        CLLocationDegrees       center_lat  = [currentGeofenceZone.lat doubleValue];
        CLLocationDegrees       center_lon  = [currentGeofenceZone.lng doubleValue];
        CLLocationDistance      radius      = [currentGeofenceZone.radius doubleValue]*3;
        CLLocationCoordinate2D  center      = CLLocationCoordinate2DMake(center_lat, center_lon);
        [self goToGeoLocation:center withDistance:radius];
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

- (void)goToGeoLocation:(CLLocationCoordinate2D)location withDistance:(CLLocationDistance)distance
{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location, distance, distance);
    @try {
        [mapa setRegion:region animated:YES];
    } @catch (NSException *e) {
        //Strange exception happens sometimes. This blank catch solves it.
    }
}


#pragma mark -
#pragma mark PickerView Data Source
- (NSInteger)numberOfComponentsInPickerView: (UIPickerView *)pickerView
{
    return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return  zoneDataSourceArray.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    GeofenceZones *item = (GeofenceZones*)zoneDataSourceArray[row];
    return item.name;
}

#pragma mark PickerView Delegate

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    GeofenceZones *item = (GeofenceZones*)zoneDataSourceArray[row];
    
    // Add MKCircle to MKMapView
    CLLocationDegrees       center_lat  = [item.lat doubleValue];
    CLLocationDegrees       center_lon  = [item.lng doubleValue];
    CLLocationDistance      radius      = [item.radius doubleValue]*3;
    CLLocationCoordinate2D  center      = CLLocationCoordinate2DMake(center_lat, center_lon);
    
    [self goToGeoLocation:center withDistance:radius];
}

#pragma mark UITextFieldDelegate Methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
