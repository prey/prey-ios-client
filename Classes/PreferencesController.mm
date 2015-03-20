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
#import "WelcomeController.h"
#import "DeviceMapController.h"
#import "AppStoreViewController.h"
#import "Constants.h"
#import <Social/Social.h>
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#import "Constants.h"
#import "CamouflageModule.h"

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

@synthesize tableViewInfo;


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    int numberRow = 1;
	switch (section)
    {
        case 0:
            if (![[PreyConfig instance] isPro])
                numberRow++;
            
            if ([self isSocialFrameworkAvailable])
                numberRow+=2;
            
            return numberRow;
            break;
		case 1:
			return 2;
			break;
		case 2:
			return 4;
			break;
        default:
            return 1;
			break;
	}
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
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

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (IS_OS_7_OR_LATER)
        return nil;
    else
        return -1;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
            return NSLocalizedString(@"Information",nil);;
            break;
        case 1:
			return NSLocalizedString(@"Settings",nil);
			break;
		case 2:
			return NSLocalizedString(@"About",nil);
			break;
	}
	return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    if (IS_IPAD)
        [header.textLabel  setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:17]];
    else
        [header.textLabel  setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:12]];
    
    [header.textLabel  setTextColor:[UIColor colorWithRed:(72/255.f) green:(84/255.f) blue:(102/255.f) alpha:.3]];
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
            [cell.textLabel  setFont:[UIFont fontWithName:@"OpenSans" size:20]];
            [cell.detailTextLabel setFont:[UIFont fontWithName:@"OpenSans" size:20]];
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
        case 0:
            if ([indexPath row] == 0) {
                cell.textLabel.text = NSLocalizedString(@"Current Location",nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            else if ([indexPath row] == 1) {
                cell.textLabel.text = NSLocalizedString(@"Share on Facebook",nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            else if ([indexPath row] == 2) {
                cell.textLabel.text = NSLocalizedString(@"Share on Twitter",nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            else if ([indexPath row] == 3) {
                cell.textLabel.text = NSLocalizedString(@"Upgrade to Pro",nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            break;
		case 1:
            
            if ([indexPath row] == 0) {
                UISwitch *camouflageMode = [[UISwitch alloc]init];
                cell.textLabel.text = NSLocalizedString(@"Camouflage mode",nil);
                [camouflageMode addTarget: self action: @selector(camouflageModeState:) forControlEvents:UIControlEventValueChanged];
                [camouflageMode setOn:config.camouflageMode];
                cell.accessoryView = camouflageMode;
            }
            else if ([indexPath row] == 1) {
				cell.textLabel.text = NSLocalizedString(@"Detach device",nil);
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                cell.accessoryView = nil;
            }
			break;
		case 2:
            cell.detailTextLabel.text = @"";
            if (cell.accessoryView) {
                [cell.accessoryView removeFromSuperview];
            }
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryView = nil;
			if (indexPath.row == 0) {
                cell.detailTextLabel.text = [Constants appVersion];
                cell.textLabel.text = NSLocalizedString(@"Version",nil);
            } else if (indexPath.row == 2) {
                cell.textLabel.text = NSLocalizedString(@"Terms of Service", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } else if (indexPath.row == 3) {
                cell.textLabel.text = NSLocalizedString(@"Privacy Policy", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } else if (indexPath.row == 1) {
                cell.textLabel.text = NSLocalizedString(@"Help", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
			break;
        default:
            break;
	}
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	switch ([indexPath section]) {
        case 0:
            if ([indexPath row] == 0)
            {
                DeviceMapController *deviceMapController = [[DeviceMapController alloc] init];
                [self.navigationController pushViewController:deviceMapController animated:YES];
            }
            else if ([indexPath row] == 1) {
                [self postToSocialFramework:SLServiceTypeFacebook];
            }
            else if ([indexPath row] == 2) {
                [self postToSocialFramework:SLServiceTypeTwitter];
            }
            else if ([indexPath row] == 3)
            {
                AppStoreViewController *viewController;
               
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
                {
                    if (IS_IPHONE5)
                        viewController = [[AppStoreViewController alloc] initWithNibName:@"AppStoreViewController-iPhone-568h" bundle:nil];
                    else
                        viewController = [[AppStoreViewController alloc] initWithNibName:@"AppStoreViewController-iPhone" bundle:nil];
                }
                else
                    viewController = [[AppStoreViewController alloc] initWithNibName:@"AppStoreViewController-iPad" bundle:nil];

                
                [self.navigationController pushViewController:viewController animated:YES];
            }
            break;
		case 1:
            if ([indexPath row] == 1){
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
			break;
		case 2:
            if (indexPath.row != 0) {
                
                PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
                HUD = [MBProgressHUD showHUDAddedTo:appDelegate.viewController.view animated:YES];
                HUD.labelText = NSLocalizedString(@"Please wait",nil);
                
                UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
                UIViewController *moo = [[UIViewController alloc] init];
                moo.view = webView;
                NSURLRequest *req = nil;
                if (indexPath.row == 2) {
                    req = [NSURLRequest requestWithURL:[NSURL URLWithString:URL_TERMS_PREY]];
                    moo.title = NSLocalizedString(@"Terms of Service", nil);
                } else if (indexPath.row == 3) {
                    req = [NSURLRequest requestWithURL:[NSURL URLWithString:URL_PRIVACY_PREY]];
                    moo.title = NSLocalizedString(@"Privacy Policy", nil);
                } else if (indexPath.row == 1) {
                    req = [NSURLRequest requestWithURL:[NSURL URLWithString:URL_HELP_PREY]];
                    moo.title = NSLocalizedString(@"Help", nil);
                }
                [webView setDelegate:self];
                [webView loadRequest:req];
                [webView setScalesPageToFit:YES];
                [self.navigationController pushViewController:moo animated:YES];
            }
			break;
            
		default:
			break;
	}
}

#pragma mark -
#pragma mark Switches methods

- (IBAction)camouflageModeState:(UISwitch*)camouflageModeSwitch{
    [[PreyConfig instance] setCamouflageMode:camouflageModeSwitch.on];
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

- (void) detachDevice
{
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    HUD = [MBProgressHUD showHUDAddedTo:appDelegate.viewController.view animated:YES];
    HUD.labelText = NSLocalizedString(@"Detaching device ...",nil);

    
    [PreyRestHttp deleteDevice:5 withBlock:^(NSHTTPURLResponse *response, NSError *error)
     {
         PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
         [MBProgressHUD hideHUDForView:appDelegate.viewController.view animated:NO];
         
         if (!error)
         {
             [[PreyConfig instance] resetValues];
             
             UIViewController *welco;
             
             if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
             {
                 if (IS_IPHONE5)
                     welco = [[WelcomeController alloc] initWithNibName:@"WelcomeController-iPhone-568h" bundle:nil];
                 else
                     welco = [[WelcomeController alloc] initWithNibName:@"WelcomeController-iPhone" bundle:nil];
             }
             else
                 welco = [[WelcomeController alloc] initWithNibName:@"WelcomeController-iPad" bundle:nil];
                          

             PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
             [appDelegate.viewController setNavigationBarHidden:YES animated:NO];
             [appDelegate.viewController setViewControllers:[NSArray arrayWithObject:welco] animated:NO];
         }
     }];
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
    
    self.title = NSLocalizedString(@"Preferences", nil);
    self.view.backgroundColor = [UIColor whiteColor];
    
    // TableView Config
    CGRect frameTable;
    if (IS_IPAD)
        frameTable = CGRectMake(149, 100, 470, 870);
    else
        frameTable = self.view.frame;
    
    tableViewInfo = [[UITableView alloc] initWithFrame:frameTable style:UITableViewStyleGrouped];
    [tableViewInfo setBackgroundView:nil];
    [tableViewInfo setBackgroundColor:[UIColor whiteColor]];
    [tableViewInfo setSeparatorColor:[UIColor colorWithRed:(240/255.f) green:(243/255.f) blue:(247/255.f) alpha:1]];
    tableViewInfo.rowHeight  = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? 44 : 72.5;
    tableViewInfo.delegate   = self;
    tableViewInfo.dataSource = self;
    if (IS_IPAD) tableViewInfo.scrollEnabled = NO;
    [self.view addSubview:tableViewInfo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData:) name:@"proUpdated" object:nil];
    
    [tableViewInfo reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController setToolbarHidden:YES animated:NO];
    
    
    currentCamouflageMode = [PreyConfig instance].camouflageMode;
    
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

#pragma mark -
#pragma mark Social Framework

- (BOOL)isSocialFrameworkAvailable
{
    if([SLComposeViewController class])
        return YES;
    else
        return NO;
}

- (void)postToSocialFramework:(NSString *)socialNetwork
{
    BOOL isAvailable = [SLComposeViewController isAvailableForServiceType:socialNetwork];
    if(isAvailable)
    {
        SLComposeViewController * composeVC = [SLComposeViewController composeViewControllerForServiceType:socialNetwork];
        if(composeVC)
        {
            SLComposeViewControllerCompletionHandler myBlock = ^(SLComposeViewControllerResult result)
            {
                if (result == SLComposeViewControllerResultCancelled)
                    NSLog(@"Cancelled");
                else
                    [self displayErrorAlert:@"Thanks, you have made the world a better and safer place." title:@"Message"];
                
                [composeVC dismissViewControllerAnimated:YES completion:Nil];
            };
            
            composeVC.completionHandler =myBlock;
            [composeVC setInitialText:[NSString stringWithFormat:@"I just protected my %@ from loss and theft with Prey. You can also protect yours for free.", [UIDevice currentDevice].model]];
            [composeVC addURL:[NSURL URLWithString:@"http://preyproject.com/download?utm_source=iOS"]];
            
            [self presentViewController: composeVC animated: YES completion: nil];
        }
    }
    else
        [self displayErrorAlert:NSLocalizedString(@"Is not available",nil) title:NSLocalizedString(@"Access Denied",nil)];
}

- (void)displayErrorAlert: (NSString *)alertMessage title:(NSString*)titleMessage
{
    UIAlertView * anAlert = [[UIAlertView alloc] initWithTitle:titleMessage message: alertMessage delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
    
    [anAlert show];
}


#pragma mark WebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView{
   NSLog(@"Start Load Web");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    NSLog(@"Finish Load Web");
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    [MBProgressHUD hideHUDForView:appDelegate.viewController.view animated:NO];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    NSLog(@"Error Loading Web: %@",[error description]);
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    [MBProgressHUD hideHUDForView:appDelegate.viewController.view animated:NO];

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