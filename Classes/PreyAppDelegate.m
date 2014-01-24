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
#import "GAI.h"
#import "PreyDeployment.h"
#import "WizardController.h"
#import "ReportModule.h"

#warning Beta TestFlight
#import "TestFlight.h"

@interface PreyAppDelegate()

-(void)renderFirstScreen;

@end

@implementation PreyAppDelegate

@synthesize window,viewController;

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
    PreyLogMessage(@"App Delegate", 20,  @"Showing the guy our fake screen at: %@", self.url );
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    fakeView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, 20, appFrame.size.width, appFrame.size.height)] autorelease];
    [fakeView setDelegate:self];
    
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    [fakeView loadRequest:requestObj];
    
    [window addSubview:fakeView];
    [window makeKeyAndVisible];
}

- (void) displayAlert {
    if (showAlert){
        
        AlertModuleController *alertController;
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            alertController = [[AlertModuleController alloc] initWithNibName:@"AlertModuleController-iPhone" bundle:nil];
        else
            alertController = [[AlertModuleController alloc] initWithNibName:@"AlertModuleController-iPad" bundle:nil];
        
        [alertController setTextToShow:self.alertMessage];
        PreyLogMessage(@"App Delegate", 20, @"Displaying the alert message");
        
        [window addSubview:alertController.view];
        [window makeKeyAndVisible];
        [alertController release];
        showAlert = NO;
    }
}


- (void)showAlert: (NSString *) textToShow {
    self.alertMessage = textToShow;
	showAlert = YES;
    [self displayAlert]; //WIP Added this line for test purposes
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
    if (showAlert){
        [self displayAlert];
        return;
    }

}

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Google Analytics config
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    [GAI sharedInstance].dispatchInterval = 20;
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    
    //id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:@"UA-8743344-7"];
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-8743344-7"];
    
    
#warning Beta: TestFlight
    // !!!: Use the next line only during beta
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];    
    [TestFlight takeOff:@"994afc49-5f4c-4d74-9f36-b5592d0a3f54"];
    
    
    
    // Optional: set Logger to VERBOSE for debug information.
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:@"UA-8743344-7"];
    
        
    //IAPHelper *IAP = [IAPHelper sharedHelper];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:[IAPHelper sharedHelper]];
    //[IAPHelper initWithRemoteIdentifiers];
    
    //LoggerSetOptions(NULL, 0x01);  //Logs to console instead of nslogger.
	//LoggerSetViewerHost(NULL, (CFStringRef)@"10.0.0.105", 50000);
    //LoggerSetupBonjour(NULL, NULL, (CFStringRef)@"cyh");
	//LoggerSetBufferFile(NULL, (CFStringRef)@"/tmp/prey.log");
  
    PreyLogMessage(@"App Delegate", 20,  @"DID FINISH WITH OPTIONS %@!!", [launchOptions description]);
    
    id locationValue = [launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey];
	if (locationValue) //Significant location change received when app was closed.
	{
        PreyLogMessageAndFile(@"App Delegate", 0, @"[PreyAppDelegate] Significant location change received when app was closed!!");
        //[[PreyRunner instance] startOnIntervalChecking];
    }
    else {        
        UILocalNotification *localNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        id remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        
        if (remoteNotification) {
            PreyLogMessageAndFile(@"App Delegate", 10, @"Prey remote notification received while not running!");
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SendReport"])
            {
                self.url = [remoteNotification objectForKey:@"url"];
                showFakeScreen = YES;
            }
        }
        
        if (localNotif) {
            application.applicationIconBadgeNumber = localNotif.applicationIconBadgeNumber-1; 
            PreyLogMessage(@"App Delegate", 10, @"Prey local notification clicked... running!");
            //[[PreyRunner instance] startPreyService];
        }
        
        PreyConfig *config = [PreyConfig instance];
        if (config.alreadyRegistered) {
            
            [self registerForRemoteNotifications];
            //[[PreyRunner instance] startOnIntervalChecking];
     
            /*
            NSOperationQueue *bgQueue = [[NSOperationQueue alloc] init];
            NSInvocationOperation* updateStatus = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateMissingStatus:) object:config] autorelease];
            [bgQueue addOperation:updateStatus];
            [bgQueue release];
             */
        }
    }
  
	return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notif {
	
    PreyLogMessage(@"App Delegate", 10, @"Prey local notification received while in foreground... let's run Prey now!");
	//PreyRunner *runner = [PreyRunner instance];
	//[runner startPreyService];
    
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    
    PreyLogMessage(@"App Delegate", 20,  @"Will Resign Active");
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
    PreyLogMessage(@"App Delegate", 20,  @"DID BECOME ACTIVE!!");
    if ([viewController.view superview] == window) {
        return;
    }
    /*if (viewController.modalViewController) {
        return;
    }*/
    [window endEditing:YES];

    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    [self displayScreen];
	
}

- (void)displayScreen
{
    if (showAlert){
        [self displayAlert];
        return;
    }
    if (showFakeScreen){
        [self showFakeScreen];
        return;
	}
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SendReport"])
    {
        ReportModule *reportModule = [[[ReportModule alloc] init] autorelease];
        [reportModule get];
    }

    
    PreyConfig *config = [PreyConfig instance];
	
	UIViewController *nextController = nil;
	PreyLogMessage(@"App Delegate", 10, @"Already registered?: %@", ([config alreadyRegistered] ? @"YES" : @"NO"));
	if (config.alreadyRegistered)
    {
		if (config.askForPassword)
        {
#warning Beta: Wizard :: Logged Test
            
            if (config.camouflageMode)
            {
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
                    nextController = [[LoginController alloc] initWithNibName:@"LoginController-iPhone" bundle:nil];
                else
                    nextController = [[LoginController alloc] initWithNibName:@"LoginController-iPad" bundle:nil];
            }
            else
            {
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
                    nextController = [[WizardController alloc] initWithNibName:@"WizardController-iPhone" bundle:nil];
                else
                    nextController = [[WizardController alloc] initWithNibName:@"WizardController-iPad" bundle:nil];
            }
        }
            /*
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
                nextController = [[LoginController alloc] initWithNibName:@"LoginController-iPhone" bundle:nil];
            else
                nextController = [[LoginController alloc] initWithNibName:@"LoginController-iPad" bundle:nil];
            */
            
#warning Prey Deployment 
        /*
        PreyDeployment *preyDeployment = [[PreyDeployment alloc] init];
        if ([preyDeployment isCorrect])
        {
            nextController = [preyDeployment returnViewController];
        }
        else ...
        [preyDeployment release];
        */
            
            
		//else
		//	nextController = [[PreferencesController alloc] initWithNibName:@"PreferencesController" bundle:nil];
    }
    else
    {
#warning Beta: Wizard :: Welcome Test
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            nextController = [[WizardController alloc] initWithNibName:@"WizardController-iPhone" bundle:nil];
        else
            nextController = [[WizardController alloc] initWithNibName:@"WizardController-iPad" bundle:nil];
        
        /*
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            nextController = [[WelcomeController alloc] initWithNibName:@"WelcomeController-iPhone" bundle:nil];
        else
            nextController = [[WelcomeController alloc] initWithNibName:@"WelcomeController-iPad" bundle:nil];        
        */
    }
    
	viewController = [[UINavigationController alloc] initWithRootViewController:nextController];
	[viewController setToolbarHidden:YES animated:NO];
	[viewController setNavigationBarHidden:YES animated:NO];
    
    if ([viewController respondsToSelector:@selector(isBeingDismissed)])  // Supports iOS5 or later
    {
        [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navbarbg.png"] forBarMetrics:UIBarMetricsDefault];
        [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:0.42f
                                                                   green: 0.42f
                                                                    blue:0.42f
                                                                   alpha:1]];
    }
    
    
    [window setRootViewController:viewController];
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
	PreyLogMessage(@"App Delegate", 10, @"Application will terminate!. Time alive: %d minutes, %d seconds",minutes,seconds);
	
}


#pragma mark -
#pragma mark Prey Config

- (void)checkStatusInPreyPanel
{
    PreyRestHttp *http = [[PreyRestHttp alloc] init];
    PreyConfig *preyConfig = [PreyConfig instance];
    [http checkStatusForDevice:[preyConfig deviceKey] andApiKey:[preyConfig apiKey]];
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
/*
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    PreyLogMessageAndFile(@"App Delegate", 10, @"Remote notification received! : %@", [userInfo description]);    
    
    [self checkStatusInPreyPanel];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SendReport"])
    {
        self.url = [userInfo objectForKey:@"url"];
        showFakeScreen = YES;
    }
}
*/
#warning Testing BackgroundPushNotification Remote

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    PreyLogMessageAndFile(@"App Delegate", 10, @"Remote notification received in Background! : %@", [userInfo description]);
    
    [self checkStatusInPreyPanel];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SendReport"])
    {
        self.url = [userInfo objectForKey:@"url"];
        showFakeScreen = YES;
    }

    
    // Llamar solo para terminar proceso en background !!!
    [self performSelector:@selector(waitNotificationProcess:) withObject:completionHandler afterDelay:9];
    //completionHandler(UIBackgroundFetchResultNewData);
}

- (void) waitNotificationProcess:(void (^)(UIBackgroundFetchResult))completionHandler
{
    completionHandler(UIBackgroundFetchResultNewData);
    //PreyLogMessage(@"PreyRestHttp", 10, @"==== Finished Background Notifications =======");
}

#warning Testing Backgroundfetch SendReport
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    PreyLogMessageAndFile(@"App Delegate", 10, @"Init Background Fetch");
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SendReport"])
    {
        ReportModule *reportModule = [[[ReportModule alloc] init] autorelease];
        [reportModule get];
    }
    
    [self performSelector:@selector(waitNotificationProcess:) withObject:completionHandler afterDelay:9];
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
    [window release];
	[viewController release];
}


@end
