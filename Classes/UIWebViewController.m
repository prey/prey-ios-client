//
//  UIWebViewController.m
//  
//
//  Created by Javier Cala Uribe on 26/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "UIWebViewController.h"
#import "Constants.h"

#define kCancelBtn_PosX         268.0
#define kCancelBtn_PosY         7.0
#define kCancelBtn_Width        38.0
#define kCancelBtn_Height       34.0

@implementation UIWebViewController
@synthesize delegate = _delegate, navigationBar = _navBar, cancelButton;

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
	UIWebViewController     *controller = [[UIWebViewController alloc] initWithURL:stringURL];
	controller.delegate = delegate;
	return controller;
}

- (id) initWithURL:(NSString*)stringURL
{
    self = [super init];
	if (self) 
    {
        CGRect frameWebView = [[UIScreen mainScreen] bounds];
        if (IS_IPAD)
            frameWebView = CGRectMake(0, 44, frameWebView.size.width, frameWebView.size.height-44);
        
		_firstLoad = YES;
        _webView = [[UIWebView alloc] initWithFrame:frameWebView];
		_webView.alpha = 0.0;
		_webView.delegate = self;
        _webView.multipleTouchEnabled = YES;
        [_webView setScalesPageToFit:YES];
        
        NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:stringURL]]; 
		[_webView loadRequest:theRequest];
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
	[self.view addSubview:_webView];
    
    [self.view setBackgroundColor:[UIColor blackColor]];

    if (IS_IPAD)
    {
        _navBar = [[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, 768, 44)];
        _navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        [self.view addSubview:_navBar];
    }
	
	_blockerView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 200, 70)];
	_blockerView.backgroundColor = [UIColor colorWithWhite: 0.0 alpha: 0.8];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
      	_blockerView.center = CGPointMake(768 / 2, 1024 / 2);
    else
        _blockerView.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
    
    _blockerView.alpha = 0.0;
	_blockerView.clipsToBounds = YES;
	if ([_blockerView.layer respondsToSelector: @selector(setCornerRadius:)]) [(id) _blockerView.layer setCornerRadius: 10];
	
	UILabel	*label = [[UILabel alloc] initWithFrame: CGRectMake(0, 5, _blockerView.bounds.size.width, 18)];
	label.text = NSLocalizedString(@"Please wait",nil);
	label.backgroundColor = [UIColor clearColor];
	label.textColor = [UIColor whiteColor];
	label.textAlignment = UITextAlignmentCenter;
	label.font = [UIFont boldSystemFontOfSize: 15];
	[_blockerView addSubview: label];
	
	UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite];
	
	spinner.center = CGPointMake(_blockerView.bounds.size.width / 2, _blockerView.bounds.size.height / 2 + 10);
	[_blockerView addSubview: spinner];
	[self.view addSubview: _blockerView];
	[spinner startAnimating];
	
	UINavigationItem  *navItem = [[UINavigationItem alloc] initWithTitle: NSLocalizedString(@"Prey Control Panel", nil)];
	navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                               target: self action: @selector(cancel:)];
	
	[_navBar pushNavigationItem:navItem animated: NO];
    
    
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


- (void) didRotateFromInterfaceOrientation: (UIInterfaceOrientation) fromInterfaceOrientation {
	_blockerView.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
}

#pragma mark Webview Delegate stuff
- (void) webViewDidFinishLoad: (UIWebView *) webView
{
    _loading = NO;

	if (_firstLoad) {
		[_webView performSelector: @selector(stringByEvaluatingJavaScriptFromString:) withObject: @"window.scrollBy(0,200)" afterDelay: 0];
		_firstLoad = NO;
	}
	
	[UIView beginAnimations: nil context: nil];
	_blockerView.alpha = 0.0;
	[UIView commitAnimations];
	
	if ([_webView isLoading]) {
		_webView.alpha = 0.0;
	} else {
		_webView.alpha = 1.0;
	}
    
    // Hide addDeviceBtn
    [webView stringByEvaluatingJavaScriptFromString:@"var addDeviceBtn = document.getElementsByClassName('btn btn-success js-add-device pull-right')[0]; addDeviceBtn.style.display='none';"];
}

- (void) webViewDidStartLoad: (UIWebView *) webView {
	_loading = YES;
	[UIView beginAnimations: nil context: nil];
	_blockerView.alpha = 1.0;
	[UIView commitAnimations];
}


- (BOOL) webView: (UIWebView *) webView shouldStartLoadWithRequest: (NSURLRequest *) request navigationType: (UIWebViewNavigationType) navigationType {
	NSData				*data = [request HTTPBody];
	char				*raw = data ? (char *) [data bytes] : "";
	
    if ([[[request URL] host] isEqualToString:@"secure.worldpay.com"])
    {
        UIAlertView *alerta = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information",nil)
                                                         message:NSLocalizedString(@"This service is not available from here. Please go to 'Manage Prey Settings' from the main menu in the app.",nil)
                                                        delegate:nil
                                               cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alerta show];
        
        return NO;
    }
    
	if (raw && strstr(raw, "cancel=")) {
		[self denied];
		return NO;
	}
	if (navigationType != UIWebViewNavigationTypeOther) _webView.alpha = 0.1;
	return YES;
}

@end
