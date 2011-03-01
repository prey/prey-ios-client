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
#import "LocationController.h"
#import "PreyRestHttp.h"


@interface PreferencesController()

-(void) goPrey;
-(void) showAlert;

@end

@implementation PreferencesController

@synthesize cLoadingView;

#pragma mark -
#pragma mark Private Methods
-(void) goPrey{
	[NSThread detachNewThreadSelector: @selector(spinBegin) toTarget:self withObject:nil];
	[[PreyRunner instance] startPreyService];
	[NSThread detachNewThreadSelector: @selector(spinEnd) toTarget:self withObject:nil];
}

-(void) stopPrey{
	[[PreyRunner instance] stopPreyService];
}

-(void) startOnIntervalChecking {
	[[PreyRunner instance] startOnIntervalChecking];
}

-(void) stopOnIntervalChecking {
	[[PreyRunner instance] stopOnIntervalChecking];
}


- (void)showAlert{
	PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate showAlert:@"This is a stolen computer, and is being tracked by Prey. Please contact the owner at (INSERT_MAIL_HERE) to resolve the situation."];
}


#pragma mark -
#pragma mark Spinner Methods

- (void)initSpinner {
	cLoadingView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];    
	// we put our spinning "thing" right in the center of the current view
	CGPoint newCenter = (CGPoint) [self.view center];
	cLoadingView.center = newCenter;	
	[self.view addSubview:cLoadingView];	
}

- (void)spinBegin {
	[cLoadingView startAnimating];
}


- (void)spinEnd {
	[cLoadingView stopAnimating];
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
			return 2;
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
				if (config.missing)
					[missing setOn:YES];
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
				[accManager showPickerOnView:self.view fromTableView:self.tableView];
				[self setupNavigatorForPicker:YES withSelector:@selector(accuracyPickerSelected)];
			} 
			else if ([indexPath row] == 1){
				[delayManager showDelayPickerOnView:self.view fromTableView:self.tableView];
				[self setupNavigatorForPicker:YES withSelector:@selector(delayPickerSelected)];
			}
			break;
		case 2:
			break;
	
		default:
			if ([indexPath row] == 0)
				[self showAlert];
			else if ([indexPath row] == 1)
				[[PreyConfig  instance] detachDevice];
			break;
	}
}

- (void) setupNavigatorForPicker:(BOOL)showed withSelector:(SEL)action {
	if (showed){
		[self.navigationController setNavigationBarHidden:NO animated:YES];
		UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
																	   style:UIBarButtonItemStyleDone
																	  target:self	action:action];
		self.navigationItem.rightBarButtonItem = doneButton;
	} else {
		// remove the "Done" button in the nav bar
		self.navigationItem.rightBarButtonItem = nil;
		
		// deselect the current table row
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
		
		//hide the nav bar again
		[self.navigationController setNavigationBarHidden:YES animated:YES];
		[self.tableView reloadData];
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
#pragma mark Missing Switch methods
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
	[actionSheet showInView:self.view];
	[actionSheet release];
	[label release];
	[button release];
	 
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	PreyRunner *runner = [PreyRunner instance];
	if (missing.on)
		if (buttonIndex == 1)
			[runner startPreyService];
		else
			[missing setOn:NO animated:YES];
	else
		if (buttonIndex == 1)
			[runner stopPreyService];
		else
			[missing setOn:YES animated:YES];

}

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
	[self initSpinner];
	accManager = [[AccuracyManager alloc] init];
	delayManager = [[DelayManager alloc] init];
    [super viewDidLoad];
	
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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

