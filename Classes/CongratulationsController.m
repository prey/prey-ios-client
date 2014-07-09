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
#import "LoginController.h"
#import "PreferencesController.h"
#import "Constants.h"

@implementation CongratulationsController

@synthesize congratsTitle, congratsMsg, ok, txtToShow, authLocation;

#pragma mark -
#pragma mark IBActions
- (IBAction) okPressed: (id) sender
{
    @try
    {
        PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
        
        LoginController *loginController;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        {
            if (IS_IPHONE5)
                loginController = [[LoginController alloc] initWithNibName:@"LoginController-iPhone-568h" bundle:nil];
            else
                loginController = [[LoginController alloc] initWithNibName:@"LoginController-iPhone" bundle:nil];
        }
        else
            loginController = [[LoginController alloc] initWithNibName:@"LoginController-iPad" bundle:nil];
        
        [appDelegate.viewController setViewControllers:[NSArray arrayWithObjects:loginController, nil] animated:NO];
    }
    @catch (NSException *exception) {
        PreyLogMessage(@"CongratulationsController", 0, @"CongratulationsController bug: %@", [exception reason]);
    }
}

- (void)viewDidLoad
{
    self.screenName = @"Congratulations";
    
    congratsMsg.font             = [UIFont fontWithName:@"Helvetica" size:20];
    congratsMsg.numberOfLines    = 5;
    congratsMsg.textAlignment    = UITextAlignmentCenter;
    congratsMsg.backgroundColor  = [UIColor clearColor];
    congratsMsg.text             = txtToShow;
    
    authLocation = [[CLLocationManager alloc] init];
    [authLocation  startUpdatingLocation];
    [authLocation stopUpdatingLocation];
	[self.ok setTitle:NSLocalizedString(@"OK",nil) forState:UIControlStateNormal];
    
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	/*
    self.title = @"Congratulations";
    self.congratsTitle.text = NSLocalizedString(@"Congratulations!",nil);
     */
	//self.congratsMsg.text = NSLocalizedString(@"You have successfully associated this device with your Prey Control Panel account.",nil);

	[super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

@end
