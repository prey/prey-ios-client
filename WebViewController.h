//
//  WebView.h
//  Prey
//
//  Created by Carlos Yaconi on 16/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WebViewController : UIViewController {
    IBOutlet UIWebView *webView;
}

@property (nonatomic, retain) UIWebView *webView;

@end
