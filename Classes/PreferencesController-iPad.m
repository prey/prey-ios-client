//
//  PreferencesController-iPad.m
//  Prey
//
//  Created by Javier Cala Uribe on 17/02/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

#import "PreferencesController-iPad.h"
#import "RecoveriesViewController.h"
#import "UIDevice-Reachability.h"
#import "DeviceMapController.h"
#import "PreyAppDelegate.h"
#import "PreyCoreData.h"
#import "Constants.h"
#import "PreyItems.h"

@implementation PreferencesController_iPad

@synthesize leftView, rightView, leftViewController, mapController, recoveriesViewController;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add PreferencesView to LeftView
    [leftView addSubview:leftViewController.view];
    
    // Init with CurrentLocation to RightView
    [self showDeviceMapController];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [tableViewInfo selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Actions

- (void)removePreviewViewController
{
    UIViewController *vc = [self.childViewControllers lastObject];
    if (vc != nil) {
        [vc willMoveToParentViewController:nil];
        [vc.view removeFromSuperview];
        [vc removeFromParentViewController];
    }
}

- (void)addViewControllerToMainVC:(id)viewController
{
    [self addChildViewController:viewController];
    [viewController didMoveToParentViewController:self];
}

- (void)showDeviceMapController
{
    [self removePreviewViewController];
    
    if (!mapController) {
        mapController = [[DeviceMapController alloc] init];
        mapController.view.frame = CGRectMake(0, 0, rightView.frame.size.width, rightView.frame.size.height);
    }

    [rightView addSubview:mapController.view];
    
    [self addViewControllerToMainVC:mapController];
}

- (void)showRecoveriesController
{
    if ([[UIDevice currentDevice] networkAvailable])
    {
        [self removePreviewViewController];
        
        if (!recoveriesViewController) {
            recoveriesViewController = [[RecoveriesViewController alloc] init];
            recoveriesViewController.view.frame = CGRectMake(0, 0, rightView.frame.size.width, rightView.frame.size.height);            
        }
        
        [rightView addSubview:recoveriesViewController.view];
        
        [self addViewControllerToMainVC:recoveriesViewController];
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

- (void)showWebController:(NSString*)url withTitle:(NSString*)titleTxt
{
    UIWebView *webView      = [[UIWebView alloc] initWithFrame:CGRectZero];
    HUD                     = [MBProgressHUD showHUDAddedTo:webView animated:YES];
    HUD.labelText           = NSLocalizedString(@"Please wait",nil);
    
    UIViewController *vc    = [[UIViewController alloc] init];
    vc.view                 = webView;
    vc.view.frame           = CGRectMake(0, 0, rightView.frame.size.width, rightView.frame.size.height);
    
    NSURLRequest *req       = nil;
    req                     = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    vc.title                = titleTxt;

    [webView setDelegate:self];
    [webView loadRequest:req];
    [webView setScalesPageToFit:YES];
    
    [rightView addSubview:vc.view];
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
            // === INFORMATION ===
        case PreyPreferencesSectionInformation:

            // Current Location
            if (indexPath.row == PreyPreferencesSectionInformationCurrentLocation)
                [self showDeviceMapController];
            
            // Geofence
            else if (indexPath.row == PreyPreferencesSectionInformationGeofence)
                [self showGeofenceMapVC];
            
            // Recovery Stories
            else if (indexPath.row == PreyPreferencesSectionInformationRecoveryStories)
                [self showRecoveriesController];
            
            // Share on Facebook
            else if (indexPath.row == PreyPreferencesSectionInformationShareOnFacebook)
                [self postToSocialFramework:SLServiceTypeFacebook];
            
            // Share on Twitter
            else if (indexPath.row == PreyPreferencesSectionInformationShareOnTwitter)
                [self postToSocialFramework:SLServiceTypeTwitter];
            
            // Upgrade To Pro
            else if (indexPath.row == PreyPreferencesSectionInformationUpgradeToPro)
                [self showAppStoreVC];
                
            break;
            
            
            // === SETTINGS ===
        case PreyPreferencesSectionSettings:
           
            // Detach Device
            if (indexPath.row == PreyPreferencesSectionSettingsDetachDevice)
                [self showDetachDeviceAction];
                
            break;
            
            
            // === ABOUT ===
        case PreyPreferencesSectionAbout:
            
            // Help
            if (indexPath.row == PreyPreferencesSectionAboutHelp)
                [self showWebController:URL_HELP_PREY withTitle:NSLocalizedString(@"Help", nil)];
            
            // Term of Service
            else if (indexPath.row == PreyPreferencesSectionAboutTermService)
                [self showWebController:URL_TERMS_PREY withTitle:NSLocalizedString(@"Terms of Service", nil)];
            
            // Privacy Policy
            else if (indexPath.row == PreyPreferencesSectionAboutPrivacyPolicy)
                [self showWebController:URL_PRIVACY_PREY withTitle:NSLocalizedString(@"Privacy Policy", nil)];
            
            break;
    }
}

@end
