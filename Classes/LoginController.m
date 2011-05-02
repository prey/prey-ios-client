//
//  LoginController.m
//  Prey
//
//  Created by Carlos Yaconi on 29/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "LoginController.h"
#import "User.h"
#import "PreyConfig.h"

@interface LoginController()

- (void) checkPassword;
- (void) hideKeyboard;
- (void) animateTextField: (UITextField*) textField up: (BOOL) up;

@end


@implementation LoginController

@synthesize loginPassword;

- (void) checkPassword {
	PreyConfig *config = [PreyConfig instance];
	User *user = [User allocWithEmail: config.email password: loginPassword.text];
	
	if (user != nil){
		PreferencesController *preferencesViewController = [[PreferencesController alloc] initWithNibName:@"PreferencesController" bundle:nil];
		preferencesViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		[self presentModalViewController:preferencesViewController animated:YES];
		[preferencesViewController release];
		[user release];
	} else {
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Access Denied!",nil) message:NSLocalizedString(@"Wrong password. Try again.",nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alertView show];
		[alertView release];
	}
	
}

- (IBAction) checkLoginPassword: (id) sender {
	
	[self hideKeyboard];
	HUD = [[MBProgressHUD alloc] initWithView:self.view];
    HUD.delegate = self;
    HUD.labelText = NSLocalizedString(@"Please wait",nil);
	HUD.detailsLabelText = NSLocalizedString(@"Checking your password...",nil);
	[self.view addSubview:HUD];
	[HUD showWhileExecuting:@selector(checkPassword) onTarget:self withObject:nil animated:YES];
}

- (void) hideKeyboard {
	[loginPassword resignFirstResponder];
	
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden {
    // Remove HUD from screen when the HUD was hidded
    [HUD removeFromSuperview];
    [HUD release];
	
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
    const int movementDistance = 140; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
	
    int movement = (up ? -movementDistance : movementDistance);
	
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}


#pragma mark -

- (IBAction)textFieldFinished:(id)sender
{
    [self checkLoginPassword:sender];
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
     [self.loginPassword addTarget:self
                        action:@selector(textFieldFinished:)
              forControlEvents:UIControlEventEditingDidEndOnExit];
     [super viewDidLoad];
 }

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 
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

*/
- (void)dealloc {
    [super dealloc];
}


@end
