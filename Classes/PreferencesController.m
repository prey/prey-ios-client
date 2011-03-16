//
//  PreferencesController.m
//  Prey
//
//  Created by Carlos Yaconi on 29/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "PreferencesController.h"
#import "PreyRunner.h"
#import "PreyAppDelegate.h"
#import "PreyConfig.h"
#import "PreyRestHttp.h"
#import "WelcomeController.h"


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
			return 1;
			break;
		case 1:
			return 4;
			break;
		case 2:
			return 1;
			break;

		default:
			return 4;
			break;
	}

}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	NSString *label = [[[NSString alloc] init] autorelease];

    switch (section) {
		case 0:
			label = NSLocalizedString(@"Execution control",nil);
			break;
		case 1:
			label = NSLocalizedString(@"Beta options",nil);
			break;
		case 2:
			label = NSLocalizedString(@"About",nil);
			break;

		default:
			break;
	}	
    return label;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    PreyConfig *config = [PreyConfig instance];
    switch ([indexPath section]) {
		case 0:
			if ([indexPath row] == 0){
				cell.textLabel.text = @"Missing";
				missing = [[UISwitch alloc]init];
				[missing addTarget: self action: @selector(changeMissingState:) forControlEvents:UIControlEventValueChanged];
				[missing setOn:config.missing];
				cell.accessoryView = missing;
			}
			break;
		case 1:
			if ([indexPath row] == 0){
				cell.textLabel.text = @"Location accuracy";
				cell.detailTextLabel.text = [accManager currentlySelectedName];
			}
			else if ([indexPath row] == 1) {
				cell.textLabel.text = @"Delay";
				cell.detailTextLabel.text = [delayManager currentDelay];
			} else if ([indexPath row] == 2) {
				cell.textLabel.text = @"Alert on report sent";
				UISwitch *alert = [[UISwitch alloc]init];
				[alert addTarget:self action: @selector(changeReportState:) forControlEvents:UIControlEventValueChanged];
				[alert setOn:config.alertOnReport];
				cell.accessoryView = alert;
			} else if ([indexPath row] == 3) {
				cell.textLabel.text = @"Detach device";
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			}
			break;
		case 2:
			cell.detailTextLabel.text = @"0.5.3";
			cell.textLabel.text = @"Current Prey version";
			break;

		default:
		if ([indexPath row] == 0) {
			cell.textLabel.text = @"Alert screen preview";
		} else if ([indexPath row] == 1) {
			cell.textLabel.text = @"Detach phone";
		} else if ([indexPath row] == 2) {
			cell.textLabel.text = @"Change password";
		} 
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
			if ([indexPath row] == 0){
				
			}
			break;
		case 1:
			if ([indexPath row] == 0){
				if (!pickerShowed){
					[accManager showPickerOnView:self.view fromTableView:self.tableView];
					[self setupNavigatorForPicker:YES withSelector:@selector(accuracyPickerSelected)];
				}
			} 
			else if ([indexPath row] == 1){
				if (!pickerShowed) {
					[delayManager showDelayPickerOnView:self.view fromTableView:self.tableView];
					[self setupNavigatorForPicker:YES withSelector:@selector(delayPickerSelected)];
				}
			} else if ([indexPath row] == 3){
				UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You're about to delete this device from the Control Panel.\n Are you sure?",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Sure, go ahead!",nil) destructiveButtonTitle:@"Cancel" otherButtonTitles:nil];
				actionSheet.tag = kDetachAction;
				[actionSheet showInView:self.view];
				[actionSheet release];
			}
			break;
		case 2:
			break;
	
		default:
			if ([indexPath row] == 0)
				[self showAlert];
			else if ([indexPath row] == 1){
				[[PreyConfig  instance] detachDevice];
                [[LocationController instance] stopUpdatingLocation];
                [[LocationController instance] stopMonitoringSignificantLocationChanges];
            }
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
	[accManager hidePickerOnView:self.view fromTableView:self.tableView];
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
		label = NSLocalizedString(@"You're attempting to mark this device as missing, and start sending reports to Control Panel.\n\nAre you sure?",nil);
		button = NSLocalizedString(@"Set as missing",nil); 
	}
	else {
		label = NSLocalizedString(@"Prey will stop sending reports to Control Panel and your device will be mark as recovered.\n\nAre you sure?",nil);
		button = NSLocalizedString(@"Set as recovered",nil); 
	}
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:label
															 delegate:self 
													cancelButtonTitle:button
													destructiveButtonTitle:@"Cancel" otherButtonTitles:nil];
	[actionSheet setTag:2];
    [actionSheet showInView:self.view];
	[actionSheet release];
	
	 
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

	if (actionSheet.tag == 1){
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];

		if (buttonIndex == 1){
            //Dettaching device...
            HUD = [[MBProgressHUD alloc] initWithView:self.view];
            HUD.delegate = self;
            HUD.labelText = NSLocalizedString(@"Removing device...",nil);
            [self.navigationController.view addSubview:HUD];
            [HUD showWhileExecuting:@selector(detachDevice) onTarget:self withObject:nil animated:YES];
        }
	}
	else if (actionSheet.tag == 2)
		if (missing.on)
			if (buttonIndex == 1){
                HUD = [[MBProgressHUD alloc] initWithView:self.view];
                HUD.delegate = self;
                HUD.labelText = NSLocalizedString(@"Starting Prey...",nil);
                [self.navigationController.view addSubview:HUD];
                [HUD showWhileExecuting:@selector(startPrey) onTarget:self withObject:nil animated:YES];
            }
			else
				[missing setOn:NO animated:YES];
		else
			if (buttonIndex == 1){
				HUD = [[MBProgressHUD alloc] initWithView:self.view];
                HUD.delegate = self;
                HUD.labelText = NSLocalizedString(@"Stopping Prey...",nil);
                [self.navigationController.view addSubview:HUD];
                [HUD showWhileExecuting:@selector(stopPrey) onTarget:self withObject:nil animated:YES];
            }
			else
				[missing setOn:YES animated:YES];

}

- (void) detachDevice {
    [[PreyConfig instance] detachDevice];
    WelcomeController *welcomeController = [[WelcomeController alloc] initWithNibName:@"WelcomeController" bundle:nil];
    [[self navigationController] pushViewController:welcomeController animated:YES];
    [welcomeController release];

}


- (IBAction)changeReportState:(UISwitch*)missingSwitch{
	[PreyConfig instance].alertOnReport = missingSwitch.on;	
}

#pragma mark -
#pragma mark Events received
- (void)missingStateUpdated:(NSNotification *)notification
{
	//LogMessage(@"Prey Location Controller", 0, @"Missing state has been updated from the control panel. Setting the missing switch");

	[self performSelectorOnMainThread:@selector(changeMissingSwitch:) withObject:[notification object] waitUntilDone:NO];
	
	
}
- (void)changeMissingSwitch:(id)config {
	BOOL isMissing = ((PreyConfig*)config).missing;
	[missing setOn:isMissing animated:YES];
	if (isMissing)
	 	[[PreyRunner instance]startPreyService];
}

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
	accManager = [[AccuracyManager alloc] init];
	delayManager = [[DelayManager alloc] init];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(missingStateUpdated:) name:@"missingUpdated" object:nil];
    [super viewDidLoad];
}


/*
 - (void)viewWillAppear:(BOOL)animated {
 [super viewWillAppear:animated];
 }
 */
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
/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
	[accManager release];
	[delayManager release];
    [super dealloc];
}


@end

