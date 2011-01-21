//
//  OldUserController.m
//  Prey
//
//  Created by Carlos Yaconi on 01/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "OldUserController.h"
#import "CongratulationsController.h"
#import "User.h"
#import "Device.h"
#import "PreyConfig.h"
#import "PreyAppDelegate.h"


@interface OldUserController () 

- (void) addDeviceForCurrentUser;

@end

@implementation OldUserController

@synthesize email,password;

- (void) addDeviceForCurrentUser {
//#if !(TARGET_IPHONE_SIMULATOR)
//	sleep(1);
//	[self performSelectorOnMainThread:@selector(showCongratsView) withObject:nil waitUntilDone:NO];
//#else
	User *user = nil;
	Device *device = nil;
	PreyConfig *config = nil;
	@try {
		user = [User initWithEmail:[email text] password:[password text]];
		device = [Device newDeviceForApiKey:[user apiKey]];
		config = [PreyConfig initWithUser:user andDevice:device];
		if (config != nil)
			[self performSelectorOnMainThread:@selector(showCongratsView) withObject:nil waitUntilDone:NO];

	}
	@catch (NSException * e) {		
		if (device != nil)
			[user deleteDevice:device];
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Hold your horses!",nil) message:[e reason] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
		[alertView show];
		[alertView release];
	} @finally {
		[user release];
		[device release];
		[config release];
	}
//#endif
}

- (void) hideKeyboard {
	
	[email resignFirstResponder];
	[password resignFirstResponder];
	 
}



#pragma mark -
#pragma mark IBAction

- (IBAction) next: (id) sender
{
	[self hideKeyboard];
	HUD = [[MBProgressHUD alloc] initWithView:self.view];
    HUD.delegate = self;
    HUD.labelText = NSLocalizedString(@"Attaching device...",nil);
	[self.navigationController.view addSubview:HUD];
	[HUD showWhileExecuting:@selector(addDeviceForCurrentUser) onTarget:self withObject:nil animated:YES];
	
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


- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)dealloc {
    [super dealloc];
	[email release];
	[password release];
}



@end
