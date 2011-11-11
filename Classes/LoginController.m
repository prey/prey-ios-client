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
    UIDeviceOrientation ori = [[UIDevice currentDevice] orientation];
    CGRect neueRect;
    if (UIDeviceOrientationIsLandscape(ori)) {
        NSLog(@"LAND");
        if (up) {
            neueRect = CGRectMake(0, -160, self.view.frame.size.width, self.view.frame.size.height);
        } else {
            neueRect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        }
    } else if (UIDeviceOrientationIsPortrait(ori)){
        NSLog(@"PORT");
        if (up) {
            neueRect = CGRectMake(0, -200, self.view.frame.size.width, self.view.frame.size.height);
        } else {
            neueRect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        }
    } else {
        //Chequear contra ancho de vista, si no, no funca. (FUCK YOU 5)
        CGFloat ancho = self.view.frame.size.width;
        if (ancho == 320) {
            if (up) {
                neueRect = CGRectMake(0, -200, self.view.frame.size.width, self.view.frame.size.height);
            } else {
                neueRect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
            }
        } else if (ancho == 480) {
            if (up) {
                neueRect = CGRectMake(0, -160, self.view.frame.size.width, self.view.frame.size.height);
            } else {
                neueRect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
            }
        }
    }
    
    if ( CGRectEqualToRect(neueRect, self.view.frame)) {
        return;
    }
	NSLog(@"%@ %@", NSStringFromCGRect(neueRect), NSStringFromCGRect(self.view.frame));	
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = neueRect;
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
    [self animateTextField:loginPassword up:[loginPassword isFirstResponder]];  
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
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
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
