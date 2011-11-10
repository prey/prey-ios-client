//
//  PreyAppDelegate.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 29/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"


@interface PreyAppDelegate : NSObject <UIApplicationDelegate, UINavigationControllerDelegate, UIWebViewDelegate> {
    UIWindow *window;
	UINavigationController *viewController;
	NSDate *wentToBackground;
	BOOL showFakeScreen;
    NSString *url;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *viewController;

- (void)showOldUserWizard;
- (void)showNewUserWizard;
- (void)showPreferences;
- (void)showAlert: (NSString *) textToShow;
- (void)showFakeScreen;
- (void)registerForRemoteNotifications;

@end

