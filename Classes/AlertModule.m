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

- (void)start {
    [super notifyCommandResponse:[self getName] withStatus:@"started"];
    NSString *alertMessage = [super.options objectForKey:@"alert_message"];
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground){
        UILocalNotification *localNotif = [[UILocalNotification alloc] init];
        if (localNotif) {
            localNotif.alertBody = alertMessage;
            localNotif.hasAction = NO;
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
            [localNotif release];
        }
    } else {
        PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate showAlert:alertMessage];
        [super notifyCommandResponse:[self getName] withStatus:@"stopped"];
    }
}

- (NSString *) getName {
	return @"alert";
}
@end
