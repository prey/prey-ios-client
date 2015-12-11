//
//  StatusDeviceVC.m
//  Prey
//
//  Created by Javier Cala Uribe on 9/12/15.
//  Copyright © 2015 Fork Ltd. All rights reserved.
//

#import "StatusDeviceVC.h"
#import "SignUpVC.h"
#import "Constants.h"
#import "PreyAppDelegate.h"

@interface StatusDeviceVC ()

@end

@implementation StatusDeviceVC

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)callSignUpView:(id)sender
{
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    SignUpVC *nextController;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        if (IS_IPHONE5)
            nextController = [[SignUpVC alloc] initWithNibName:@"SignUpVC-iPhone-568h" bundle:nil];
        else
            nextController = [[SignUpVC alloc] initWithNibName:@"SignUpVC-iPhone" bundle:nil];
    }
    else
        nextController = [[SignUpVC alloc] initWithNibName:@"SignUpVC-iPad" bundle:nil];
    
    [appDelegate.viewController setViewControllers:[NSArray arrayWithObjects:nextController, nil] animated:NO];
}

@end
