//
//  WelcomeController.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 04/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "WelcomeController.h"
#import "NewUserController.h"
#import "OldUserController.h"
#import "PreyAppDelegate.h"

@implementation WelcomeController

@synthesize buttnewUser, buttoldUser;


-(void)newUserClicked:(id)sender{
    NewUserController *nuController = [[NewUserController alloc] initWithStyle:UITableViewStyleGrouped];
	nuController.title = NSLocalizedString(@"Create Prey account",nil);
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate.viewController pushViewController:nuController animated:YES];
	[nuController release];
}

-(void)oldUserClicked:(id)sender{
    OldUserController *ouController = [[OldUserController alloc] initWithStyle:UITableViewStyleGrouped];
    ouController.title = NSLocalizedString(@"Log in to Prey",nil);
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate.viewController pushViewController:ouController animated:YES];
	[ouController release];
}

#pragma mark -
#pragma mark Lifecycle
/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

- (void) viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];

}

- (void) viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}
-(void)viewDidAppear:(BOOL)animated {
     /*PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.viewController popToRootViewControllerAnimated:NO];
    [super viewDidAppear:animated];*/
}
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
    self.screenName = @"Welcome";
    
    [self.buttnewUser setTitle:NSLocalizedString(@"New user", nil) forState: UIControlStateNormal];
    [self.buttoldUser setTitle:NSLocalizedString(@"Already a Prey user", nil) forState: UIControlStateNormal];
	[super viewDidLoad];
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


- (void)dealloc {
    [super dealloc];
}


@end
