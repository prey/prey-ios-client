//
//  PreyAppDelegate.h
//  Prey
//
//  Created by Carlos Yaconi on 29/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PreyAppDelegate : NSObject <UIApplicationDelegate, UINavigationControllerDelegate> {
    UIWindow *window;
	UIViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIViewController *viewController;

- (void)showOldUserWizard;
- (void)showNewUserWizard;
- (void)showPreferences;

@end

