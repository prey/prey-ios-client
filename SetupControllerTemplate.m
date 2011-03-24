//
//  SetupControllerTemplate.m
//  Prey
//
//  Created by Carlos Yaconi on 13/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "SetupControllerTemplate.h"
#import "CongratulationsController.h"
#import "PreyAppDelegate.h"
#import "PreyRunner.h"

@interface SetupControllerTemplate () 

- (void) hideKeyboard;
- (void) showCongratsView;
- (void) animateTextField: (UITextField*) textField up: (BOOL) up;

@end

@implementation SetupControllerTemplate

#pragma mark -
#pragma mark Private methods

- (void) showCongratsView {
	
	CongratulationsController *congratsController = [[CongratulationsController alloc] initWithNibName:@"CongratulationsController" bundle:nil];
	[self.navigationController setNavigationBarHidden:YES animated:YES];
	[self.navigationController pushViewController:congratsController animated:YES];
	[congratsController release];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden {
    // Remove HUD from screen when the HUD was hidded
    [HUD removeFromSuperview];
    [HUD release];
	
}
#pragma mark -

- (void) activatePreyService {
    [(PreyAppDelegate*)[UIApplication sharedApplication].delegate registerForRemoteNotifications];
    [[PreyRunner instance] startOnIntervalChecking];
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
    strEmailMatchstring=@"\\b([a-zA-Z0-9%_.+\\-]+)@([a-zA-Z0-9.\\-]+?\\.[a-zA-Z]{2,6})\\b";
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
	[strEmailMatchstring release];
}


@end
