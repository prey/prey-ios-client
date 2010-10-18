//
//  PreyAppDelegate.m
//  Prey
//
//  Created by Carlos Yaconi on 29/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.

#import "PreyAppDelegate.h"
#import "LoginController.h"
#import "OldUserController.h"
#import "NewUserController.h"
#import "WelcomeController.h"
#import "PreyConfig.h"
#import "CongratulationsController.h"
#import "PreferencesController.h"
#import "Constants.h"


@interface PreyAppDelegate()

-(void)renderFirstScreen;

@end

@implementation PreyAppDelegate

@synthesize window;
@synthesize viewController;

-(void)renderFirstScreen{

	
}

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
		
	
	
	NSLog(@"Registering for push notifications...");    
    [[UIApplication sharedApplication] 
	 registerForRemoteNotificationTypes:
	 (UIRemoteNotificationTypeAlert | 
	  UIRemoteNotificationTypeBadge | 
	  UIRemoteNotificationTypeSound)];
	
	/*
	LoginController *loginController = [[LoginController alloc] initWithNibName:@"LoginController" bundle:nil];
    [window addSubview:loginController.view];
    [window makeKeyAndVisible];
    */
	/*
	OldUserController *ouController = [[OldUserController alloc] initWithNibName:@"OldUserController" bundle:nil];
	
	CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
    ouController.view.frame = applicationFrame;
	
    [window addSubview:ouController.view];
    [window makeKeyAndVisible];
	*/
	
	return YES;
}


- (void)showOldUserWizard {
	
	OldUserController *ouController = [[OldUserController alloc] initWithNibName:@"OldUserController" bundle:nil];
	UINavigationController *ouw = [[UINavigationController alloc] initWithRootViewController:ouController];
	
	ouw.delegate = self;
	ouController.title = NSLocalizedString(@"Prey install wizard",nil);
	ouw.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[viewController presentModalViewController:ouw animated:YES];

	// Release the view controllers to prevent over-retention.
	[ouw release];
	[ouController release];
	
	/*
	 OldUserController *ouController = [[OldUserController alloc] initWithNibName:@"OldUserController" bundle:nil];
	 
	 
	 CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
	 ouController.view.frame = applicationFrame;
	 [self.view addSubview:ouController.view];
	 
	 ouController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	 [self presentModalViewController:ouController animated:YES];
	 
	 [window addSubview:ouController.view];
	 [window makeKeyAndVisible];
	 */
}

- (void)showNewUserWizard {
	
	NewUserController *nuController = [[NewUserController alloc] initWithNibName:@"NewUserController" bundle:nil];
	UINavigationController *nuw = [[UINavigationController alloc] initWithRootViewController:nuController];
	
	nuw.delegate = self;
	nuController.title = NSLocalizedString(@"Prey install wizard",nil);
	nuw.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[viewController presentModalViewController:nuw animated:YES];
	
	// Release the view controllers to prevent over-retention.
	[nuw release];
	[nuController release];
}

- (void)showPreferences {
/*
	PreferencesController *preferencesController = [[PreferencesController alloc] initWithNibName:@"PreferencesController" bundle:nil];
	CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
	preferencesController.view.frame = applicationFrame;
	[self setViewController:preferencesController];
    [window addSubview:preferencesController.view];
    [window makeKeyAndVisible];
	[preferencesController release];
*/	
	PreferencesController *preferencesController = [[PreferencesController alloc] initWithNibName:@"PreferencesController" bundle:nil];
	CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
	preferencesController.view.frame = applicationFrame;
	
	// Begin animation setup
	[UIView beginAnimations:nil context:NULL];
	
	// Set duration for animation
	[UIView setAnimationDuration:1];
	
	// Set function to be called when animation is complete
	[UIView setAnimationDidStopSelector: @selector(animDone:finished:context:)];
	
	// Set the delegate (This object must have the function animDone)
	[UIView setAnimationDelegate:self];
	
	// Set Animation type and which UIView should animate
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:window cache:YES];
	
	// Add subview to the UIView set in the previous line
	[window addSubview:preferencesController.view];
	
	//Start the animation
	[UIView commitAnimations];
	
}

// Function to be called when the animation is complete
-(void)animDone:(NSString*) animationID finished:(BOOL) finished context:(void*) context
{
	// Add code here to be executed when the animation is done
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
	for (UIView *view in [window subviews]) {
		[view removeFromSuperview];
	}
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
	PreyConfig *config = [PreyConfig getInstance];
	
	UIViewController *nextController = nil;
	NSLog(@"Already registered?: %@", ([config alreadyRegistered] ? @"YES" : @"NO"));
	if (config.alreadyRegistered)
		if (ASK_FOR_LOGIN)
			nextController = [[LoginController alloc] initWithNibName:@"LoginController" bundle:nil];
		else
			nextController = [[PreferencesController alloc] initWithNibName:@"PreferencesController" bundle:nil];
	else
		nextController = [[WelcomeController alloc] initWithNibName:@"WelcomeController" bundle:nil];
	
	CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
	nextController.view.frame = applicationFrame;
	[self setViewController:nextController];
	[window addSubview:viewController.view];
	[window makeKeyAndVisible];
	
	[nextController release];
	[config release];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"Application will terminate");
	/*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}
#pragma mark -
#pragma mark Push notifications delegate

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken { 
	
    NSLog(@"Did register for remote notifications - Device Token=%@",deviceToken);
	
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err { 
	
    NSLog( @"Failed to register for remote notifications - Error: %@", err);    
	
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	
    for (id key in userInfo) {
        NSLog(@"Remote notification received - key: %@, value: %@", key, [userInfo objectForKey:key]);
    }    
	
}

#pragma mark -
#pragma mark UINavigationController delegate methods
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)_viewController animated:(BOOL)animated {
	NSLog(@"UINAV did show: %@", [_viewController class]);
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)_viewController animated:(BOOL)animated {
	NSLog(@"UINAV will show: %@", [_viewController class]);
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
	[super dealloc];
    [window release];
	[viewController release];
}


@end
