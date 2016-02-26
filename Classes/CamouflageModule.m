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
#import "Constants.h"

@implementation CamouflageModule

- (void)start
{
    NSInteger requestNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"requestNumber"] + 1;
    [[NSUserDefaults standardUserDefaults] setInteger:requestNumber forKey:@"requestNumber"];

    [[PreyConfig instance] setCamouflageMode:YES];
    [[PreyConfig instance] saveValues];

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
        
        if (appDelegate.viewController.presentedViewController)
            [appDelegate.viewController.presentedViewController dismissViewControllerAnimated:NO completion:NULL];
        
        [appDelegate.viewController setViewControllers:[NSArray arrayWithObjects:loginController, nil] animated:NO];
    }
    [super notifyCommandResponse:[self getName] withStatus:@"started"];
    
    PreyLogMessage(@"CamouflageModule", 10, @"CamouflageModule: command start");
}

- (void)stop
{
    NSInteger requestNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"requestNumber"] + 1;
    [[NSUserDefaults standardUserDefaults] setInteger:requestNumber forKey:@"requestNumber"];

    [[PreyConfig instance] setCamouflageMode:NO];
    [[PreyConfig instance] saveValues];
    
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
        
        if (appDelegate.viewController.presentedViewController)
            [appDelegate.viewController.presentedViewController dismissViewControllerAnimated:NO completion:NULL];

        [appDelegate.viewController setViewControllers:[NSArray arrayWithObjects:loginController, nil] animated:NO];
    }
    
    [super notifyCommandResponse:[self getName] withStatus:@"stopped"];
    
    PreyLogMessage(@"CamouflageModule", 10, @"CamouflageModule: command stop");
}


- (NSString *) getName {
	return @"camouflage";
}
@end
