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
    NewUserController *nuController = [[NewUserController alloc] init];
	nuController.title = NSLocalizedString(@"Create Prey account",nil);
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate.viewController pushViewController:nuController animated:YES];
}

-(void)oldUserClicked:(id)sender{
    OldUserController *ouController = [[OldUserController alloc] init];
    ouController.title = NSLocalizedString(@"Log in to Prey",nil);
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate.viewController pushViewController:ouController animated:YES];
}

#pragma mark -
#pragma mark Lifecycle

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

- (void)viewDidLoad {
    
    self.screenName = @"Welcome";
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        [self.buttnewUser.titleLabel setFont:[UIFont fontWithName:@"OpenSans" size:14]];
        [self.buttoldUser.titleLabel setFont:[UIFont fontWithName:@"OpenSans" size:14]];
    }
    else
    {
        [self.buttnewUser.titleLabel setFont:[UIFont fontWithName:@"OpenSans" size:20]];
        [self.buttoldUser.titleLabel setFont:[UIFont fontWithName:@"OpenSans" size:20]];
    }
    
    
    [self.buttnewUser setTitle:[NSLocalizedString(@"New user", nil) uppercaseString] forState: UIControlStateNormal];
    [self.buttoldUser setTitle:[NSLocalizedString(@"Already a Prey user", nil) uppercaseString] forState: UIControlStateNormal];
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

@end
