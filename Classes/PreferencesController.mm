//
//  PreferencesController.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 29/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "PreferencesController.h"
#import "PreyAppDelegate.h"
#import "PreyConfig.h"
#import "PreyRestHttp.h"
#import "DeviceMapController.h"
#import "AppStoreViewController.h"
#import "Constants.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#import "Constants.h"
#import "CamouflageModule.h"
#import "RecoveriesViewController.h"
#import "UIDevice-Reachability.h"
#import "OnboardingView.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "PreyCoreData.h"
#import "GeofenceMapController.h"
#import "PreyItems.h"

@interface UIActionSheet(DismissAlert)
- (void)hide;
@end

@implementation UIActionSheet(DismissAlert)

- (void)hide{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationDidEnterBackgroundNotification" object:nil];
    [self dismissWithClickedButtonIndex:[self cancelButtonIndex] animated:NO];
}
@end



@implementation PreferencesController

@synthesize tableViewInfo, textsToShareArrayEN, textsToShareArrayES;


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return PreyPreferencesSectionNumberToDataSourceDelegate;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger numberRows;
    
	switch (section)
    {
            // === INFORMATION ===
        case PreyPreferencesSectionInformation:
            numberRows = PreyPreferencesSectionInformationNumberToDataSourceDelegate;
            
            if ([[PreyConfig instance] isPro])
                numberRows--;
            
            if (![self isSocialFrameworkAvailable])
                numberRows-=2;
            
            break;
            
            // === SETTINGS ===
		case PreyPreferencesSectionSettings:
            numberRows = PreyPreferencesSectionSettingsNumberToDataSourceDelegate;
            
            if (![self isTouchIDAvailable])
                numberRows--;
            
			break;

            // === ABOUT ===
        case PreyPreferencesSectionAbout:
            numberRows = PreyPreferencesSectionAboutNumberToDataSourceDelegate;
            
			break;
	}
    
    return numberRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    NSString *titleSection;
    
    switch (section) {
        case PreyPreferencesSectionInformation:
            titleSection = NSLocalizedString(@"Information",nil);;
            break;
        case PreyPreferencesSectionSettings:
			titleSection = NSLocalizedString(@"Settings",nil);
			break;
		case PreyPreferencesSectionAbout:
			titleSection = NSLocalizedString(@"About",nil);
			break;
	}
	return titleSection;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor whiteColor];
        
        if (IS_IPAD)
        {
            [cell.textLabel  setFont:[UIFont fontWithName:@"OpenSans" size:16]];
            [cell.detailTextLabel setFont:[UIFont fontWithName:@"OpenSans" size:16]];
        }
        else
        {
            [cell.textLabel  setFont:[UIFont fontWithName:@"OpenSans" size:14]];
            [cell.detailTextLabel setFont:[UIFont fontWithName:@"OpenSans" size:14]];
        }
        
        [cell.textLabel setTextColor:[UIColor colorWithRed:(72/255.f) green:(84/255.f) blue:(102/255.f) alpha:1]];
        [cell.detailTextLabel setTextColor:[UIColor colorWithRed:(72/255.f) green:(84/255.f) blue:(102/255.f) alpha:.3f]];
    }
    
    PreyConfig *config = [PreyConfig instance];
    switch ([indexPath section]) {
        
            // === INFORMATION ===
        
        case PreyPreferencesSectionInformation:
            
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;

            // Current Location
            if (indexPath.row == PreyPreferencesSectionInformationCurrentLocation) {
                cell.textLabel.text = NSLocalizedString(@"Current Location",nil);
                cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            }

            // Geofence
            else if (indexPath.row == PreyPreferencesSectionInformationGeofence) {
                
                NSString *fontLabel = @"OpenSans-Bold";
                CGFloat  fontSize   = (IS_IPAD) ? 16.0f : 14.0f;
                [cell.textLabel setFont:[UIFont fontWithName:fontLabel size:fontSize]];
                
                UILabel *accessoryLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 70, 30)];
                [accessoryLbl setBackgroundColor:[UIColor colorWithRed:(209.0f/255.0f) green:(157.0f/255.0f) blue:(35.0f/255.0f) alpha:1.0f]];
                [accessoryLbl setText:NSLocalizedString(@"New",nil)];
                [accessoryLbl setTextAlignment:NSTextAlignmentCenter];
                [accessoryLbl setFont:[UIFont fontWithName:fontLabel size:fontSize]];
                cell.accessoryView = accessoryLbl;
                
                [self shakeAnimation:accessoryLbl];
                
                cell.textLabel.text = NSLocalizedString(@"Your Geofences",nil);
                cell.accessoryType  = UITableViewCellAccessoryNone;
            }

            // Recovery Stories
            else if (indexPath.row == PreyPreferencesSectionInformationRecoveryStories) {
                cell.textLabel.text = NSLocalizedString(@"Recovery Stories",nil);
                cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            }
            
            // Share on Facebook
            else if (indexPath.row == PreyPreferencesSectionInformationShareOnFacebook) {
                cell.textLabel.text = NSLocalizedString(@"Share on Facebook",nil);
                cell.accessoryType  = UITableViewCellAccessoryNone;
            }
            
            // Share on Twitter
            else if (indexPath.row == PreyPreferencesSectionInformationShareOnTwitter) {
                cell.textLabel.text = NSLocalizedString(@"Share on Twitter",nil);
                cell.accessoryType  = UITableViewCellAccessoryNone;
            }
            
            // Upgrade to Pro
            else if (indexPath.row == PreyPreferencesSectionInformationUpgradeToPro) {
                cell.textLabel.text = NSLocalizedString(@"Upgrade to Pro",nil);
                cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            }
            
            break;
            
            
            // === SETTINGS ===
            
		case PreyPreferencesSectionSettings:
            
            // Camouflage
            if (indexPath.row == PreyPreferencesSectionSettingsCamouglafeMode) {
                UISwitch *camouflageMode = [[UISwitch alloc]init];
                cell.textLabel.text      = NSLocalizedString(@"Camouflage mode",nil);
                [camouflageMode addTarget: self action: @selector(camouflageModeState:) forControlEvents:UIControlEventValueChanged];
                [camouflageMode setOn:config.camouflageMode];
                cell.accessoryView       = camouflageMode;
            }
            
            // Detach Device
            else if (indexPath.row == PreyPreferencesSectionSettingsDetachDevice) {
				cell.textLabel.text = NSLocalizedString(@"Detach device",nil);
				cell.accessoryType  = UITableViewCellAccessoryNone;
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                cell.accessoryView  = nil;
            }
            
            // Touch ID
            else if (indexPath.row == PreyPreferencesSectionSettingsTouchID) {
                UISwitch *touchIDMode = [[UISwitch alloc]init];
                cell.textLabel.text   = NSLocalizedString(@"Touch ID",nil);
                [touchIDMode addTarget: self action: @selector(touchIDModeState:) forControlEvents:UIControlEventValueChanged];
                [touchIDMode setOn:config.isTouchIDEnabled];
                cell.accessoryView    = touchIDMode;
            }

			break;
            
            
            // === ABOUT ===
            
		case PreyPreferencesSectionAbout:
            
            cell.detailTextLabel.text = @"";
            
            if (cell.accessoryView)
                [cell.accessoryView removeFromSuperview];
            
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryView = nil;
            
            
            // Version
			if (indexPath.row == PreyPreferencesSectionAboutVersion) {
                cell.detailTextLabel.text   = [Constants appVersion];
                cell.textLabel.text         = NSLocalizedString(@"Version",nil);
            }
            
            // Help
            else if (indexPath.row == PreyPreferencesSectionAboutHelp) {
                cell.textLabel.text = NSLocalizedString(@"Help", nil);
                cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            }

            // Term of Service
            else if (indexPath.row == PreyPreferencesSectionAboutTermService) {
                cell.textLabel.text = NSLocalizedString(@"Terms of Service", nil);
                cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            }
            
            // Privacy Policy
            else if (indexPath.row == PreyPreferencesSectionAboutPrivacyPolicy) {
                cell.textLabel.text = NSLocalizedString(@"Privacy Policy", nil);
                cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            }
            
			break;
	}
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    if (IS_OS_7_OR_LATER)
    {
        if (section == 0)
            return 35;
        else
            return nil;
    }
    else
        return -1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (IS_OS_7_OR_LATER)
        return nil;
    else
        return -1;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    CGFloat sizeFontSection             = (IS_IPAD) ? 14.0f : 12.0f;
    header.textLabel.font               = [UIFont fontWithName:@"OpenSans-Semibold" size:sizeFontSection];
    
    [header.textLabel  setTextColor:[UIColor colorWithRed:(72/255.f) green:(84/255.f) blue:(102/255.f) alpha:.3]];
}



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
                [self showAppStoreVC:NO];
            
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

#pragma mark -
#pragma mark Switches methods

- (IBAction)camouflageModeState:(UISwitch*)camouflageModeSwitch{
    [[PreyConfig instance] setCamouflageMode:camouflageModeSwitch.on];
    [[PreyConfig instance] saveValues];
}

- (IBAction)touchIDModeState:(UISwitch*)touchIDModeSwitch{
    [[PreyConfig instance] setIsTouchIDEnabled:touchIDModeSwitch.on];
    [[PreyConfig instance] saveValues];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (actionSheet.tag == 1)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:actionSheet name:@"UIApplicationDidEnterBackgroundNotification" object:nil];
		NSIndexPath *indexPath = [tableViewInfo indexPathForSelectedRow];
		[tableViewInfo deselectRowAtIndexPath:indexPath animated:YES];
        
		if (buttonIndex == 0){
            [self detachDevice];
        }
	}
}

- (void)showAppStoreVC:(BOOL)isGeofencing
{
    AppStoreViewController *viewController;
    
    if (IS_IPAD)
        viewController = [[AppStoreViewController alloc] initWithNibName:@"AppStoreViewController-iPad" bundle:nil];
    else
        viewController = (IS_IPHONE5) ? [[AppStoreViewController alloc] initWithNibName:@"AppStoreViewController-iPhone-568h" bundle:nil] :
                                        [[AppStoreViewController alloc] initWithNibName:@"AppStoreViewController-iPhone" bundle:nil];

    viewController.isGeofencingView = isGeofencing;
    
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)showGeofenceMapVC
{
    if ([[PreyCoreData instance] isGeofenceActive])
    {
        GeofenceMapController *geofenceMapController = [[GeofenceMapController alloc] init];
        [self.navigationController pushViewController:geofenceMapController animated:YES];
    }
    else if ([[PreyConfig instance] isPro])
    {
        UIAlertView *alerta = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information",nil)
                                                         message:NSLocalizedString(@"You don't have geofences",nil)
                                                        delegate:nil
                                               cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alerta show];
    }
    else
        [self showAppStoreVC:YES];
}

- (void)showDeviceMapController
{
    DeviceMapController *deviceMapController = [[DeviceMapController alloc] init];
    [self.navigationController pushViewController:deviceMapController animated:YES];
}

- (void)showRecoveriesController
{
    if ([[UIDevice currentDevice] networkAvailable])
    {
        RecoveriesViewController *recoveriesController = [[RecoveriesViewController alloc] init];
        recoveriesController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate.viewController setNavigationBarHidden:NO animated:NO];
        [appDelegate.viewController pushViewController:recoveriesController animated:YES];
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

- (void)showDetachDeviceAction
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You're about to delete this device from the Control Panel.\n Are you sure?",nil)
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"No, don't delete",nil)
                                               destructiveButtonTitle:NSLocalizedString(@"Yes, remove from my account",nil)
                                                    otherButtonTitles:nil];
    if (IS_IPAD)
        [actionSheet addButtonWithTitle:NSLocalizedString(@"No, don't delete",nil)];
    
    actionSheet.tag = kDetachAction;
    [actionSheet showInView:self.view];
    
    [[NSNotificationCenter defaultCenter] addObserver:actionSheet
                                             selector:@selector(hide)
                                                 name:@"UIApplicationDidEnterBackgroundNotification"
                                               object:nil];
}

- (void)showWebController:(NSString*)url withTitle:(NSString*)titleTxt
{
    UIWebView *webView      = [[UIWebView alloc] initWithFrame:CGRectZero];
    HUD                     = [MBProgressHUD showHUDAddedTo:webView animated:YES];
    HUD.label.text          = NSLocalizedString(@"Please wait",nil);
    
    UIViewController *vc    = [[UIViewController alloc] init];
    vc.view                 = webView;
    
    NSURLRequest *req       = nil;
    req                     = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    vc.title                = titleTxt;
    
    [webView setDelegate:self];
    [webView loadRequest:req];
    [webView setScalesPageToFit:YES];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)detachDevice
{
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    HUD = [MBProgressHUD showHUDAddedTo:appDelegate.viewController.view animated:YES];
    HUD.label.text = NSLocalizedString(@"Detaching device ...",nil);

    
    [[PreyRestHttp getClassVersion] deleteDevice:5 withBlock:^(NSHTTPURLResponse *response, NSError *error)
     {
         PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
         [MBProgressHUD hideHUDForView:appDelegate.viewController.view animated:NO];
         
         if (!error)
         {
             [[PreyConfig instance] resetValues];
             
             UIViewController *onboardingVC;
             
             if (IS_IPAD)
                 onboardingVC = [[OnboardingView alloc] initWithNibName:@"OnboardingView-iPad" bundle:nil];
             else
                 onboardingVC = (IS_IPHONE5) ? [[OnboardingView alloc] initWithNibName:@"OnboardingView-iPhone-568h" bundle:nil] :
                                               [[OnboardingView alloc] initWithNibName:@"OnboardingView-iPhone" bundle:nil];
             
             tableViewInfo.delegate   = nil;
             tableViewInfo.dataSource = nil;
             tableViewInfo = nil;
             
             PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
             [appDelegate.viewController setNavigationBarHidden:YES animated:NO];
             [appDelegate.viewController setViewControllers:[NSArray arrayWithObject:onboardingVC] animated:NO];
         }
     }];
}

- (void)shakeAnimation:(UILabel*)label
{
    CABasicAnimation* shake = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    shake.fromValue         = [NSNumber numberWithFloat:-0.1];
    shake.toValue           = [NSNumber numberWithFloat:+0.1];
    shake.duration          = 0.08;
    shake.autoreverses      = YES;
    shake.repeatCount       = 5;
    [label.layer addAnimation:shake forKey:@"buttonShake"];
}

#pragma mark Touch ID

- (BOOL)isTouchIDAvailable
{
    return NO;
    // Disable for JWT Login 2016.03.31
    /*
    BOOL isAvailable = NO;
    
    if (IS_OS_8_OR_LATER)
    {
        LAContext   *context  = [[LAContext alloc] init];
        NSError     *errorCxt = nil;
        
        if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&errorCxt])
            isAvailable = YES;
    }
    
    return isAvailable;
    */
}


#pragma mark -
#pragma mark Events received

- (void)reloadData:(NSNotification *)notification
{
	[tableViewInfo reloadData];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    self.screenName = @"Preferences";
    
    self.title = [[UIDevice currentDevice] name];    
    //self.title = NSLocalizedString(@"Preferences", nil);

    self.view.backgroundColor = [UIColor whiteColor];
    
    // TableView Config
    CGRect frameTable = (IS_IPAD) ? CGRectMake(0,44, 250, 980) : self.view.frame;
    
    tableViewInfo = [[UITableView alloc] initWithFrame:frameTable style:UITableViewStyleGrouped];
    [tableViewInfo setBackgroundView:nil];
    [tableViewInfo setBackgroundColor:[UIColor whiteColor]];
    [tableViewInfo setSeparatorColor:[UIColor colorWithRed:(240/255.f) green:(243/255.f) blue:(247/255.f) alpha:1]];
    tableViewInfo.rowHeight  = (IS_IPAD) ? 65 : 44;
    tableViewInfo.delegate   = self;
    tableViewInfo.dataSource = self;
    [self.view addSubview:tableViewInfo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData:) name:@"proUpdated" object:nil];
    
    [tableViewInfo reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController setToolbarHidden:YES animated:NO];
    
    
    currentCamouflageMode = [PreyConfig instance].camouflageMode;
    
    [self initTextToShareSocialMedia];
    
    [super viewDidLoad];
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    if ( (![parent isEqual:self.parentViewController]) && (currentCamouflageMode != [PreyConfig instance].camouflageMode) )
    {
        CamouflageModule *camouflageModule = [[CamouflageModule alloc] init];
        
        if ([PreyConfig instance].camouflageMode)
            [camouflageModule start];
        else
            [camouflageModule stop];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!IS_IPAD) {
        NSIndexPath *indexPath = [tableViewInfo indexPathForSelectedRow];
        [tableViewInfo deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    if (IS_OS_7_OR_LATER)
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (IS_OS_7_OR_LATER)
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}


#pragma mark -
#pragma mark Social Framework

- (void)initTextToShareSocialMedia
{
    textsToShareArrayEN = @[@"Just installed Prey on my %@. It's like a bulletproof vest against thieves.",
                            @"Just installed Prey on my %@. It's like a killer katana against thieves.",
                            @"Just installed Prey on my %@. It's like a 7 feet bodyguard against thieves.",
                            @"Just installed Prey on my %@. It's like a tank war against thieves.",
                            @"Just installed Prey on my %@. It's like pepper spray against thieves."];

    textsToShareArrayES = @[@"Acabo de instalar Prey en mi %@, ahora el detective soy yo.",
                            @"Acabo de instalar Prey en mi %@ y el robo dejó de ser una preocupación para mí.",
                            @"Acabo de instalar Prey en mi %@ y ya no le temo a los ladrones.",
                            @"Acabo de instalar Prey en mi %@. En caso de robo, ya tengo una carta bajo la manga.",
                            @"Acabo de instalar Prey en mi %@. Ahora puedo monitorear mi teléfono en caso de robo o pérdida."];
}

- (BOOL)isSocialFrameworkAvailable
{
    return ([SLComposeViewController class]) ? YES : NO;
}

- (void)postToSocialFramework:(NSString *)socialNetwork
{
    BOOL isAvailable = [SLComposeViewController isAvailableForServiceType:socialNetwork];
    SLComposeViewController *composeVC = [SLComposeViewController composeViewControllerForServiceType:socialNetwork];
    
    if ( (isAvailable) && (composeVC) )
    {        
        SLComposeViewControllerCompletionHandler myBlock = ^(SLComposeViewControllerResult result)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (result == SLComposeViewControllerResultCancelled)
                    NSLog(@"Cancelled");
                else
                    [self displayErrorAlert:NSLocalizedString(@"Thanks, you have made the world a better and safer place.", nil)
                                      title:NSLocalizedString(@"Message", nil)];
                
                [self dismissViewControllerAnimated:NO completion:Nil];
                [MBProgressHUD hideHUDForView:self.view animated:NO];
            });
        };
        
        composeVC.completionHandler = myBlock;
        
        int rnd = 1 + arc4random() % 5;
        NSString *textToShare;
        NSString *urlString;
        NSString *socialMedia   = ([socialNetwork isEqualToString:SLServiceTypeFacebook]) ? @"facebook" : @"twitter";
        NSString *language      = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
        
        if ([language isEqualToString:@"es"])
        {
            textToShare = [NSString stringWithFormat:textsToShareArrayES[rnd-1],[UIDevice currentDevice].model];
            urlString   = [NSString stringWithFormat:@"https://preyproject.com/?utm_source=iOS-social-share&utm_medium=%@&utm_campaign=es-message%d",socialMedia,rnd];
        }
        else
        {
            textToShare = [NSString stringWithFormat:textsToShareArrayEN[rnd-1],[UIDevice currentDevice].model];
            urlString   = [NSString stringWithFormat:@"https://preyproject.com/?utm_source=iOS-social-share&utm_medium=%@&utm_campaign=en-message%d",socialMedia,rnd];
        }
        
        
        [composeVC setInitialText:textToShare];
        [composeVC addURL:[NSURL URLWithString:urlString]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            HUD.label.text = NSLocalizedString(@"Please wait",nil);
            
            [self presentViewController:composeVC animated:YES completion:^{[self dismissHUDview:socialNetwork];}];
        });
    }
    else
        [self displayErrorAlert:NSLocalizedString(@"Is not available",nil) title:NSLocalizedString(@"Access Denied",nil)];
}

- (void)dismissHUDview:(NSString*)socialNetwork
{
    static int fbLoad = 0;
    static int twLoad = 0;
    int delay = 5;
    
    if ([socialNetwork isEqualToString:SLServiceTypeFacebook])
    {
        fbLoad++;
        delay = (fbLoad > 3) ? 0 : 5;
    }
    else
    {
        twLoad++;
        delay = (twLoad > 3) ? 0 : 5;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:NO];
    });
}

- (void)displayErrorAlert: (NSString *)alertMessage title:(NSString*)titleMessage
{
    UIAlertView * anAlert = [[UIAlertView alloc] initWithTitle:titleMessage message: alertMessage delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
    
    [anAlert show];
    
    NSIndexPath *indexPath = [tableViewInfo indexPathForSelectedRow];
    [tableViewInfo deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark WebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView{
   NSLog(@"Start Load Web");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    NSLog(@"Finish Load Web");
    [MBProgressHUD hideHUDForView:webView animated:NO];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    NSLog(@"Error Loading Web: %@",[error description]);
    [MBProgressHUD hideHUDForView:webView animated:NO];

    UIAlertView *alerta = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"We have a situation!",nil)
                                                     message:NSLocalizedString(@"Error loading web, please try again.",nil)
                                                    delegate:nil
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
    [alerta show];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end