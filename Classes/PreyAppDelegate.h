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
    UIWebView *fakeView;
	BOOL showFakeScreen;
    BOOL screenLoaded;
    BOOL showAlert;
}

@property (nonatomic) NSString *url;
@property (nonatomic) NSString *alertMessage;
@property (nonatomic) IBOutlet UIWindow *window;
@property (nonatomic) IBOutlet UINavigationController *viewController;
@property (nonatomic, copy) void (^onPreyVerificationSucceeded)(UIBackgroundFetchResult);

- (void)showAlert: (NSString *) textToShow;
- (void)showFakeScreen;
- (void)registerForRemoteNotifications;
- (void)changeShowFakeScreen:(BOOL)value;
- (void)checkedCompletionHandler;

@end

