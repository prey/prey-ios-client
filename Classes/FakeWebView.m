//
//  FakeWebView.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 23/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "FakeWebView.h"


@implementation FakeWebView


- (void) openUrl: (NSString *) url showingLoadingText: (NSString *) _spinnerText {
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [self loadRequest:requestObj];
    spinnerText = _spinnerText;
}

#pragma mark -
#pragma mark WebView delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    //HUD = [[MBProgressHUD alloc] initWithView:webView];
    HUD = [MBProgressHUD showHUDAddedTo:webView animated:YES];
    HUD.delegate = self;
    HUD.labelText = spinnerText;
    //[webView addSubview:HUD];
    HUD.removeFromSuperViewOnHide=YES;
    [HUD show:YES];
    return YES;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    BOOL ok = [MBProgressHUD hideHUDForView:webView animated:YES];
    PreyLogMessage(@"FakeWebView", 10, @"Fake web did finish loading. Hidden?: %@", ok ? @"YES" : @"NO");
    [webView becomeFirstResponder];
}


#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden {
    // Remove HUD from screen when the HUD was hidded
    PreyLogMessage(@"FakeWebView", 10, @"HUB was hidden");
    //[HUD removeFromSuperview];
    //[HUD release];
	
}
@end
