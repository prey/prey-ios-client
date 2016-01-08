//
//  WizardController.m
//  Prey
//
//  Created by Javier Cala Uribe on 8/07/13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "PreyTourWebView.h"
#import "PreyAppDelegate.h"
#import "PreyConfig.h"
#import "Constants.h"


@implementation PreyTourWebView

@synthesize tourWebView, cancelButton;

#pragma mark Init

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"PreyTourWeb"]];
    
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    tourWebView = [[UIWebView alloc] initWithFrame:appDelegate.window.frame];
    [tourWebView loadRequest:[NSURLRequest requestWithURL:url]];
    [tourWebView setDelegate:self];
    [tourWebView setBackgroundColor:[UIColor blackColor]];
    tourWebView.scrollView.alwaysBounceVertical = NO;

    [self.view addSubview:tourWebView];
    
    CGRect cancelBtnFrame = (IS_IPAD) ? CGRectMake(680, 20, 72, 64) : CGRectMake(270, 7, 38, 34);
    
    cancelButton = [[UIButton alloc] initWithFrame:cancelBtnFrame];
    [cancelButton setBackgroundColor:[UIColor clearColor]];
    [cancelButton setBackgroundImage:[UIImage imageNamed:@"close_off"] forState:UIControlStateNormal];
    [cancelButton setBackgroundImage:[UIImage imageNamed:@"close_on"] forState:UIControlStateHighlighted];
    [cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancelButton];
}

- (void)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UIWebViewDelegate

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

    if ([[URL scheme] isEqualToString:@"closewebview"])
    {
        [self cancel:nil];        
        return NO;
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    PreyLogMessage(@"Tour Controller", 10, @"Did StartLoadUIWebview");
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    PreyLogMessage(@"Tour Controller", 10, @"Did FinishLoadUIWebView");
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    PreyLogMessage(@"Tour Controller", 10, @"Did FailLoadUIWebView = %@", error);
}

@end
