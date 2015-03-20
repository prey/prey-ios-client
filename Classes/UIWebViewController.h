//
//  UIWebViewController.h
//  
//
//  Created by Javier Cala Uribe on 26/03/12.
//  Copyright (c) 2012 . Any rights reserved.
//

#import <UIKit/UIKit.h>
#import "GAITrackedViewController.h"
#import "MBProgressHUD.h"

@class UIWebViewController;

@protocol UIWebViewControllerDelegate <NSObject>

@end
    
@interface UIWebViewController : GAITrackedViewController <UIWebViewDelegate>
{
    MBProgressHUD                               *HUD;
	UIWebView									*webViewPage;
	UINavigationBar								*navBar;
	
	id <UIWebViewControllerDelegate>            delegate;
    
	BOOL										loading, firstLoad;
    UIButton                                    *cancelButton;
}


@property (nonatomic, readwrite) id <UIWebViewControllerDelegate> delegate;
@property (nonatomic, readonly) UINavigationBar *navigationBar;
@property (nonatomic) UIButton *cancelButton;

+ (UIWebViewController *)controllerToEnterdelegate:(id<UIWebViewControllerDelegate>)delegate setURL:(NSString*)stringURL;

@end
