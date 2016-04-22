//
//  LoginController.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 29/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "LoginController.h"
#import "User.h"
#import "PreyConfig.h"
#import "Constants.h"
#import <CoreLocation/CoreLocation.h>
#import "PreyAppDelegate.h"
#import "PreferencesController.h"
#import "ReviewRequest.h"
#import "Constants.h"
#import "UIDevice-Reachability.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "PreyTourWebView.h"
#import "DeviceAuth.h"
#import "PreyRestHttpV2.h"
#import "PreyGeofencingController.h"
#import "PreferencesController-iPad.h"

@implementation LoginController

@synthesize loginImage, scrollView, loginPassword, nonCamuflageImage, preyLogo, devReady, detail, tipl;
@synthesize loginButton, panelButton, settingButton, hideLogin;


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	if (touch.tapCount > 0) {
        [self.view endEditing:YES];
		[self becomeFirstResponder];
	}
}

- (void) checkPassword
{
    PreyConfig *config = [PreyConfig instance];
    [User getTokenFromPanel:config.email password:loginPassword.text
                  withBlock:^(NSString *token, NSError *error)
    {
        PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
        [MBProgressHUD hideHUDForView:appDelegate.viewController.view animated:NO];
        
        if (!error) // User Login
        {
            [config setTokenPanel:token];
            [config saveValues];
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width*0, 0) animated:YES];
        }
    }]; // End Block User
  

    // Disable for JWT Login 2016.03.31
    /*
    [User allocWithEmail:config.email password:loginPassword.text
               withBlock:^(User *user, NSError *error)
     {
         PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
         [MBProgressHUD hideHUDForView:appDelegate.viewController.view animated:NO];
         
         if (!error) // User Login
         {
             [config setPro:user.isPro];
             [config saveValues];
             [self showPreferencesController];
         }
     }]; // End Block User
    */
}

- (void)showPreferencesController
{
    PreyAppDelegate *appDelegate                    = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    PreferencesController *preferencesController    = [[PreferencesController alloc] init];
    preferencesController.modalTransitionStyle      = UIModalTransitionStyleFlipHorizontal;
    if (IS_IPAD)
    {
        PreferencesController_iPad *viewController  = [[PreferencesController_iPad alloc] initWithNibName:@"PreferencesController-iPad" bundle:nil];
        viewController.leftViewController = preferencesController;
        [appDelegate.viewController pushViewController:viewController animated:YES];
    }
    else
        [appDelegate.viewController pushViewController:preferencesController animated:YES];

    [appDelegate.viewController setNavigationBarHidden:NO animated:NO];
}

- (IBAction) checkLoginPassword: (id) sender
{
	if ([loginPassword.text length] <6)
    {
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Access Denied",nil) message:NSLocalizedString(@"Wrong password. Try again.",nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alertView show];
		return;
	}
    
	[self hideKeyboard];
    
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    HUD = [MBProgressHUD showHUDAddedTo:appDelegate.viewController.view animated:YES];
    HUD.label.text = NSLocalizedString(@"Please wait",nil);
    HUD.detailsLabel.text = NSLocalizedString(@"Checking your password...",nil);
    [self checkPassword];
}

- (void) hideKeyboard {
	[loginPassword resignFirstResponder];
}

#pragma mark UI sliding methods
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self animateTextField: textField up: YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self animateTextField: textField up: NO];
}

- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    const float movementDuration = 0.3f;
    int movementDistanceY;
    
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        // Configuracion iPhone
        if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
            movementDistanceY = 160;
        else
            movementDistanceY = 200;
    }
    else
    {
        // Configuracion iPad
        if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
            movementDistanceY = 340;
        else
            movementDistanceY = 240;
    }
    
    
    int movement = (up ? -movementDistanceY : movementDistanceY);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

#pragma mark view methods

- (IBAction)goToControlPanel:(UIButton *)sender
{
    if ([[UIDevice currentDevice] networkAvailable])
    {
        NSString *body = [NSString stringWithFormat:@"token=%@",[PreyConfig instance].tokenPanel];
        UIViewController *controller = [UIWebViewController controllerToEnterdelegate:self setURL:URL_SESSION_PANEL withParameters:body];
        
        if (controller)
            [self.navigationController presentViewController:controller animated:YES completion:NULL];
    }
    else
    {
        UIAlertView *alerta = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information",nil)
                                                         message:NSLocalizedString(@"The internet connection appears to be offline",nil)
                                                        delegate:nil
                                               cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alerta show];
    }
}

- (IBAction)goToSettings:(UIButton *)sender
{
    [self showPreferencesController];
    
    // Disable for JWT Login 2016.03.31
    /*
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width, 0) animated:YES];
    
    if ( (IS_OS_8_OR_LATER) && ([PreyConfig instance].isTouchIDEnabled) )
        [self loginWithTouchID];
    */
}

- (void)runWebForgot
{
    UIViewController *controller = [UIWebViewController controllerToEnterdelegate:self setURL:URL_FORGOT_PANEL];
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    if (controller)
        [appDelegate.viewController presentViewController:controller animated:YES completion:NULL];
}

// Disable for JWT Login 2016.03.31
/*
- (void)loginWithTouchID
{
    LAContext   *context  = [[LAContext alloc] init];
    NSError     *errorCxt = nil;
    
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&errorCxt])
    {
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                localizedReason:NSLocalizedString(@"Authenticate for login?",nil)
                          reply:^(BOOL success, NSError *error) {
                              
                              if (success)
                              {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      [self showPreferencesController];
                                  });
                              }
                                  
                              else if (error.code != kLAErrorUserCancel)
                              {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil)
                                                                                      message:NSLocalizedString(@"There was a problem verifying your identity",nil)
                                                                                     delegate:nil
                                                                            cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                                            otherButtonTitles:nil];
                                      [alert show];
                                  });
                              }
                          }];
    }
}
*/

- (void)viewDidLoad
{
    if ([ReviewRequest shouldAskForReview])
        [ReviewRequest askForReview];
    
    self.screenName = @"Login";
    
/*
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        [devReady setFont:[UIFont fontWithName:@"Roboto-Regular" size:24]];
        [detail   setFont:[UIFont fontWithName:@"OpenSans" size:14]];
        [tipl     setFont:[UIFont fontWithName:@"OpenSans" size:14]];
        
        [loginButton.titleLabel   setFont:[UIFont fontWithName:@"OpenSans" size:14]];
        [panelButton.titleLabel   setFont:[UIFont fontWithName:@"OpenSans" size:14]];
        [settingButton.titleLabel setFont:[UIFont fontWithName:@"OpenSans" size:14]];
    }
    else
    {
        [devReady setFont:[UIFont fontWithName:@"Roboto-Regular" size:34]];
        [detail   setFont:[UIFont fontWithName:@"OpenSans" size:20]];
        [tipl     setFont:[UIFont fontWithName:@"OpenSans" size:20]];
        
        [loginButton.titleLabel   setFont:[UIFont fontWithName:@"OpenSans" size:20]];
        [panelButton.titleLabel   setFont:[UIFont fontWithName:@"OpenSans" size:20]];
        [settingButton.titleLabel setFont:[UIFont fontWithName:@"OpenSans" size:20]];
    }
    [settingButton setTitle:[NSLocalizedString(@"Manage Prey settings", nil) uppercaseString] forState: UIControlStateNormal];
    [panelButton setTitle:[NSLocalizedString(@"Go to Control Panel", nil) uppercaseString] forState: UIControlStateNormal];
    [loginButton setTitle:[NSLocalizedString(@"Log in to Prey", nil) uppercaseString] forState: UIControlStateNormal];
    [loginPassword setPlaceholder:NSLocalizedString(@"Type in your password", nil)];
    [tipl setText:NSLocalizedString(@"Swipe to go back", nil)];
*/
    PreyConfig *config = [PreyConfig instance];
    [self.scrollView setContentSize:CGSizeMake(scrollView.frame.size.width*2, scrollView.frame.size.height)];
    [self.loginPassword setBorderStyle:UITextBorderStyleRoundedRect];
    
    if (config.camouflageMode)
    {
        [self.nonCamuflageImage setHidden:YES];
        [self.loginImage setHidden:NO];
        [self.detail setHidden:YES];
        [self.devReady setHidden:YES];
        [self.preyLogo setHidden:YES];
        [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width*1, 0) animated:NO];
        [self.tipl setHidden:YES];
        [self configButtonsForCamouflage:YES];
        
        [loginButton setBackgroundColor:[UIColor clearColor]];
        
        if (IS_IPHONE4S) {
            scrollView.frame = CGRectMake(scrollView.frame.origin.x, scrollView.frame.origin.y+30,
                                          scrollView.frame.size.width, scrollView.frame.size.height);
        }
        
        // Disable for JWT Login 2016.03.31
        //if ( (IS_OS_8_OR_LATER) && ([PreyConfig instance].isTouchIDEnabled) )
        //    [self loginWithTouchID];
    }
    else
    {
        [self.tipl setHidden:NO];
        [self.nonCamuflageImage setHidden:NO];
        [self.loginImage setHidden:YES];
        [self.detail setHidden:NO];
        [self.devReady setHidden:NO];
        [self.preyLogo setHidden:NO];
        [self configButtonsForCamouflage:NO];
        
        // Enable for JWT Login 2016.03.31
        if (!hideLogin)
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width*1, 0) animated:NO];
    }
    
    [self.loginPassword addTarget:self action:@selector(checkLoginPassword:) forControlEvents:UIControlEventEditingDidEndOnExit];
    
    // Add forgot password
    UIButton *btnForgotPwd;
    btnForgotPwd = [[UIButton alloc] initWithFrame:tipl.frame];
    [btnForgotPwd setBackgroundColor:[UIColor clearColor]];
    [btnForgotPwd.titleLabel setFont:tipl.font];
    [btnForgotPwd setTitleColor:[UIColor colorWithRed:(148/255.f) green:(169/255.f) blue:(183/255.f) alpha:1.f] forState:UIControlStateNormal];
    [btnForgotPwd setTitleColor:[UIColor colorWithRed:(148/255.f) green:(169/255.f) blue:(183/255.f) alpha:.7] forState:UIControlStateHighlighted];
    btnForgotPwd.titleLabel.textAlignment = UITextAlignmentCenter;
    [btnForgotPwd setTitle:NSLocalizedString(@"Forgot your password?",nil) forState:UIControlStateNormal];
    [btnForgotPwd addTarget:self action:@selector(runWebForgot) forControlEvents:UIControlEventTouchUpInside];
    CGFloat fontSize = (IS_IPAD) ? 18 : 12;
    [btnForgotPwd.titleLabel   setFont:[UIFont fontWithName:@"OpenSans" size:fontSize]];
    [scrollView addSubview:btnForgotPwd];

    tipl.hidden = YES;

    // Add Tap Gesture to Prey Tour
    [self configTourTouch];
    
    [super viewDidLoad];
    
    [self changeTexts];
    
    if ([[PreyConfig instance] hideTourWeb])
        [self closeTourLabel];
    
    // Check geofencing on panel
    if ( ([PreyConfig instance].isPro) && (IS_OS_7_OR_LATER) ) {
        [PreyRestHttpV2 checkGeofenceZones:5 withBlock:^(NSHTTPURLResponse *response, NSError *error) {
            PreyLogMessage(@"App Delegate", 10, @"Geofence");
        }];
    }
    
    // Check New Version on App Store
    if ( (!config.isMissing) && ([config shouldAskForUpdateApp]) ) {
        dispatch_queue_t bgQueue = dispatch_queue_create("App Version Queue", DISPATCH_QUEUE_SERIAL);
        dispatch_async(bgQueue, ^{
            [[PreyConfig instance] checkLastVersionOnStore];
        });
    }
}

- (void)changeTexts
{
    [loginButton setTitle:[NSLocalizedString(@"Log In", nil) uppercaseString] forState: UIControlStateNormal];
    [loginPassword setPlaceholder:NSLocalizedString(@"Type in your password", nil)];
    [loginPassword setBackgroundColor:[UIColor whiteColor]];
    [loginPassword setTextColor:[UIColor blackColor]];

    
    _remoteControlLbl.text  = NSLocalizedString(@"REMOTE CONTROL FROM YOUR", nil);
    _preyAccountLbl.text    = NSLocalizedString(@"PREY ACCOUNT", nil);
    _configureLbl.text      = NSLocalizedString(@"CONFIGURE", nil);
    _preySettingsLbl.text   = NSLocalizedString(@"PREY SETTINGS", nil);
}

- (void)configTourTouch
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(startPreyTour)];
    [tap setDelegate:self];
    
    UIImageView *tourImg = (UIImageView*)[self.view viewWithTag:701];
    [tourImg setUserInteractionEnabled:YES];
    [tourImg addGestureRecognizer:tap];
    
    // Add target for close Tour Label
    UIButton *closeTourBtn = (UIButton*)[self.view viewWithTag:702];
    [closeTourBtn addTarget:self action:@selector(closeTourLabel) forControlEvents:UIControlEventTouchUpInside];
    
    
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    language = [language substringToIndex:2];

    if ([language isEqualToString:@"es"])
        tourImg.image = [UIImage imageNamed:@"tour-es"];
}

- (void)closeTourLabel
{
    UIImageView *tourImg   = (UIImageView*)[self.view viewWithTag:701];
    UIButton *closeTourBtn = (UIButton*)[self.view viewWithTag:702];

    [tourImg removeFromSuperview];
    [closeTourBtn removeFromSuperview];
}

- (void)startPreyTour
{
    PreyTourWebView *controller;
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    if (IS_IPAD)
        controller = [[PreyTourWebView alloc] initWithNibName:@"PreyTourWebView-iPad" bundle:nil];
    else
        controller = (IS_IPHONE5) ? [[PreyTourWebView alloc] initWithNibName:@"PreyTourWebView-iPhone-568h" bundle:nil] :
                                    [[PreyTourWebView alloc] initWithNibName:@"PreyTourWebView-iPhone" bundle:nil];

    if (controller)
        [appDelegate.viewController presentViewController:controller animated:YES completion:NULL];
}

- (void)configButtonsForCamouflage:(BOOL)isCamouflage
{
    if (isCamouflage)
    {
        [loginButton setBackgroundImage:[UIImage imageNamed:@"bt-camouflage"] forState:UIControlStateNormal];
        [loginButton setBackgroundImage:[UIImage imageNamed:@"bt-camouflage"] forState:UIControlStateHighlighted];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Check Device Authorization
    [self checkDeviceAuth];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int page = floor(self.scrollView.contentOffset.x/self.scrollView.frame.size.width);
    if (page != 0) {

        [self.scrollView setScrollEnabled:NO];

        // Disable for JWT Login 2016.03.31
        //PreyConfig *config = [PreyConfig instance];
        //if (!config.camouflageMode)
        //    [self.scrollView setScrollEnabled:YES];
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.scrollView.contentOffset.x < 20) {
        [self.scrollView setScrollEnabled:NO];
        [self.view endEditing:YES];
    }
}

#pragma mark UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    if ( (alertView.tag == kTagAlertViewAuthDevice) && (&UIApplicationOpenSettingsURLString != NULL) && (buttonIndex == 0) ) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
    }
}


#pragma mark Device Authorization

- (void)checkDeviceAuth {
    
    BOOL isAllAuthAvailable = [[DeviceAuth instance] checkAllDeviceAuthorization:self];
    
    self.devReady.text = (isAllAuthAvailable) ? [NSLocalizedString(@"PROTECTED", nil) uppercaseString] :
                                                [NSLocalizedString(@"NOT PROTECTED", nil) uppercaseString];

    self.detail.text   = NSLocalizedString(@"current device status", nil);
}

@end
