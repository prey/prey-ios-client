//
//  AlertModule.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 19/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "AlertModule.h"
#import "PreyAppDelegate.h"
#import "AlertModuleController.h"

@implementation AlertModule

- (void)start
{
    NSString *alertMessage = [super.options objectForKey:@"alert_message"];

    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        UILocalNotification *localNotif = [[UILocalNotification alloc] init];
        if (localNotif)
        {
            localNotif.alertBody = alertMessage;
            localNotif.hasAction = NO;
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
            [localNotif release];
        }
    }
    else
    {
        [super notifyCommandResponse:[self getName] withStatus:@"started"];

        [self showAlertModule:alertMessage];
        
        [super notifyCommandResponse:[self getName] withStatus:@"stopped"];
    }
    
    PreyLogMessage(@"AlertModule", 10, @"AlertModule: command start");
}

- (void)showAlertModule:(NSString*)message
{
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    AlertModuleController *alertController;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        alertController = [[AlertModuleController alloc] initWithNibName:@"AlertModuleController-iPhone" bundle:nil];
    else
        alertController = [[AlertModuleController alloc] initWithNibName:@"AlertModuleController-iPad" bundle:nil];
    
    [alertController setTextToShow:message];
    PreyLogMessage(@"App Delegate", 20, @"Displaying the alert message");
    
    [appDelegate.viewController setViewControllers:[NSArray arrayWithObjects:alertController, nil] animated:NO];
    [alertController release];
}

- (NSString *) getName {
	return @"alert";
}
@end
