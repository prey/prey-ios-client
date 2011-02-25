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
			return 3;
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
			label = NSLocalizedString(@"Execution control 2",nil);
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
    
    switch ([indexPath section]) {
		case 0:
			if ([indexPath row] == 0){
				cell.textLabel.text = @"Missing";
				UISwitch *missing = [[UISwitch alloc]init];
				cell.accessoryView = missing;
			}
			else if ([indexPath row] == 1){
				cell.textLabel.text = @"Location accuracy";
				UISlider *accuracy = [[UISlider alloc]init];
				accuracy.minimumValue = 0;
				accuracy.maximumValue = 5;
				accuracy.continuous = NO;
				
				NSString* imageName = [[NSBundle mainBundle] pathForResource:@"location_worst" ofType:@"png"];
				UIImage* worst = [[UIImage alloc] initWithContentsOfFile:imageName];
				imageName = [[NSBundle mainBundle] pathForResource:@"location_best" ofType:@"png"];
				UIImage* best = [[UIImage alloc] initWithContentsOfFile:imageName];
				accuracy.minimumValueImage = worst;
				accuracy.maximumValueImage = best;
				
				[accuracy addTarget:self action:@selector(accuracyChanged:) forControlEvents:UIControlEventValueChanged];

				cell.accessoryView = accuracy;
			}
			else if ([indexPath row] == 2){
				cell.textLabel.text = @"Location accuracy";
							}
			break;
		case 1:
			if ([indexPath row] == 0)
				cell.textLabel.text = @"Start on-interval checking";
			else if ([indexPath row] == 1)
				cell.textLabel.text = @"Stop on-interval checking";
			cell.textLabel.textAlignment = UITextAlignmentCenter;
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
- (void)accuracyChanged:(UISlider*)sender
{
	float newValue = ceil([sender value]);
	[sender setValue:newValue];
	LogMessageCompat(@"sliderAction: value set = %.1f", newValue);
}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	//LogMessageCompat(@"Table cell press. Section: %i, Row: %i",[indexPath section],[indexPath row]);
	switch ([indexPath section]) {
		case 0:
			if ([indexPath row] == 0)
				[self goPrey];
			else if ([indexPath row] == 1)
				[self stopPrey];
			else {
				accPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 200, 320, 200)];
				accPicker.delegate = self;
				[accManager showPicker:accPicker onView:self.view fromTableView:self.tableView];
				[self.navigationController setNavigationBarHidden:NO animated:YES];
				UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
												style:UIBarButtonItemStyleDone
												target:self	action:@selector(accuracyPickerSelected:)];
				self.navigationItem.rightBarButtonItem = doneButton;
			}
			break;
		case 1:
			if ([indexPath row] == 0)
				[self startOnIntervalChecking];
			else if ([indexPath row] == 1)
				[self stopOnIntervalChecking];
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

#pragma mark -
#pragma mark Picker datasource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	return [accManager pickerCount];
}

#pragma mark -
#pragma mark Picker delegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return [accManager nameFor:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	[accManager setSelectedAccuracyRow:row];
}


- (void)accuracyPickerSelected:(UIBarButtonItem*)sender
{
	[accManager hidePicker:accPicker onView:self.view fromTableView:self.tableView];
	// remove the "Done" button in the nav bar
	self.navigationItem.rightBarButtonItem = nil;
	
	// deselect the current table row
	NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	//hide the nav bar again
	[self.navigationController setNavigationBarHidden:YES animated:YES];
}

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
	[self initSpinner];
	accManager = [[AccuracyManager alloc] init];
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
	[accPicker release];
    [super dealloc];
}


@end

