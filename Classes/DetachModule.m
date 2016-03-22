//
//  DetachModule.m
//  Prey-iOS
//
//  Created by Javier Cala on 23/04/2015.
//  Copyright 2015 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "DetachModule.h"
#import "PreyAppDelegate.h"
#import "ReportModule.h"
#import "PreyConfig.h"
#import "OnboardingView.h"
#import "PreferencesController.h"
#import "RecoveriesViewController.h"
#import "Constants.h"

@implementation DetachModule

- (void)start
{
    [self detachDevice];
    
    PreyLogMessage(@"DetachModule", 10, @"DetachModule: command start");
}

- (void)detachDevice
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SendReport"])
        [[ReportModule instance] stop];
    
    [[PreyConfig instance] resetValues];
    
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
    {
        UIViewController *onboardingVC;

        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        {
            if (IS_IPHONE5)
                onboardingVC = [[OnboardingView alloc] initWithNibName:@"OnboardingView-iPhone-568h" bundle:nil];
            else
                onboardingVC = [[OnboardingView alloc] initWithNibName:@"OnboardingView-iPhone" bundle:nil];
        }
        else
            onboardingVC = [[OnboardingView alloc] initWithNibName:@"OnboardingView-iPad" bundle:nil];
        
        
        PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
        
        if ([appDelegate.viewController.visibleViewController  isKindOfClass:[PreferencesController class]])
        {
            PreferencesController *tmpVC   = (PreferencesController*)appDelegate.viewController.visibleViewController;
            tmpVC.tableViewInfo.delegate   = nil;
            tmpVC.tableViewInfo.dataSource = nil;
            tmpVC.tableViewInfo = nil;
        }
        
        if ([appDelegate.viewController.visibleViewController  isKindOfClass:[RecoveriesViewController class]])
        {
            RecoveriesViewController *tmpVC = (RecoveriesViewController*)appDelegate.viewController.visibleViewController;
            tmpVC.tableViewInfo.delegate    = nil;
            tmpVC.tableViewInfo.dataSource  = nil;
            tmpVC.tableViewInfo = nil;
        }        

        [appDelegate.viewController setNavigationBarHidden:YES animated:NO];
        [appDelegate.viewController setViewControllers:[NSArray arrayWithObject:onboardingVC] animated:NO];
    }
}

- (NSString *) getName {
	return @"detach";
}
@end
