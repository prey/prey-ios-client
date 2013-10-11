//
//  WizardController.h
//  Prey
//
//  Created by Javier Cala Uribe on 8/07/13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "Location.h"

@interface WizardController : UIViewController <UIWebViewDelegate, MBProgressHUDDelegate>
{
    UIWebView *wizardWebView;
    Location *location;
}

@property (nonatomic,retain)  UIWebView *wizardWebView;

@end
