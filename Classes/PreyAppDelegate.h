//
//  PreyAppDelegate.h
//  Prey
//
//  Created by Carlos Yaconi on 29/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocationController.h"

@interface PreyAppDelegate : NSObject <UIApplicationDelegate, UINavigationControllerDelegate> {
    UIWindow *window;
	UINavigationController *viewController;
	
	LocationController *locationController;
	NSDate *wentToBackground;
	BOOL showFakeScreen;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *viewController;

- (void)showOldUserWizard;
- (void)showNewUserWizard;
- (void)showPreferences;
- (void)showAlert: (NSString *) textToShow;

@end

