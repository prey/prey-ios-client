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

#pragma mark -
#pragma mark Private Methods
-(void) goPrey{
	[[PreyRunner instance] startPreyService];
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
#pragma mark View lifecycle


- (void)viewDidLoad {
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
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	switch (section) {
		case 0:
			return 2;
			break;
		case 1:
			return 2;
			break;
		default:
			return 4;
			break;
	}

}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    switch ([indexPath section]) {
		case 0:
			if ([indexPath row] == 0)
				cell.textLabel.text = @"GO Prey";
			else if ([indexPath row] == 1)
				cell.textLabel.text = @"STOP Prey";
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			break;
		case 1:
			if ([indexPath row] == 0)
				cell.textLabel.text = @"Start on-interval checking";
			else if ([indexPath row] == 1)
				cell.textLabel.text = @"Stop on-interval checking";
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			break;
		default:
		if ([indexPath row] == 0) {
			cell.textLabel.text = @"Alert screen preview";
		} else if ([indexPath row] == 1) {
			cell.textLabel.text = @"Detach phone";
		} else if ([indexPath row] == 2) {
			cell.textLabel.text = @"Change password";
		} else {
			cell.textLabel.text = @"About";
		}
			break;
	}
    
    return cell;
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
			break;
		case 1:
			if ([indexPath row] == 0)
				[self startOnIntervalChecking];
			else if ([indexPath row] == 1)
				[self stopOnIntervalChecking];
			break;
		default:
			if ([indexPath row] == 0)
				[self showAlert];
			else if ([indexPath row] == 1)
				[[PreyConfig  getInstance] detachDevice];
			break;
	}
}


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
    [super dealloc];
}


@end

