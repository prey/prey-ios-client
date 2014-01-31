//
//  AlertModule.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 19/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "CamouflageModule.h"
#import "PreyAppDelegate.h"
#import "PreyConfig.h"
#import "LoginController.h"
#import "WizardController.h"
#import "PreferencesController.h"

@implementation CamouflageModule

- (void)start
{
    [[PreyConfig instance] setCamouflageMode:YES];    

    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
    {
        LoginController *loginController;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            loginController = [[LoginController alloc] initWithNibName:@"LoginController-iPhone" bundle:nil];
        else
            loginController = [[LoginController alloc] initWithNibName:@"LoginController-iPad" bundle:nil];
        
        PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate.viewController pushViewController:loginController animated:NO];
        [loginController release];
    }
    [super notifyCommandResponse:[self getName] withStatus:@"started"];
}

- (void)stop
{
    [[PreyConfig instance] setCamouflageMode:NO];
    
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
    {
        PreferencesController *preferencesController = [[PreferencesController alloc] initWithStyle:UITableViewStyleGrouped];
        preferencesController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate.viewController setNavigationBarHidden:NO animated:NO];
        [appDelegate.viewController pushViewController:preferencesController animated:YES];
        [preferencesController release];
        /*
        WizardController *wizardController;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            wizardController = [[WizardController alloc] initWithNibName:@"WizardController-iPhone" bundle:nil];
        else
            wizardController = [[WizardController alloc] initWithNibName:@"WizardController-iPad" bundle:nil];
        
        PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate.viewController pushViewController:wizardController animated:NO];
        [wizardController release];
        */
    }
    
    [super notifyCommandResponse:[self getName] withStatus:@"stopped"];
}


- (NSString *) getName {
	return @"camouflage";
}
@end
