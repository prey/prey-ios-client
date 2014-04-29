//
//  StoreControllerViewController.h
//  Prey
//
//  Created by Diego Torres on 3/12/12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import "MBProgressHUD.h"

@interface StoreControllerViewController : UITableViewController <UIWebViewDelegate, MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
}

@end
