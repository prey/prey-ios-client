//
//  LoginController.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 29/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "LoginController.h"
#import "User.h"
#import "PreyConfig.h"

@interface LoginController()

- (void) checkPassword;
- (void) hideKeyboard;
- (void) animateTextField: (UITextField*) textField up: (BOOL) up;
- (void)setViewMovedUp:(BOOL)movedUp;

@property int movementDistance; // tweak as needed

@end


@implementation LoginController

@synthesize loginPassword, loginImage, movementDistance;


- (void) checkPassword {
	PreyConfig *config = [PreyConfig instance];
    
    @try {
        User *user = [User allocWithEmail: config.email password: loginPassword.text];
        
		PreferencesController *preferencesViewController = [[PreferencesController alloc] initWithNibName:@"PreferencesController" bundle:nil];
		preferencesViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [self.navigationController pushViewController:preferencesViewController animated:YES];
        [preferencesViewController release];
		/*
        [self presentModalViewController:preferencesViewController animated:YES];
		
         */
		[user release];
	} @catch (NSException *e)  {
        NSString *title = nil;
        NSString *message = nil;
        if ([[e name]isEqualToString:@"GetApiKeyUnknownException"]){
            message = [e description];
            title = NSLocalizedString(@"Couldn't check your password",nil);
        }
        else {
            message = NSLocalizedString(@"Wrong password. Try again.",nil);
            title = NSLocalizedString(@"Access Denied",nil);
        }
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alertView show];
		[alertView release];
	} 
	
}

- (IBAction) checkLoginPassword: (id) sender {
	if ([loginPassword.text length] <6){
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Access Denied",nil) message:NSLocalizedString(@"Wrong password. Try again.",nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];		
		[alertView show];
		[alertView release];
		return;
	}
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



#pragma mark -
#pragma mark screen rotation stuff

-(void) detectOrientation {
    movementDistance = 200;
    if (([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft) || 
        ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight)) {
        movementDistance = 160;
        [self setViewMovedUp:YES];
    } 
    if ([loginPassword isFirstResponder])
        [self textFieldDidBeginEditing:loginPassword];
    /*
    else if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait) {
        [self setViewMovedUp:NO];
    } */  
}

-(void)setViewMovedUp:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5]; // if you want to slide up the view
    
    CGRect rect = self.view.frame;
    if (movedUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard 
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y -= kOFFSET_FOR_KEYBOARD;
        rect.size.height += kOFFSET_FOR_KEYBOARD;
    }
    else
    {
        // revert back to the normal state.
        rect.origin.y += kOFFSET_FOR_KEYBOARD;
        rect.size.height -= kOFFSET_FOR_KEYBOARD;
    }
    self.view.frame = rect;
    
    [UIView commitAnimations];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation ==UIInterfaceOrientationLandscapeRight);
}

#pragma mark -
#pragma mark view methods

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    movementDistance = 200;
    PreyConfig *config = [PreyConfig instance];
    UIImage *img = nil;
    if (config.camouflageMode)
        img = [[UIImage imageNamed:@"star_wars_battlefront.png"] autorelease];
    else
        img = [[UIImage imageNamed:@"prey-logo.png"] autorelease];
    self.loginImage.image = img;
    
    [self.loginPassword addTarget:self
                           action:@selector(textFieldFinished:)
                 forControlEvents:UIControlEventEditingDidEndOnExit];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detectOrientation) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    [super viewDidLoad];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil]; 
}

 /*
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
