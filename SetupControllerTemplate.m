//
//  SetupControllerTemplate.m
//  Prey
//
//  Created by Carlos Yaconi on 13/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "SetupControllerTemplate.h"
#import "CongratulationsController.h"

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
- (void) hideKeyboard 
{
	//Subclass must override it
	return;
}

#pragma mark -
#pragma mark IBActions
- (IBAction) cancel: (id) sender 
{
	[self dismissModalViewControllerAnimated:YES];
}
- (IBAction)doneEditing:(id)sender 
{
	[sender resignFirstResponder];
}

#pragma mark -
#pragma mark UI sliding methods
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self animateTextField: textField up: YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self animateTextField: textField up: NO];
}

- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    const int movementDistance = 80; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
	
    int movement = (up ? -movementDistance : movementDistance);
	
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden {
    // Remove HUD from screen when the HUD was hidded
    [HUD removeFromSuperview];
    [HUD release];
	
}
#pragma mark -
/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

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
}


@end
