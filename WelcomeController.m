//
//  WelcomeController.m
//  Prey
//
//  Created by Carlos Yaconi on 04/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "WelcomeController.h"
#import "PreyAppDelegate.h"

@implementation WelcomeController

@synthesize welcomeText,welcomeTitle,yes,no;

#pragma mark -
#pragma mark IBActions

- (IBAction) notRegistered: (id) sender{
	PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate showNewUserWizard];

}

- (IBAction) alreadyRegistered: (id) sender{
	PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate showOldUserWizard];
	/*
	OldUserController *ouController = [[OldUserController alloc] initWithNibName:@"OldUserController" bundle:nil];
	ouController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:ouController animated:YES];
	
	[ouController release];
	 */
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    self.welcomeTitle.text = NSLocalizedString(@"Welcome to Prey!",nil);
	self.welcomeText.text = NSLocalizedString(@"Prey helps you find your phone by reporting its location to a web control panel, activated by a SMS message of your choice.\n\nHave you already registered on preyproject.com?!",nil);
	[self.yes setTitle:NSLocalizedString(@"Yes",nil) forState:UIControlStateNormal];
	[self.no setTitle:NSLocalizedString(@"No",nil) forState:UIControlStateNormal];
	[super viewDidLoad];
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
    [super dealloc];
	[welcomeText release];
	[welcomeTitle release];
	[yes release];
	[no release];
}


@end
