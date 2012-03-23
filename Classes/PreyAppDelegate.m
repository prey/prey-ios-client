//
//  PreyAppDelegate.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 29/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"

#import "PreyAppDelegate.h"
#import "LoginController.h"
#import "OldUserController.h"
#import "NewUserController.h"
#import "WelcomeController.h"
#import "PreyConfig.h"
#import "CongratulationsController.h"
#import "PreferencesController.h"
#import "Constants.h"
#import "AlertModuleController.h"
#import "PreyRunner.h"
#import "FakeWebView.h"
#import "PicturesController.h"
#import "IAPHelper.h"
#import "GANTracker.h"



@interface PreyAppDelegate()

-(void)renderFirstScreen;

@end

@implementation PreyAppDelegate

@synthesize window,viewController;
//@synthesize viewController;

-(void)renderFirstScreen{

	
}

#pragma mark -
#pragma mark Some useful stuff
- (void)registerForRemoteNotifications {
    PreyLogMessage(@"App Delegate", 10, @"Registering for push notifications...");    
    [[UIApplication sharedApplication] 
	 registerForRemoteNotificationTypes:
	 (UIRemoteNotificationTypeAlert | 
	  UIRemoteNotificationTypeBadge | 
	  UIRemoteNotificationTypeSound)];
}

- (void)showFakeScreen {
    PreyLogMessage(@"App Delegate", 20,  @"Showing the guy our fake screen at: %@", url );
    
    UIView *fake = [[UIView alloc] initWithFrame:CGRectMake(0,0,20,20)];
    fake.backgroundColor = [UIColor redColor];
    [window addSubview:fake];
    [window makeKeyAndVisible];
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    UIWebView *fakeView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, 20, appFrame.size.width, appFrame.size.height)] autorelease];
    [fakeView setDelegate:self];
    
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [fakeView loadRequest:requestObj];

    //[fakeView openUrl:url showingLoadingText:@"Accessing your account..."];
    
    [window addSubview:fakeView];
    //showFakeScreen = NO;
}

#pragma mark -
#pragma mark WebView delegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    PreyLogMessage(@"App Delegate", 20,  @"Attempting to show the HUD");
    MBProgressHUD *HUD2 = [MBProgressHUD showHUDAddedTo:webView animated:YES];
    HUD2.labelText = NSLocalizedString(@"Accessing your account...",nil);
    HUD2.removeFromSuperViewOnHide=YES;
    

}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [MBProgressHUD hideHUDForView:webView animated:YES];
    [[PicturesController instance]take:[NSNumber numberWithInt:5] usingCamera:@"front"];
}

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    if ([[[[UINavigationController alloc] init] autorelease] respondsToSelector:@selector(isBeingDismissed)]) {
        //Soporta iOS5
        [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navbarbg.png"] forBarMetrics:UIBarMetricsDefault];
        [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:0.42f
                    green: 0.42f
                    blue:0.42f 
                    alpha:1]];
    }
    //Analytics singleton tracker.
    [[GANTracker sharedTracker] startTrackerWithAccountID:@"UA-8743344-1" dispatchPeriod:10 delegate:nil];
    
    IAPHelper *IAP = [IAPHelper sharedHelper];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:IAP];
    [IAP initWithRemoteIdentifiers];
    
    //LoggerSetOptions(NULL, 0x01);  //Logs to console instead of nslogger.
	//LoggerSetViewerHost(NULL, (CFStringRef)@"10.0.0.5", 50000);
    //LoggerSetupBonjour(NULL, NULL, (CFStringRef)@"Prey");
	//LoggerSetBufferFile(NULL, (CFStringRef)@"/tmp/prey.log");
    
    /*
    PreyLogMessage(@"App Delegate", 20,[[UIDevice currentDevice] systemName]);
    PreyLogMessage(@"App Delegate", 20,[[UIDevice currentDevice] systemVersion]);
    PreyLogMessage(@"App Delegate", 20,[[UIDevice currentDevice] localizedModel]);
    PreyLogMessage(@"App Delegate", 20,[[UIDevice currentDevice] name]);
    PreyLogMessage(@"App Delegate", 20,[[UIDevice currentDevice] macaddress]);
    PreyLogMessage(@"App Delegate", 20,[[UIDevice currentDevice] platformString]);
    
    PreyLogMessage(@"App Delegate", 20,  @"DID FINISH WITH OPTIONS %@!!", [launchOptions description]);
    */
    id locationValue = [launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey];
	if (locationValue) //Significant location change received while app being closed.
	{
        PreyLogMessageAndFile(@"App Delegate", 0, @"[PreyAppDelegate] Significant location change received while app was closed!!");
        [[PreyRunner instance] startOnIntervalChecking];
    }
    else {        
        UILocalNotification *localNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        id remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (remoteNotification) {
            PreyLogMessageAndFile(@"App Delegate", 10, @"Prey remote notification received while not running!");	
            //[[PicturesController instance]take:[NSNumber numberWithInt:5] usingCamera:@"front"];
            url = [remoteNotification objectForKey:@"url"];
            [[PreyRunner instance] startPreyService];
            showFakeScreen = YES;
            //[self showAlert: @"Remote notification received. Here we can send the app to the background or show a customized message."];	
        }
        
        if (localNotif) {
            application.applicationIconBadgeNumber = localNotif.applicationIconBadgeNumber-1; 
            PreyLogMessage(@"App Delegate", 10, @"Prey local notification clicked... running!");
            [[PreyRunner instance] startPreyService];
        }
        
        PreyConfig *config = [PreyConfig instance];
        if (config.alreadyRegistered) {
            
            [self registerForRemoteNotifications];
            [[PreyRunner instance] startOnIntervalChecking];
     
            /*
            NSOperationQueue *bgQueue = [[NSOperationQueue alloc] init];
            NSInvocationOperation* updateStatus = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateMissingStatus:) object:config] autorelease];
            [bgQueue addOperation:updateStatus];
            [bgQueue release];
             */
        }
    }
     
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

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notif {
	/*
    LogMessage(@"App Delegate", 10, @"Prey local notification received while in foreground... let's run Prey now!");
	PreyRunner *runner = [PreyRunner instance];
	[runner startPreyService];
     */
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
    showFakeScreen = NO;
	PreyLogMessage(@"App Delegate", 10, @"Prey is now running in the background");
	wentToBackground = [NSDate date];
	for (UIView *view in [window subviews]) {
		[view removeFromSuperview];
	}
	
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
	PreyLogMessage(@"App Delegate", 10, @"Prey is now entering to the foreground");
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    if ([viewController.view superview] == self.window) {
        return;
    }
    if (viewController.modalViewController) {
        return;
    }
    [self.window endEditing:YES];

    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
     PreyLogMessage(@"App Delegate", 20,  @"DID BECOME ACTIVE!!");
    if (showFakeScreen){
        [self showFakeScreen];
        return;
	}
	
    PreyConfig *config = [PreyConfig instance];
	
	UIViewController *nextController = nil;
    UINavigationController *navco = nil;
	PreyLogMessage(@"App Delegate", 10, @"Already registered?: %@", ([config alreadyRegistered] ? @"YES" : @"NO"));
	if (config.alreadyRegistered)
		if (config.askForPassword)
			nextController = [[LoginController alloc] initWithNibName:@"LoginController" bundle:nil];
		else
			nextController = [[PreferencesController alloc] initWithNibName:@"PreferencesController" bundle:nil];
	else {
        nextController = [[LoginController alloc] initWithNibName:@"LoginController" bundle:nil];
		UIViewController *welco = [[WelcomeController alloc] initWithNibName:@"WelcomeController" bundle:nil];
        navco = [[UINavigationController alloc] initWithRootViewController:welco];
	}
	viewController = [[UINavigationController alloc] initWithRootViewController:nextController];
	//[viewController setTitle:NSLocalizedString(@"Welcome to Prey!",nil)];
	[viewController setToolbarHidden:YES animated:NO];
	[viewController setNavigationBarHidden:YES animated:NO];
	
	//window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [window addSubview:viewController.view];
    if (navco != nil) {
        [nextController presentModalViewController:navco animated:NO];
        [navco release];
    }
    [window makeKeyAndVisible];
	[nextController release];
}
- (void)updateMissingStatus:(id)data {
    [(PreyConfig*)data updateMissingStatus];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	int minutes=0;
	int seconds=0;
	if (wentToBackground != nil){
		NSTimeInterval inBg = [wentToBackground timeIntervalSinceNow];
		minutes = floor(-inBg/60);
		seconds = trunc(-inBg - minutes * 60);
	}
	PreyLogMessage(@"App Delegate", 10, @"Application will terminate!. Time alive: %f minutes, %f seconds",minutes,seconds);
	
}

// Function to be called when the animation is complete
-(void)animDone:(NSString*) animationID finished:(BOOL) finished context:(void*) context
{
	// Add code here to be executed when the animation is done
}

#pragma mark -
#pragma mark Wizards and preferences delegate methods

- (void)showOldUserWizard {
	OldUserController *ouController = [[OldUserController alloc] initWithStyle:UITableViewStyleGrouped];
    ouController.title = NSLocalizedString(@"Log in to Prey",nil);
	[viewController pushViewController:ouController animated:YES];
	[ouController release];
}

- (void)showNewUserWizard {
	NewUserController *nuController = [[NewUserController alloc] initWithStyle:UITableViewStyleGrouped];
	nuController.title = NSLocalizedString(@"Create Prey account",nil);
    
	[viewController pushViewController:nuController animated:YES];
	[nuController release];
}

- (void)showPreferences {

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
	
	for (UIView *subview in window.subviews)
		[subview removeFromSuperview];

	// Add subview to the UIView set in the previous line
	[window addSubview:preferencesController.view];
	
	//Start the animation
	[UIView commitAnimations];
	[preferencesController release];
	
}

- (void)showAlert: (NSString *) textToShow {
	AlertModuleController *alertController = [[AlertModuleController alloc] init];
    [alertController setTextToShow:textToShow];
    [viewController pushViewController:alertController animated:NO];
    [alertController release];
	
}

#pragma mark -
#pragma mark Push notifications delegate

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken { 
    NSString * tokenAsString = [[[deviceToken description] 
                                 stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] 
                                stringByReplacingOccurrencesOfString:@" " withString:@""];
    PreyLogMessageAndFile(@"App Delegate", 10, @"Did register for remote notifications - Device Token=%@",tokenAsString);
	PreyRestHttp *http = [[PreyRestHttp alloc] init];
    [http setPushRegistrationId:tokenAsString]; 
    [http release];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err { 
	
    PreyLogMessageAndFile(@"App Delegate", 10,  @"Failed to register for remote notifications - Error: %@", err);    
	
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    PreyLogMessageAndFile(@"App Delegate", 10, @"Remote notification received! : %@", [userInfo description]);    
    url = [userInfo objectForKey:@"url"];
    [[PreyRunner instance] startPreyService];
	showFakeScreen = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"missingUpdated" object:[PreyConfig instance]];
}

#pragma mark -
#pragma mark UINavigationController delegate methods
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)_viewController animated:(BOOL)animated {
	PreyLogMessage(@"App Delegate", 10, @"UINAV did show: %@", [_viewController class]);
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)_viewController animated:(BOOL)animated {
	PreyLogMessage(@"App Delegate", 10, @"UINAV will show: %@", [_viewController class]);
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
    [[GANTracker sharedTracker] stopTracker];
    [window release];
	[viewController release];
}


@end
