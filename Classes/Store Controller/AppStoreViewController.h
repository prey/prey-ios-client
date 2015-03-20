//
//  AppStoreViewController.h
//  Prey
//
//  Created by Javier Cala Uribe on 5/6/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GAITrackedViewController.h"
#import <StoreKit/StoreKit.h>
#import "MBProgressHUD.h"

@interface AppStoreViewController : GAITrackedViewController
{
    MBProgressHUD *HUD;
}

@property (nonatomic) IBOutlet UIButton *yearButton;

- (IBAction)buySubscription:(id)sender;

@end
