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

@interface UIWebViewController ()
@property (nonatomic, readwrite) UIInterfaceOrientation orientation;
@end

@implementation UIWebViewController
@synthesize delegate = _delegate, navigationBar = _navBar, orientation = _orientation;

+ (UIWebViewController *) controllerToEnterdelegate: (id <UIWebViewControllerDelegate>) delegate forOrientation: (UIInterfaceOrientation)theOrientation setURL:(NSString*)stringURL
{
	UIWebViewController     *controller = [[UIWebViewController alloc] initOrientation:theOrientation setURL:stringURL];
	controller.delegate = delegate;
	return controller;
}

+ (UIWebViewController *) controllerToEnterdelegate: (id <UIWebViewControllerDelegate>) delegate setURL:(NSString*)stringURL{
	return [UIWebViewController controllerToEnterdelegate: delegate forOrientation: UIInterfaceOrientationPortrait setURL:stringURL];
}


- (id) initOrientation:(UIInterfaceOrientation)theOrientation setURL:(NSString*)stringURL
{
    self = [super init];
	if (self) 
    {
		self.orientation = theOrientation;
		_firstLoad = YES;
		
		if (UIInterfaceOrientationIsLandscape( self.orientation ) ){
			_webView = [[UIWebView alloc] initWithFrame: CGRectMake(0, 32, 480, 288)];
		}
		else{
			_webView = [[UIWebView alloc] initWithFrame: CGRectMake(0, 44, 320, 416)];
		}
		
		_webView.alpha = 0.0;
		_webView.delegate = self;
		_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _webView.multipleTouchEnabled = YES;
        [_webView setScalesPageToFit:YES];
        
        NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:stringURL]]; 
		[_webView loadRequest: theRequest];
	}
	return self;
}

//=============================================================================================================================
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

//=============================================================================================================================
#pragma mark View Controller Stuff
- (void) loadView
{
    self.screenName = @"Control Panel Web";
    
	[super loadView];
    
	if ( UIInterfaceOrientationIsLandscape( self.orientation ) ) 
    {
		self.view = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 480, 288)];
		_navBar = [[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, 480, 32)];
	}
    else 
    {
		self.view = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 320, 416)];
		_navBar = [[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, 320, 44)];
	}
    
	_navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
	[self.view addSubview: _webView];
	[self.view addSubview: _navBar];
	
	_blockerView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 200, 60)];
	_blockerView.backgroundColor = [UIColor colorWithWhite: 0.0 alpha: 0.8];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
      	_blockerView.center = CGPointMake(768 / 2, 1024 / 2);
    else
        _blockerView.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
    
    _blockerView.alpha = 0.0;
	_blockerView.clipsToBounds = YES;
	if ([_blockerView.layer respondsToSelector: @selector(setCornerRadius:)]) [(id) _blockerView.layer setCornerRadius: 10];
	
	UILabel	*label = [[UILabel alloc] initWithFrame: CGRectMake(0, 5, _blockerView.bounds.size.width, 15)];
	label.text = NSLocalizedString(@"Please Wait…", nil);
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
	
	//[_navBar setBarStyle:UIBarStyleBlackOpaque];
	[_navBar pushNavigationItem:navItem animated: NO];
}


- (void) didRotateFromInterfaceOrientation: (UIInterfaceOrientation) fromInterfaceOrientation {
	self.orientation = self.interfaceOrientation;
	_blockerView.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
}

//=============================================================================================================================
#pragma mark Webview Delegate stuff
- (void) webViewDidFinishLoad: (UIWebView *) webView {
    
    
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
	
	if (raw && strstr(raw, "cancel=")) {
		[self denied];
		return NO;
	}
	if (navigationType != UIWebViewNavigationTypeOther) _webView.alpha = 0.1;
	return YES;
}

@end
