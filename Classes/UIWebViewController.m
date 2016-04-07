//
//  UIWebViewController.m
//  
//
//  Created by Javier Cala Uribe on 26/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "PreyAppDelegate.h"
#import "UIWebViewController.h"
#import "Constants.h"

#define kCancelBtn_PosX         268.0
#define kCancelBtn_PosY         7.0
#define kCancelBtn_Width        38.0
#define kCancelBtn_Height       34.0

@implementation UIWebViewController
@synthesize delegate, navigationBar, cancelButton;

- (void) viewWillAppear:(BOOL)animated
{
    if (!IS_IPAD)
        [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    if (!IS_IPAD)
        [self.navigationController setNavigationBarHidden:NO animated:animated];

    [super viewWillDisappear:animated];
}


+ (UIWebViewController *)controllerToEnterdelegate:(id<UIWebViewControllerDelegate>)delegate setURL:(NSString*)stringURL
{
	UIWebViewController *controller = [[UIWebViewController alloc] initWithURL:stringURL];
	controller.delegate = delegate;
	return controller;
}

+ (UIWebViewController *)controllerToEnterdelegate:(id<UIWebViewControllerDelegate>)delegate setURL:(NSString*)stringURL withParameters:(NSString*)params
{
    UIWebViewController *controller = [[UIWebViewController alloc] initWithURL:stringURL withParams:params];
    controller.delegate = delegate;
    return controller;
}

- (id)initWithURL:(NSString*)stringURL withParams:(NSString*)params
{
    self = [super init];
    if (self)
    {
        CGRect frameWebView = [[UIScreen mainScreen] bounds];
        if (IS_IPAD)
            frameWebView = CGRectMake(0, 44, frameWebView.size.width, frameWebView.size.height-44);
        
        webViewPage = [[UIWebView alloc] initWithFrame:frameWebView];
        self.view.backgroundColor = [UIColor blackColor];
        webViewPage.backgroundColor = [UIColor blackColor];
        webViewPage.delegate = self;
        webViewPage.multipleTouchEnabled = YES;
        [webViewPage setScalesPageToFit:YES];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:stringURL]];
        [request setHTTPMethod: @"POST"];
        [request setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
        [webViewPage loadRequest:request];
    }
    return self;
}

- (id)initWithURL:(NSString*)stringURL
{
    self = [super init];
	if (self) 
    {
        CGRect frameWebView = [[UIScreen mainScreen] bounds];
        if (IS_IPAD)
            frameWebView = CGRectMake(0, 44, frameWebView.size.width, frameWebView.size.height-44);
        
        webViewPage = [[UIWebView alloc] initWithFrame:frameWebView];
		self.view.backgroundColor = [UIColor blackColor];
		webViewPage.backgroundColor = [UIColor blackColor];
        webViewPage.delegate = self;
        webViewPage.multipleTouchEnabled = YES;
        [webViewPage setScalesPageToFit:YES];
        
        NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:stringURL]]; 
		[webViewPage loadRequest:theRequest];
	}
	return self;
}

#pragma mark Actions
- (void) denied
{
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) // Check iOS 5.0 or later
        [self dismissViewControllerAnimated:YES completion:NULL];
    else
        [self dismissModalViewControllerAnimated:YES];
}

- (void) cancel: (id) sender
{
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) // Check iOS 5.0 or later
        [self dismissViewControllerAnimated:YES completion:NULL];
    else
        [self dismissModalViewControllerAnimated:YES];
}

#pragma mark View Controller Stuff
- (void) loadView
{
    self.screenName = @"Control Panel Web";
    
	[super loadView];
    
    CGRect frameView = [[UIScreen mainScreen] bounds];
    if (IS_IPAD)
        frameView = CGRectMake(0, 44, frameView.size.width, frameView.size.height-44);

    
    self.view = [[UIView alloc] initWithFrame:frameView];
	[self.view addSubview:webViewPage];
    
    [self.view setBackgroundColor:[UIColor blackColor]];

    if (IS_IPAD)
    {
        navBar = [[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, 768, 44)];
        navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        [self.view addSubview:navBar];
    }
    
	UINavigationItem  *navItem = [[UINavigationItem alloc] initWithTitle: NSLocalizedString(@"Prey Control Panel", nil)];
	navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                               target: self action: @selector(cancel:)];
	
	[navBar pushNavigationItem:navItem animated: NO];
    
    
    if (!IS_IPAD)
    {
        cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(kCancelBtn_PosX, kCancelBtn_PosY, kCancelBtn_Width, kCancelBtn_Height)];
        [cancelButton setBackgroundColor:[UIColor clearColor]];
        [cancelButton setBackgroundImage:[UIImage imageNamed:@"close_off"] forState:UIControlStateNormal];
        [cancelButton setBackgroundImage:[UIImage imageNamed:@"close_on"] forState:UIControlStateHighlighted];
        [cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:cancelButton];
    }
}


#pragma mark WebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    NSLog(@"Error Loading Web: %@",[error description]);
    [MBProgressHUD hideHUDForView:webView animated:NO];
    
    UIAlertView *alerta = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"We have a situation!",nil)
                                                     message:NSLocalizedString(@"Error loading web, please try again.",nil)
                                                    delegate:nil
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
    [alerta show];
}

- (void) webViewDidFinishLoad: (UIWebView *) webView
{
    NSLog(@"Finish Load Web");
    [MBProgressHUD hideHUDForView:webView animated:NO];


    
    // Hide ViewMap class
    [webView stringByEvaluatingJavaScriptFromString:@"var viewMapBtn = document.getElementsByClassName('btn btn-block btn-border js-toggle-report-map')[1]; viewMapBtn.style.display='none';"];
    
    // Hide addDeviceBtn
    [webView stringByEvaluatingJavaScriptFromString:@"var addDeviceBtn = document.getElementsByClassName('btn btn-success js-add-device pull-right')[0]; addDeviceBtn.style.display='none';"];
    
    // Hide accountPlans
    [webView stringByEvaluatingJavaScriptFromString:@"var accountPlans = document.getElementById('account-plans'); accountPlans.style.display='none';"];

    // Hide print option
    [webView stringByEvaluatingJavaScriptFromString:@"var printBtn = document.getElementById('print'); printBtn.style.display='none';"];
}

- (void) webViewDidStartLoad: (UIWebView *) webView {
    NSLog(@"Start Load Web");
    HUD = [MBProgressHUD showHUDAddedTo:webView animated:YES];
    HUD.label.text = NSLocalizedString(@"Please wait",nil);
}


- (BOOL) webView: (UIWebView *) webView shouldStartLoadWithRequest: (NSURLRequest *) request navigationType: (UIWebViewNavigationType) navigationType {
    
	NSData				*data = [request HTTPBody];
	char				*raw = data ? (char *) [data bytes] : "";

    NSLog(@"Should Load Web: %@", [[request URL] host]);
    
    if ([[[request URL] host] isEqualToString:@"secure.worldpay.com"])
    {
        UIAlertView *alerta = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information",nil)
                                                         message:NSLocalizedString(@"This service is not available from here. Please go to 'Manage Prey Settings' from the main menu in the app.",nil)
                                                        delegate:nil
                                               cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alerta show];
        
        return NO;
    }
    
    if ([[[request URL] host] isEqualToString:@"help.preyproject.com"])
    {
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString:@"https://help.preyproject.com"]];
        
        return NO;
    }
    
    if ([[[request URL] host] isEqualToString:@"panel.preyproject.com"])
    {
        // Hide print option
        [webView stringByEvaluatingJavaScriptFromString:@"var printBtn = document.getElementById('print'); printBtn.style.display='none';"];
    }
    

    // Google Maps apps and large picture
    if ( ([[[request URL] host] isEqualToString:@"s3.amazonaws.com"]) || ([[[request URL] host] isEqualToString:@"www.google.com"]) )
    {
        [[UIApplication sharedApplication] openURL:[request URL]];        
        return NO;
    }
    
	if (raw && strstr(raw, "cancel=")) {
		[self denied];
		return NO;
	}
    
	return YES;
}

@end
