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
#import "Constants.h"

@implementation CamouflageModule

- (void)start
{
    [[PreyConfig instance] setCamouflageMode:YES];    

    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
    {
        PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
        
        LoginController *loginController;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        {
            if (IS_IPHONE5)
                loginController = [[LoginController alloc] initWithNibName:@"LoginController-iPhone-568h" bundle:nil];
            else
                loginController = [[LoginController alloc] initWithNibName:@"LoginController-iPhone" bundle:nil];
        }
        else
            loginController = [[LoginController alloc] initWithNibName:@"LoginController-iPad" bundle:nil];
        
        [appDelegate.viewController setViewControllers:[NSArray arrayWithObjects:loginController, nil] animated:NO];
        [loginController release];
    }
    [super notifyCommandResponse:[self getName] withStatus:@"started"];
}

- (void)stop
{
    [[PreyConfig instance] setCamouflageMode:NO];
    
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
    {
        PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
        
        LoginController *loginController;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        {
            if (IS_IPHONE5)
                loginController = [[LoginController alloc] initWithNibName:@"LoginController-iPhone-568h" bundle:nil];
            else
                loginController = [[LoginController alloc] initWithNibName:@"LoginController-iPhone" bundle:nil];
        }
        else
            loginController = [[LoginController alloc] initWithNibName:@"LoginController-iPad" bundle:nil];
        
        [appDelegate.viewController setViewControllers:[NSArray arrayWithObjects:loginController, nil] animated:NO];
        [loginController release];
    }
    
    [super notifyCommandResponse:[self getName] withStatus:@"stopped"];
}


- (NSString *) getName {
	return @"camouflage";
}
@end
