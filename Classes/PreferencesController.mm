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
#import "PreyRunner.h"
#import "PreyAppDelegate.h"
#import "PreyConfig.h"
#import "PreyRestHttp.h"
#import "WelcomeController.h"
#import "LogController.h"
#import "DeviceMapController.h"
#import "IAPHelper.h"
#import "StoreControllerViewController.h"
#import "SignificantLocationController.h"

#import "ReviewRequest.h"

@interface PreferencesController()

-(void) showAlert;
-(void) startPrey;
-(void) stopPrey;

@end

@implementation PreferencesController


#pragma mark -
#pragma mark Private Methods


- (void)showAlert{
	PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate showAlert:@"This is a stolen computer, and is being tracked by Prey. Please contact the owner at (INSERT_MAIL_HERE) to resolve the situation."];
}

-(void) startPrey {
    [[PreyRunner instance] startPreyService];
}

-(void) stopPrey {
    [[PreyRunner instance] stopPreyService];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden {
    // Remove HUD from screen when the HUD was hidded
    [HUD removeFromSuperview];
    [HUD release];
	HUD = nil;
}




#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	switch (section) {
        case 0:
            if ([[PreyConfig instance] isPro])
                return 1;
            if ([[[IAPHelper sharedHelper] products] count] == 0) {
                return 1;
            }
            return 2;
            break;
		case 1:
			return 3;
			break;
		case 2:
			return 4;
			break;
        default:
            return 1;
			break;
	}

}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
    switch (section) {
        case 1:
			return NSLocalizedString(@"Settings",nil);
			break;
		case 2:
			return NSLocalizedString(@"About",nil);
			break;
	}
	return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    }
    PreyConfig *config = [PreyConfig instance];
    switch ([indexPath section]) {
        case 0:
            if ([indexPath row] == 0) {
                cell.textLabel.text = NSLocalizedString(@"Current Location",nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } else if ([indexPath row] == 1) {
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
                 [camouflageMode release];                 
             }
             else if ([indexPath row] == 1) {
                 intervalCheckin = [[UISwitch alloc]init];
                 cell.textLabel.text = NSLocalizedString(@"Use Location Listener",nil);
                 [intervalCheckin addTarget: self action: @selector(intervalModeState:) forControlEvents:UIControlEventValueChanged];
                 [intervalCheckin setOn:config.intervalMode];
                 cell.accessoryView = intervalCheckin;
                 
             } else if ([indexPath row] == 2) {
				cell.textLabel.text = NSLocalizedString(@"Detach device",nil);
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
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
	//LogMessageCompat(@"Table cell press. Section: %i, Row: %i",[indexPath section],[indexPath row]);
	switch ([indexPath section]) {
        case 0:
            if ([indexPath row] == 0) {
                [self.navigationController pushViewController:[[DeviceMapController alloc] init] animated:YES];
            } else if ([indexPath row] == 1) {
                [self.navigationController pushViewController:[[StoreControllerViewController alloc] init] animated:YES];
            }
		case 1:
            if ([indexPath row] == 2){
				UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You're about to delete this device from the Control Panel.\n Are you sure?",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"No, don't delete",nil) destructiveButtonTitle:NSLocalizedString(@"Yes, remove from my account",nil) otherButtonTitles:nil];
				actionSheet.tag = kDetachAction;
				[actionSheet showInView:self.view];
				[actionSheet release];
			} 
            /*
            else if ([indexPath row] == 4){
				LogController *logController = [[LogController alloc] init];
                [self.navigationController setNavigationBarHidden:NO animated:NO];
                [self.navigationController pushViewController:logController animated:YES];
                [logController release];
			}
            */
			break;
		case 2:
            if (indexPath.row != 0) {
                UIWebView *webView = [[[UIWebView alloc] initWithFrame:CGRectZero] autorelease];
                UIViewController *moo = [[[UIViewController alloc] init] autorelease];
                moo.view = webView;
                NSURLRequest *req;
                if (indexPath.row == 2) {
                    req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.preyproject.com/terms"]];
                    moo.title = NSLocalizedString(@"Terms of Service", nil);
                } else if (indexPath.row == 3) {
                    req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.preyproject.com/privacy"]];
                    moo.title = NSLocalizedString(@"Privacy Policy", nil);
                } else if (indexPath.row == 1) {
                    req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://support.preyproject.com/"]];
                    moo.title = NSLocalizedString(@"Help", nil);
                }
                [webView loadRequest:req];
                [webView setScalesPageToFit:YES];
                [self.navigationController pushViewController:moo animated:YES];
            }
			break;
	
		default:
			break;
	}
}

- (void) setupNavigatorForPicker:(BOOL)showed withSelector:(SEL)action {
	if (showed){
		[self.navigationController setNavigationBarHidden:NO animated:YES];
        self.navigationItem.hidesBackButton=YES;
		UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self	action:action];
		self.navigationItem.rightBarButtonItem = doneButton;
		pickerShowed = YES;
	} else {
		// remove the "Done" button in the nav bar
		self.navigationItem.rightBarButtonItem = nil;
		
		// deselect the current table row
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
		
		//hide the nav bar again
		[self.navigationController setNavigationBarHidden:YES animated:YES];
        self.navigationItem.hidesBackButton=NO;
		[self.tableView reloadData];
		pickerShowed = NO;
	}
}

- (void)accuracyPickerSelected 
{
	[self setupNavigatorForPicker:NO withSelector:nil];

}

- (void)delayPickerSelected
{
	[delayManager hideDelayPickerOnView:self.view fromTableView:self.tableView];
	[self setupNavigatorForPicker:NO withSelector:nil];
	
}

#pragma mark -
#pragma mark Switches methods
- (IBAction)changeMissingState:(UISwitch*)missingSwitch{
	//LogMessageCompat(@"Switch status on? %@", missingSwitch.on == YES? @"YES" : @"NO");
	
	NSString *label = nil;
	NSString *button = nil;
	if (missingSwitch.on){
		label = NSLocalizedString(@"You're attempting to mark this device as missing, and start sending reports to the Control Panel.\n\nAre you sure?",nil);
		button = NSLocalizedString(@"Mark as missing",nil); 
	}
	else {
		label = NSLocalizedString(@"Prey will stop sending reports to the Control Panel and your device will be mark as recovered.\n\nAre you sure?",nil);
		button = NSLocalizedString(@"Mark as recovered",nil); 
	}
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:label
															 delegate:self 
													cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
													destructiveButtonTitle:button otherButtonTitles:nil];
	[actionSheet setTag:2];
    [actionSheet showInView:self.view];
	[actionSheet release];
	
	 
}

- (IBAction)changeAskForPasswordState:(UISwitch*)askForPassSwitch{
	//LogMessageCompat(@"Switch status on? %@", missingSwitch.on == YES? @"YES" : @"NO");
        [[PreyConfig instance] setAskForPassword:askForPassSwitch.on];
}


- (IBAction)camouflageModeState:(UISwitch*)camouflageModeSwitch{
	//LogMessageCompat(@"Switch status on? %@", missingSwitch.on == YES? @"YES" : @"NO");
    [[PreyConfig instance] setCamouflageMode:camouflageModeSwitch.on];
}

- (IBAction)intervalModeState:(UISwitch*)intervalModeSwitch{
    NSString *label = nil;
	NSString *button = nil;
	if (intervalModeSwitch.on){
		label = NSLocalizedString(@"By enabling this, the arrow location icon will be shown beside the battery status at the top. This doesn't mean the GPS is on, but it may use a bit of your phone's battery",nil);
		button = NSLocalizedString(@"Enable it!",nil);
	}
	else {
		label = NSLocalizedString(@"By disabling this, Prey won't be able to check its missing status, and the only way to start sending reports will be activating Prey from the Web Control Panel",nil);
		button = NSLocalizedString(@"Disable it!",nil);
	}
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:label
															 delegate:self
													cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                               destructiveButtonTitle:button otherButtonTitles:nil];
	[actionSheet setTag:3];
    [actionSheet showInView:self.view];
	[actionSheet release];
    
    
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

	if (actionSheet.tag == 1){
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];

		if (buttonIndex == 0){
            //Dettaching device...
            HUD = [[MBProgressHUD alloc] initWithView:self.view];
            HUD.delegate = self;
            HUD.labelText = NSLocalizedString(@"Removing device...",nil);
            [self.navigationController.view addSubview:HUD];
            [HUD showWhileExecuting:@selector(detachDevice) onTarget:self withObject:nil animated:YES];
        }
	}
	else if (actionSheet.tag == 2){
		if (missing.on)
			if (buttonIndex == 0){
                HUD = [[MBProgressHUD alloc] initWithView:self.view];
                HUD.delegate = self;
                HUD.labelText = NSLocalizedString(@"Starting Prey...",nil);
                [self.navigationController.view addSubview:HUD];
                [HUD showWhileExecuting:@selector(startPrey) onTarget:self withObject:nil animated:YES];
            }
			else
				[missing setOn:NO animated:YES];
		else
			if (buttonIndex == 0){
				HUD = [[MBProgressHUD alloc] initWithView:self.view];
                HUD.delegate = self;
                HUD.labelText = NSLocalizedString(@"Stopping Prey...",nil);
                [self.navigationController.view addSubview:HUD];
                [HUD showWhileExecuting:@selector(stopPrey) onTarget:self withObject:nil animated:YES];
            }
			else
				[missing setOn:YES animated:YES];
    } else  if (actionSheet.tag == 3){
        if (intervalCheckin.on)
			if (buttonIndex == 0){
                [[PreyConfig instance] setIntervalMode:intervalCheckin.on];
                [[SignificantLocationController instance] startMonitoringSignificantLocationChanges];
            }
			else
				[intervalCheckin setOn:NO animated:YES];
        else
            if (buttonIndex == 0){
                [[PreyConfig instance] setIntervalMode:intervalCheckin.on];
                [[SignificantLocationController instance] stopMonitoringSignificantLocationChanges];
            }
            else
                [intervalCheckin setOn:YES animated:YES];
        }
}

- (void) detachDevice {
    [self stopPrey];
    [[PreyConfig instance] detachDevice];
    [[PreyRunner instance] stopOnIntervalChecking];
    
    UIViewController *welco;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        welco = [[WelcomeController alloc] initWithNibName:@"WelcomeController-iPhone" bundle:nil];
    else
        welco = [[WelcomeController alloc] initWithNibName:@"WelcomeController-iPad" bundle:nil];
    
    UINavigationController *navco = [[UINavigationController alloc] initWithRootViewController:welco];
    
    [[self navigationController] presentModalViewController:navco animated:YES];
    
    [welco release];
    [navco release];
}


#pragma mark -
#pragma mark Events received
- (void)missingStateUpdated:(NSNotification *)notification
{
	//LogMessage(@"Prey Location Controller", 0, @"Missing state has been updated from the control panel. Setting the missing switch");
	[self performSelectorOnMainThread:@selector(changeMissingSwitch:) withObject:[notification object] waitUntilDone:NO];
}

- (void)reloadData:(NSNotification *)notification
{
	[[self tableView] reloadData];
}

- (void)changeMissingSwitch:(id)config {
	BOOL isMissing = ((PreyConfig*)config).missing;
	[missing setOn:isMissing animated:YES];
}

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad
{
    if (ReviewRequest::ShouldAskForReview())
		ReviewRequest::AskForReview();

    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:[[[UIView alloc] initWithFrame:CGRectZero] autorelease]]autorelease];
    HUD = nil;
    self.title = NSLocalizedString(@"Preferences", nil);
    [self.tableView setBackgroundColor:[UIColor whiteColor]];
    
	delayManager = [[DelayManager alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData:) name:kProductsLoadedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(missingStateUpdated:) name:@"missingUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData:) name:@"delayUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData:) name:@"accuracyUpdated" object:nil];
    [super viewDidLoad];
}



 - (void)viewWillAppear:(BOOL)animated {
     [super viewWillAppear:animated];
     [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
     [self.navigationController setNavigationBarHidden:NO animated:NO];
     [self.navigationController setToolbarHidden:YES animated:NO];
     [[UIApplication sharedApplication] setStatusBarHidden:NO];
 }

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

/*
 - (void)viewDidAppear:(BOOL)animated {
 [super viewDidAppear:animated];
 }
 */
/*
 - (void)viewWillDisappear:(BOOL)animated {
 [super viewWillDisappear:animated];
 }
 */
/*
 - (void)viewDidDisappear:(BOOL)animated {
 [super viewDidDisappear:animated];
 }
 */
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}
 

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}




- (void)dealloc {
    if (HUD != nil) {
        HUD.delegate = nil;
        [HUD removeFromSuperview];
        [HUD release];
    }
	[delayManager release];
    [super dealloc];
}


@end

