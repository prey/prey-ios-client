//
//  WizardController.h
//  Prey
//
//  Created by Javier Cala Uribe on 8/07/13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "UIWebViewController.h"

@interface PreyTourWebView : UIViewController <UIWebViewControllerDelegate, UIWebViewDelegate, MBProgressHUDDelegate>
{
    UIWebView       *tourWebView;
    MBProgressHUD   *HUD;
    UIButton        *cancelButton;
}

@property (nonatomic) UIWebView *tourWebView;
@property (nonatomic) UIButton  *cancelButton;

@end
