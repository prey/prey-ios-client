//
//  CongratulationsController.m
//  Prey
//
//  Created by Carlos Yaconi on 04/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "CongratulationsController.h"
#import "PreyAppDelegate.h"
#import "PreferencesController.h"


@implementation CongratulationsController

@synthesize congratsTitle, congratsMsg, ok;

#pragma mark -
#pragma mark IBActions
- (IBAction) okPressed: (id) sender{
	
	PreferencesController *preferencesController = [[PreferencesController alloc] initWithNibName:@"PreferencesController" bundle:nil];
//	[self.navigationController popToRootViewControllerAnimated:YES];
	[self.navigationController setNavigationBarHidden:YES animated:YES];
	
	[self.navigationController pushViewController:preferencesController animated:YES];
	[preferencesController release];
	
	/*
	PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
	[self.navigationController dismissModalViewControllerAnimated:YES];
	[appDelegate showPreferences];
	*/
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	/*
    self.title = @"Congratulations";
    self.congratsTitle.text = NSLocalizedString(@"Congratulations!",nil);
	self.congratsMsg.text = NSLocalizedString(@"You have successfully associated this phone with your Prey account. Now take a minute to set it up.",nil);
     */
	[self.ok setTitle:NSLocalizedString(@"OK",nil) forState:UIControlStateNormal];
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[congratsMsg release];
	[congratsTitle release];
	[ok release];
	[super dealloc];
}


@end
