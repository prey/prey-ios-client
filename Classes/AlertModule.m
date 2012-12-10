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

- (void)main {
    NSString *alertMessage = [self.configParms objectForKey:@"alert_message"];
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground){
        UILocalNotification *localNotif = [[UILocalNotification alloc] init];
        if (localNotif) {
            localNotif.alertBody = alertMessage;
            localNotif.hasAction = NO;
            //localNotif.alertAction = NSLocalizedString(@"Read Message", nil);
            //localNotif.soundName = @"alarmsound.caf";
            //localNotif.applicationIconBadgeNumber = 1;
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
            [localNotif release];
        }
    } else {
        PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
        //SEL s = NSSelectorFromString(@"showAlert");
        //[appDelegate performSelector:s withObject:alertMessage afterDelay:2];
        [appDelegate showAlert:alertMessage];
    }
}

- (NSString *) getName {
	return @"alert";
}
@end
