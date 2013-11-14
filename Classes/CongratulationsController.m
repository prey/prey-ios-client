//
//  CongratulationsController.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 04/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <CoreLocation/CoreLocation.h>
#import "CongratulationsController.h"
#import "PreyAppDelegate.h"
#import "PreferencesController.h"
#import "PreyRunner.h"


@implementation CongratulationsController

@synthesize congratsTitle, congratsMsg, ok, txtToShow;

#pragma mark -
#pragma mark IBActions
- (IBAction) okPressed: (id) sender{
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    PreferencesController *preferencesController = [[PreferencesController alloc] initWithNibName:@"PreferencesController" bundle:nil];
    [appDelegate.viewController pushViewController:preferencesController animated:NO];
    [preferencesController release];
    
    if ([self.parentViewController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) // Check iOS 5.0 or later
        [self.parentViewController dismissViewControllerAnimated:YES completion:NULL];
    else
        [self.parentViewController dismissModalViewControllerAnimated:YES];
    
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    self.screenName = @"Congratulations";
    
    congratsMsg.font             = [UIFont fontWithName:@"Helvetica" size:20];
    congratsMsg.numberOfLines    = 5;
    congratsMsg.textColor        = [UIColor colorWithWhite:0.200 alpha:1.000];
    congratsMsg.textAlignment    = UITextAlignmentCenter;
    congratsMsg.backgroundColor  = [UIColor clearColor];
    congratsMsg.text             = txtToShow;

	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	/*
    self.title = @"Congratulations";
    self.congratsTitle.text = NSLocalizedString(@"Congratulations!",nil);
     */
	//self.congratsMsg.text = NSLocalizedString(@"You have successfully associated this device with your Prey Control Panel account.",nil);

    CLLocationManager *tempCL = [[[CLLocationManager alloc] init] autorelease];
    [tempCL  startUpdatingLocation];
    [tempCL stopUpdatingLocation];
	[self.ok setTitle:NSLocalizedString(@"OK",nil) forState:UIControlStateNormal];
	[super viewWillAppear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
    [[PreyRunner instance] startOnIntervalChecking];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[congratsMsg release];
	[congratsTitle release];
	[ok release];
	[super dealloc];
}


@end
