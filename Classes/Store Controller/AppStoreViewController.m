//
//  AppStoreViewController.m
//  Prey
//
//  Created by Javier Cala Uribe on 5/6/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

#import "AppStoreViewController.h"
#import "PreyStoreManager.h"
#import "GrettingsProViewController.h"
#import "PreyConfig.h"
#import "Constants.h"
#import "PreyAppDelegate.h"

@interface AppStoreViewController ()

@end

@implementation AppStoreViewController

@synthesize yearButton, iconPro, titleView, description, planName;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"Upgrade to Pro", nil);
    }
    return self;
}

- (void)viewDidLoad
{
    self.screenName = @"Upgrade to Pro II";
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (_isGeofencingView)
        [self changeLanguageTextForGeofencing];
    else
        [self changeLanguageTextForUpgradePro];

}

- (void)changeLanguageTextForUpgradePro
{
    titleView.text   = NSLocalizedString(@"FULL PROTECTION FOR YOUR DEVICES", nil);
    description.text = NSLocalizedString(@"100 reports per device \nUltra-fast frecuency for reports \nScan hardware for changes \nGeofencing for Home plans and over \nPriority support", nil);
    planName.text    = NSLocalizedString(@"UPGRADE NOW", nil);
    
    [self changeTextYearButton];
}

- (void)changeLanguageTextForGeofencing
{
    titleView.text   = NSLocalizedString(@"KEEP TRACK OF YOUR DEVICES WITH GEOFENCING", nil);
    description.text = NSLocalizedString(@"Get our Home plan and use our Geofencing feature to get notifications whenever your devices leave or enter an area", nil);
    planName.text    = NSLocalizedString(@"UPGRADE NOW", nil);
    
    [self changeTextYearButtonToGeofencing];
}

- (void)changeTextYearButton
{
    NSString *formattedString;
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    
    if ( [[PreyStoreManager instance].purchasableObjects count] == 1 )
    {
        SKProduct *productYear  = [[PreyStoreManager instance].purchasableObjects objectAtIndex:0];
        
        // Year Button
        [numberFormatter setLocale:productYear.priceLocale];
        formattedString = [NSString stringWithFormat:@"%@",[numberFormatter stringFromNumber:productYear.price]];
        [yearButton setTitle:formattedString forState:UIControlStateNormal];
        
        [yearButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
        [yearButton addTarget:self action:@selector(buySubscription:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)changeTextYearButtonToGeofencing
{
    [yearButton setTitle:@"Buy" forState:UIControlStateNormal];

    [yearButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [yearButton addTarget:self action:@selector(goToPanelWeb) forControlEvents:UIControlEventTouchUpInside];
}

- (void)goToPanelWeb
{
    NSLog(@"inside");
}

- (void)showCongratsPro
{
    GrettingsProViewController *controller;
    
    if (IS_IPAD)
        controller = [[GrettingsProViewController alloc] initWithNibName:@"GrettingsProViewController-iPad" bundle:nil];
    else
        controller = (IS_IPHONE5) ? [[GrettingsProViewController alloc] initWithNibName:@"GrettingsProViewController-iPhone-568h" bundle:nil] :
                                    [[GrettingsProViewController alloc] initWithNibName:@"GrettingsProViewController-iPhone" bundle:nil];

    [self.navigationController presentViewController:controller animated:YES completion:NULL];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buySubscription:(id)sender
{
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    HUD = [MBProgressHUD showHUDAddedTo:appDelegate.viewController.view animated:YES];
    HUD.labelText = NSLocalizedString(@"Please wait",nil);
    
    if ( [[PreyStoreManager instance].purchasableObjects count] == 1 )
    {
        SKProduct *product = [[PreyStoreManager instance].purchasableObjects objectAtIndex:0];
        
        [[PreyStoreManager instance] buyFeature:product.productIdentifier
                                        onComplete:^(NSString* purchasedFeature,
                                                     NSData* purchasedReceipt,
                                                     NSArray* availableDownloads)
         {
             NSLog(@"Purchased: %@", purchasedFeature);
             
             PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
             [MBProgressHUD hideHUDForView:appDelegate.viewController.view animated:NO];
             
             [[PreyConfig instance] setPro:YES];
             [[PreyConfig instance] saveValues];
             [self showCongratsPro];
         }
                                       onCancelled:^
         {
             NSLog(@"User Cancelled Transaction");
             [self showCancelMessage];
         }];

    }
    else
    {
        NSLog(@"User Cancelled Transaction");
        [self showCancelMessage];
    }
}

- (void)showCancelMessage
{
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    [MBProgressHUD hideHUDForView:appDelegate.viewController.view animated:NO];
    
    UIAlertView *alerta = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information",nil)
                                                      message:NSLocalizedString(@"Canceled transaction, please try again.",nil)
                                                     delegate:nil
                                            cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
    [alerta show];

}

@end
