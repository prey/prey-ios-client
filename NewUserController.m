//
//  NewUserController.m
//  Prey
//
//  Created by Carlos Yaconi on 01/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "NewUserController.h"
#import "User.h"
#import "Device.h"
#import "PreyConfig.h"

@interface NewUserController () 

- (void) addNewUser;

@end

@implementation NewUserController

@synthesize name,email,password,repassword;
#pragma mark -
#pragma mark Private methods

- (void) hideKeyboard {
	
	[email resignFirstResponder];
	[name resignFirstResponder];
	[password resignFirstResponder];
	[repassword resignFirstResponder];
}

- (void) addNewUser {
	if (![password.text isEqualToString:repassword.text]){
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"We have a situation!",nil) message:NSLocalizedString(@"Passwords do not match",nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];		
		[alertView show];
		[alertView release];	
		return;
	}
	if ([password.text length] <6){
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"We have a situation!",nil) message:NSLocalizedString(@"Passwords must be at least 6 characters",nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];		
		[alertView show];
		[alertView release];
		return;
	}
	
#if (TARGET_IPHONE_SIMULATOR)
	sleep(1);
	[self performSelectorOnMainThread:@selector(showCongratsView) withObject:@"congrats dummy text" waitUntilDone:NO];
#else
	User *user = nil;
	Device *device = nil;
	PreyConfig *config = nil;
	@try {
		user = [User createNew:[name text] email:[email text] password:[password text] repassword:[repassword text]];
		device = [Device newDeviceForApiKey:[user apiKey]];
		config = [PreyConfig initWithUser: user andDevice:device];
		if (config != nil){
			NSString *txtCongrats = NSLocalizedString(@"Account created! Remember to verify your account by opening your inbox and clicking on the link we sent to your email address.",nil);
			[self performSelectorOnMainThread:@selector(showCongratsView) withObject:txtCongrats waitUntilDone:NO];
		}
	}
	@catch (NSException * e) {
		if (device != nil)
			[user deleteDevice:device];
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"User couldn't be created",nil) message:[e reason] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
		[alertView show];
		[alertView release];
		
	}
	@finally {
		[user release];
		[device release];
		[config release];
	}
#endif
}

#pragma mark -
#pragma mark IBActions



- (IBAction) next: (id) sender {
	[self hideKeyboard];
	HUD = [[MBProgressHUD alloc] initWithView:self.view];
    HUD.delegate = self;
    HUD.labelText = NSLocalizedString(@"Creating account...",nil);
	[self.navigationController.view addSubview:HUD];
	[HUD showWhileExecuting:@selector(addNewUser) onTarget:self withObject:nil animated:YES];
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
	[name release];
	[email release];
	[password release];
	[repassword release];
}


@end
