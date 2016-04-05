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
#import "PhotoController.h"
#import "Constants.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "PreyConfig.h"

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
        if (IS_IPAD)
            loginController = [[LoginController alloc] initWithNibName:@"LoginController-iPad" bundle:nil];
        else
            loginController = (IS_IPHONE5) ? [[LoginController alloc] initWithNibName:@"LoginController-iPhone-568h" bundle:nil] :
                                             [[LoginController alloc] initWithNibName:@"LoginController-iPhone" bundle:nil];
        
        loginController.hideLogin = YES;
        
        [appDelegate.viewController setViewControllers:[NSArray arrayWithObjects:loginController, nil] animated:NO];
    }
    @catch (NSException *exception) {
        PreyLogMessage(@"CongratulationsController", 0, @"CongratulationsController bug: %@", [exception reason]);
    }
}

- (void)viewDidLoad
{
    self.screenName = @"Congratulations";

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        [congratsTitle setFont:[UIFont fontWithName:@"Roboto-Regular" size:24]];
        [congratsMsg   setFont:[UIFont fontWithName:@"OpenSans" size:14]];
        [ok.titleLabel setFont:[UIFont fontWithName:@"OpenSans" size:14]];
    }
    else
    {
        [congratsTitle setFont:[UIFont fontWithName:@"Roboto-Regular" size:36]];
        [congratsMsg   setFont:[UIFont fontWithName:@"OpenSans" size:20]];
        [ok.titleLabel setFont:[UIFont fontWithName:@"OpenSans" size:30]];
    }
    
    congratsMsg.numberOfLines    = 5;
    congratsMsg.textAlignment    = UITextAlignmentCenter;
    congratsMsg.backgroundColor  = [UIColor clearColor];
    congratsMsg.text             = txtToShow;

    [congratsTitle setText:[NSLocalizedString(@"Device set up!",nil) uppercaseString]];
    [ok setTitle:[NSLocalizedString(@"OK",nil) uppercaseString] forState:UIControlStateNormal];

    authLocation = [[CLLocationManager alloc] init];
    
    if (IS_OS_8_OR_LATER)
    {
        [authLocation requestAlwaysAuthorization];
        
        // Authorization Camera
        [PhotoController instance];

        // Disable for JWT Login 2016.03.31
        // Check TouchID
        //[self checkTouchID];
    }
    else
    {
        [authLocation  startUpdatingLocation];
        [authLocation stopUpdatingLocation];
    }
    
	[super viewDidLoad];
}

// Disable for JWT Login 2016.03.31
/*
- (void)checkTouchID
{
    LAContext   *context  = [[LAContext alloc] init];
    NSError     *errorCxt = nil;
    
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&errorCxt])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information",nil)
                                                        message:NSLocalizedString(@"Would you like to use Touch ID to access the Prey settings?",nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                              otherButtonTitles:NSLocalizedString(@"OK",nil),nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [PreyConfig instance].isTouchIDEnabled = YES;
        [[PreyConfig instance] saveValues];
    }
}
*/


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
