//
//  PreyAppDelegate.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 29/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"

#import "PreyAppDelegate.h"
#import "PreyConfig.h"
#import "PreyRestHttp.h"
#import "PreyDeployment.h"
#import "Constants.h"
#import "LoginController.h"
#import "AlertModuleController.h"
#import "GrettingsProViewController.h"
#import "FakeWebView.h"
#import "ReportModule.h"
#import "AlertModule.h"
#import "GAI.h"
#import "MKStoreManager.h"
#import "OnboardingView.h"

@implementation PreyAppDelegate

@synthesize window,viewController;

#pragma mark -
#pragma mark Some useful stuff
- (void)registerForRemoteNotifications {
    PreyLogMessage(@"App Delegate", 10, @"Registering for push notifications...");    

    if (IS_OS_8_OR_LATER)
    {
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        
        if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
            [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
        }
    }
    else
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert |
                                                                               UIRemoteNotificationTypeBadge |
                                                                               UIRemoteNotificationTypeSound)];
}

- (void)changeShowFakeScreen:(BOOL)value
{
    showFakeScreen = value;
}

- (void)showFakeScreen
{
    PreyLogMessage(@"App Delegate", 20,  @"Showing the guy our fake screen at: %@", self.url );
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    fakeView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, appFrame.size.width, appFrame.size.height)];
    [fakeView setDelegate:self];
    
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    [fakeView loadRequest:requestObj];
    
    UIViewController *fakeViewController = [[UIViewController alloc] init];
    [fakeViewController.view addSubview:fakeView];
    
    [window setRootViewController:fakeViewController];
    [window makeKeyAndVisible];
}

- (void) displayAlert
{
    NSInteger requestNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"requestNumber"] + 2;
    [[NSUserDefaults standardUserDefaults] setInteger:requestNumber forKey:@"requestNumber"];

    AlertModule *alertModule = [[AlertModule alloc] init];
    [alertModule notifyCommandResponse:[alertModule getName] withStatus:@"started"];
    
    AlertModuleController *alertController;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        alertController = [[AlertModuleController alloc] initWithNibName:@"AlertModuleController-iPhone" bundle:nil];
    else
        alertController = [[AlertModuleController alloc] initWithNibName:@"AlertModuleController-iPad" bundle:nil];
    
    [alertController setTextToShow:self.alertMessage];
    PreyLogMessage(@"App Delegate", 20, @"Displaying the alert message");
    
    [window setRootViewController:alertController];
    [window makeKeyAndVisible];

    showAlert = NO;

    [alertModule notifyCommandResponse:[alertModule getName] withStatus:@"stopped"];
}


- (void)showAlert: (NSString *) textToShow {
    self.alertMessage = textToShow;
	showAlert = YES;
}

- (void)configSendReport:(NSDictionary*)userInformation
{
    if ([userInformation objectForKey:@"url"] == nil)
        self.url = @"http://m.bofa.com?a=1";
    else
        self.url = [userInformation objectForKey:@"url"];
    
    showFakeScreen = YES;
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
    [GAI sharedInstance].dispatchInterval = 120;
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelNone];
    [[GAI sharedInstance] trackerWithTrackingId:kGAIcode];
    [[[GAI sharedInstance] defaultTracker] setAllowIDFACollection:YES];

    
    // Add app Version in SettingsView
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [[NSUserDefaults standardUserDefaults] setObject:version forKey:@"version_preference"];

    
    // Preloads keyboard so there's no lag on initial keyboard appearance.
    UITextField *lagFreeField = [[UITextField alloc] init];
    lagFreeField.hidden = YES;
    [self.window addSubview:lagFreeField];
    [lagFreeField becomeFirstResponder];
    [lagFreeField resignFirstResponder];
    [lagFreeField removeFromSuperview];
    
    
    // Reset RequestNumber
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"requestNumber"];
    
    //LoggerSetOptions(NULL, 0x01);  //Logs to console instead of nslogger.
	//LoggerSetViewerHost(NULL, (CFStringRef)@"10.0.0.105", 50000);
    //LoggerSetupBonjour(NULL, NULL, (CFStringRef)@"cyh");
	//LoggerSetBufferFile(NULL, (CFStringRef)@"/tmp/prey.log");
  
    PreyLogMessage(@"App Delegate", 20,  @"DID FINISH WITH OPTIONS %@!!", [launchOptions description]);
    
    // Check remote notification clicked
    id remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotification)
    {
        PreyLogMessage(@"App Delegate", 10, @"Prey remote notification received while not running!");
        [self checkRemoteNotification:application remoteNotification:remoteNotification];
    }
    
    // Check local notification clicked
    UILocalNotification *localNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotif)
    {
        PreyLogMessage(@"App Delegate", 10, @"Prey local notification clicked... running!");
        [self checkLocalNotification:application localNotification:localNotif];
    }
    
    // Check notification_id with server
    PreyConfig *config = [PreyConfig instance];
    if (config.alreadyRegistered)
    {
        [self registerForRemoteNotifications];

        // In-App Purchase Instance
        if (!config.isPro)
            [MKStoreManager sharedManager];
    }
    
    [self displayScreen];
  
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    PreyLogMessage(@"App Delegate", 20,  @"Will Resign Active");
}


- (void)applicationWillTerminate:(UIApplication *)application
{
	PreyLogMessage(@"App Delegate", 10, @"Application will terminate!");
    
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    if (localNotif)
    {
        NSMutableDictionary *userInfoLocalNotification = [[NSMutableDictionary alloc] init];
        [userInfoLocalNotification setObject:@"keep_background" forKey:@"url"];
        
        localNotif.userInfo = userInfoLocalNotification;
        localNotif.alertBody = NSLocalizedString(@"Keep Prey in background to enable all of its features.", nil);
        localNotif.hasAction = NO;
        localNotif.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    showFakeScreen = NO;
	PreyLogMessage(@"App Delegate", 10, @"Prey is now running in the background");
    
    PreyConfig *config = [PreyConfig instance];
    if (config.alreadyRegistered) {
        for (UIView *view in [window subviews]) {
            [view removeFromSuperview];
        }
    }
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
	PreyLogMessage(@"App Delegate", 10, @"Prey is now entering to the foreground");
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    PreyLogMessage(@"App Delegate", 20,  @"DID BECOME ACTIVE!!");
    
    if ( ([viewController.view superview] == window) ||
         ([viewController.presentedViewController isKindOfClass:[GrettingsProViewController class]]) )
        return;

    
    [window endEditing:YES];

    if (application.applicationIconBadgeNumber > 0)
    {
        self.url = @"http://m.bofa.com?a=1";
        showFakeScreen = YES;
        application.applicationIconBadgeNumber = -1;
    }

    [self displayScreen];
}

- (void)displayScreen
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SendReport"])
    {
        PreyLogMessage(@"App Delegate", 10, @"Send Report: displayScreen");
        [[ReportModule instance] get];
    }

    if (showAlert){
        [self displayAlert];
        return;
    }
    if (showFakeScreen){
        [self showFakeScreen];
        return;
	}
    
    PreyConfig *config = [PreyConfig instance];
	
	UIViewController *nextController = nil;
	PreyLogMessage(@"App Delegate", 10, @"Already registered?: %@", ([config alreadyRegistered] ? @"YES" : @"NO"));
	if (config.alreadyRegistered)
    {
		if (config.askForPassword)
        {
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            {
                if (IS_IPHONE5)
                    nextController = [[LoginController alloc] initWithNibName:@"LoginController-iPhone-568h" bundle:nil];
                else
                    nextController = [[LoginController alloc] initWithNibName:@"LoginController-iPhone" bundle:nil];
            }
            else
                nextController = [[LoginController alloc] initWithNibName:@"LoginController-iPad" bundle:nil];
        }
    }
    else
    {
        [PreyDeployment runPreyDeployment];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        {
            if (IS_IPHONE5)
                nextController = [[OnboardingView alloc] initWithNibName:@"OnboardingView-iPhone-568h" bundle:nil];
            else
                nextController = [[OnboardingView alloc] initWithNibName:@"OnboardingView-iPhone" bundle:nil];
        }
        else
            nextController = [[OnboardingView alloc] initWithNibName:@"OnboardingView-iPad" bundle:nil];
    }
    
	viewController = [[UINavigationController alloc] initWithRootViewController:nextController];
	[viewController setToolbarHidden:YES animated:NO];
	[viewController setNavigationBarHidden:YES animated:NO];
    
    
    if ([viewController respondsToSelector:@selector(isBeingDismissed)])  // Supports iOS5 or later
    {
        UIFont *fontTitle, *fontItem;
        UIColor *colorTitle = [UIColor colorWithRed:.3019f green:.3411f blue:.4f alpha:1];
        UIColor *colorItem  = [UIColor colorWithRed:0 green:.5058f blue:.7607f alpha:1];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        {
            fontItem = [UIFont fontWithName:@"OpenSans-Bold" size:12];
            fontTitle = [UIFont fontWithName:@"OpenSans-Semibold" size:13];
        }
        else
        {
            fontItem = [UIFont fontWithName:@"OpenSans-Bold" size:18];
            fontTitle = [UIFont fontWithName:@"OpenSans-Semibold" size:20];
        }
        
        [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              colorTitle, UITextAttributeTextColor,
                                                              fontTitle,UITextAttributeFont,nil]];

        NSDictionary *barButtonAppearanceDict = @{UITextAttributeFont:fontItem, UITextAttributeTextColor:colorItem};
        [[UIBarButtonItem appearance] setTitleTextAttributes:barButtonAppearanceDict forState:UIControlStateNormal];
        
        
        if (IS_OS_7_OR_LATER)
        {
            [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
            // Back arrow color
            [[UINavigationBar appearance] setTintColor:colorItem];
        }
        else
        {
            [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
        }
    }
    
    
    [window setRootViewController:viewController];
    [window makeKeyAndVisible];
}

#pragma mark -
#pragma mark Push notifications delegate

#ifdef __IPHONE_8_0
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    if (notificationSettings.types == UIUserNotificationTypeNone)
        [[PreyConfig instance] setIsNotificationSettingsEnabled:NO];
    else
        [[PreyConfig instance] setIsNotificationSettingsEnabled:YES];
}
#endif

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notif
{
    PreyLogMessage(@"App Delegate", 10, @"Prey local notification received while in foreground... let's run Prey now!");
    
    [self checkLocalNotification:application localNotification:notif];
}

- (void)checkLocalNotification:(UIApplication*)application localNotification:(UILocalNotification *)notification
{
    if ( [[notification.userInfo objectForKey:@"url"] isEqual:@"alert_message"] )
        [self showAlert:notification.alertBody];
    
    else if( [[notification.userInfo objectForKey:@"url"] isEqual:@"http://m.bofa.com?a=1"] )
        [self configSendReport:notification.userInfo];
    
    application.applicationIconBadgeNumber = -1;
    [application cancelAllLocalNotifications];
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString * tokenAsString = [[[deviceToken description] 
                                 stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] 
                                stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    [PreyRestHttp setPushRegistrationId:5 withToken:tokenAsString
                              withBlock:^(NSHTTPURLResponse *response, NSError *error) {
    PreyLogMessage(@"App Delegate", 10, @"Did register for remote notifications - Device Token");
    }];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
    PreyLogMessage(@"App Delegate", 10,  @"Failed to register for remote notifications - Error: %@", err);
}


- (void)checkRemoteNotification:(UIApplication*)application remoteNotification:(NSDictionary *)userInfo
{
    [PreyRestHttp checkStatusForDevice:5 withBlock:^(NSHTTPURLResponse *response, NSError *error) {
        if (error) {
            PreyLogMessage(@"PreyAppDelegate", 10,@"Error: %@",error);
        } else {
            PreyLogMessage(@"PreyAppDelegate", 10,@"OK:");
        }
    }];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SendReport"])
        [self configSendReport:userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    PreyLogMessage(@"App Delegate", 10, @"Remote notification received! : %@", [userInfo description]);
    [self checkRemoteNotification:application remoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    PreyLogMessage(@"App Delegate", 10, @"Remote notification received in Background! : %@", [userInfo description]);

    self.onPreyVerificationSucceeded = completionHandler;
    
    if ([userInfo objectForKey:@"url-echo"] == nil)
    {
        if ([userInfo objectForKey:@"cmd"] == nil)
        {
            [PreyRestHttp checkStatusForDevice:5 withBlock:^(NSHTTPURLResponse *response, NSError *error) {
                if (error)
                {
                    [self checkedCompletionHandlerError];
                    PreyLogMessage(@"PreyAppDelegate", 10,@"Error: %@",error);
                }
                else
                    PreyLogMessage(@"PreyAppDelegate", 10,@"OK Background");
            }];
        }
        else
            [PreyRestHttp checkCommandJsonForDevice:[userInfo objectForKey:@"cmd"]];
    }
    else
    {        
        [PreyRestHttp checkStatusInBackground:5 withURL:[userInfo objectForKey:@"url-echo"] withBlock:^(NSHTTPURLResponse *response, NSError *error)
         {
             if (error)
             {
                 [self checkedCompletionHandlerError];
                 PreyLogMessage(@"PreyAppDelegate", 10,@"Error: %@",error);
             }
             else
             {
                 [self checkedCompletionHandler];
                 PreyLogMessage(@"PreyAppDelegate", 10,@"OK Echo");
             }
         }];
    }
}

- (void)checkedCompletionHandlerError
{
    if (self.onPreyVerificationSucceeded)
    {
        self.onPreyVerificationSucceeded(UIBackgroundFetchResultFailed);
        self.onPreyVerificationSucceeded = nil;
    }
}

- (void)checkedCompletionHandler
{
    NSInteger requestNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"requestNumber"] - 1;
    
    if ( (self.onPreyVerificationSucceeded) && (requestNumber <= 0) )
    {
        PreyLogMessage(@"PreyAppDelegate", 10,@"OK UIBackgroundFetchResultNewData");
        self.onPreyVerificationSucceeded(UIBackgroundFetchResultNewData);
        self.onPreyVerificationSucceeded = nil;
        requestNumber = 0;
    }
    
    if (requestNumber <= 0)
        requestNumber = 0;
    
    PreyLogMessage(@"PreyAppDelegate", 10,@"Number Request: %ld",(long)requestNumber);
    
    [[NSUserDefaults standardUserDefaults] setInteger:requestNumber forKey:@"requestNumber"];
}

-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    PreyLogMessage(@"App Delegate", 10, @"Init Background Fetch");
    
    self.onPreyVerificationSucceeded = completionHandler;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SendReport"])
        [[ReportModule instance] get];
    else
    {
        if (self.onPreyVerificationSucceeded)
        {
            self.onPreyVerificationSucceeded(UIBackgroundFetchResultNoData);
            self.onPreyVerificationSucceeded = nil;
        }
    }
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}

@end
