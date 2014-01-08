//
//  WizardController.m
//  Prey
//
//  Created by Javier Cala Uribe on 8/07/13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "WizardController.h"

#import "PreyAppDelegate.h"
#import "User.h"
#import "Device.h"
#import "PreyConfig.h"

#import "Location.h"

@interface WizardController ()

@end

@implementation WizardController

@synthesize wizardWebView;

#pragma mark Init

- (void)dealloc
{
    [super dealloc];
    [wizardWebView release];
    [location release];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"Wizard"]];
    
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    wizardWebView = [[UIWebView alloc] initWithFrame:appDelegate.window.frame];
    [wizardWebView loadRequest:[NSURLRequest requestWithURL:url]];
    [wizardWebView setDelegate:self];

    [self.view addSubview:wizardWebView];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark Old User


- (void) addDeviceForCurrentUser:(NSArray*)userData{
	
	User *user = nil;
	Device *device = nil;
	PreyConfig *config = nil;
	@try {
		user    = [User allocWithEmail:userData[1] password:userData[2]];
		device  = [Device newDeviceForApiKey:[user apiKey]];
		config  = [[PreyConfig initWithUser:user andDevice:device] retain];
		if (config != nil){
            //NSString *txtCongrats = NSLocalizedString(@"Congratulations! You have successfully associated this iOS device with your Prey account.",nil);
            
            [(PreyAppDelegate*)[UIApplication sharedApplication].delegate registerForRemoteNotifications];
            
            [self deviceAddedSuccessfully];
        }
        
	}
	@catch (NSException * e) {
		if (device != nil)
			[user deleteDevice:device];
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Couldn't add your device",nil) message:[e reason] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
		[alertView show];
		[alertView release];
	} @finally {
        [config release];
		[user release];
		[device release];
	}
}

- (void)deviceAddedSuccessfully
{
    [wizardWebView stringByEvaluatingJavaScriptFromString:@"Wizard.load('ok')"];
    
    [self enableLocationManager];
    [self enablePrey];
}

- (void)enableLocationManager
{
    location = [[Location alloc] init];
    [location testLocation];
}

- (void)enablePrey
{
    UIRemoteNotificationType notificationTypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    
    if (notificationTypes & UIRemoteNotificationTypeAlert)
        PreyLogMessage(@"App Delegate", 10, @"Alert notification set. Good!");
    else
    {
        PreyLogMessage(@"App Delegate", 10, @"User has disabled alert notifications");
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert notification disabled",nil)
                                                            message:NSLocalizedString(@"You need to grant Prey access to show alert notifications in order to remotely mark it as missing.",nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                  otherButtonTitles:nil];
		[alertView show];
		[alertView release];
    }

}


#pragma mark UIWebViewDelegate


- (void)callJavaScriptMethod:(NSURL *)userInfo
{    
    if ([[userInfo host] isEqualToString:@"index"])
    {
        PreyConfig *config = [PreyConfig instance];
        
        if (config.alreadyRegistered)
        {
            if (config.askForPassword)
            {
                [wizardWebView stringByEvaluatingJavaScriptFromString:@"Wizard.load('ok')"];
                [self enablePrey];
            }
        }
        else
        {
            NSInteger currentPage = [[NSUserDefaults standardUserDefaults] integerForKey:@"currentViewWizard"];
            if (currentPage == 0)
                currentPage = 1;
            
            NSString *loadString = [NSString stringWithFormat:@"Wizard.load('%d')",currentPage];
            
            [wizardWebView stringByEvaluatingJavaScriptFromString:@"Wizard.start(4)"];
            [wizardWebView stringByEvaluatingJavaScriptFromString:loadString];
        }
    }
    
    else if ([[userInfo host] isEqualToString:@"signin"])
    {
        NSArray     *userData = [userInfo pathComponents];
        NSString    *strEmailMatchstring =   @"\\b([a-zA-Z0-9%_.+\\-]+)@([a-zA-Z0-9.\\-]+?\\.[a-zA-Z]{2,6})\\b";
        
        if ([userData count] == 3)
        {
            if (![userData[1] isMatchedByRegex:strEmailMatchstring])
            {
                UIAlertView *objAlert = [[UIAlertView alloc] initWithTitle:@"Error!" message:NSLocalizedString(@"Enter a valid e-mail address",nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Try Again",nil];
                [objAlert show];
                [objAlert release];
            }
            else
            {
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                hud.labelText = NSLocalizedString(@"Attaching device...",nil);
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
                {
                    [self addDeviceForCurrentUser:userData];
                    
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
            }
        }
        else
        {
            UIAlertView *objAlert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Enter a valid e-mail/password" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Try Again",nil];
            [objAlert show];
            [objAlert release];
        }
        
    }

    else if ([[userInfo host] isEqualToString:@"signup"])
    {
        //[wizardWebView stringByEvaluatingJavaScriptFromString:@"Wizard.load('error')"];
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Access Denied",nil) message:@"Only registered users"delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alertView show];
		[alertView release];
        
    }
    
    else if ([[userInfo host] isEqualToString:@"activeView"])
    {
        NSArray     *userData = [userInfo pathComponents];
        [[NSUserDefaults standardUserDefaults] setInteger:[userData[1] intValue] forKey:@"currentViewWizard"];
    }
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    /*
    NSString *url_ = @"foo://name.com:8080/12345;param?foo=1&baa=2#fragment";
    NSURL *url = [NSURL URLWithString:url_];
    
    NSLog(@"scheme: %@", [url scheme]);
    NSLog(@"host: %@", [url host]);
    NSLog(@"port: %@", [url port]);
    NSLog(@"path: %@", [url path]);
    NSLog(@"path components: %@", [url pathComponents]);
    NSLog(@"parameterString: %@", [url parameterString]);
    NSLog(@"query: %@", [url query]);
    NSLog(@"fragment: %@", [url fragment]);
     
     TEST
     command://callfunction/parameter1/parameter2?parameter3=value
    */
    
    NSURL *URL = [request URL];
    if ([[URL scheme] isEqualToString:@"command"])
    {
        [self callJavaScriptMethod:URL];
        return NO;
    }
    else
        return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    PreyLogMessage(@"Wizard Controller", 10, @"Did StartLoadUIWebview");
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    PreyLogMessage(@"Wizard Controller", 10, @"Did FinishLoadUIWebView");
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    PreyLogMessage(@"Wizard Controller", 10, @"Did FailLoadUIWebView = %@", error);
}

@end
