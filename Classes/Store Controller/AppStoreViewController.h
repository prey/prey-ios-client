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
#import "UIWebViewController.h"

@interface AppStoreViewController : GAITrackedViewController <UIWebViewControllerDelegate>
{
    MBProgressHUD *HUD;
}

@property (nonatomic) IBOutlet UIButton *yearButton;
@property (nonatomic) IBOutlet UIImageView *iconPro;
@property (nonatomic) IBOutlet UILabel *titleView;
@property (nonatomic) IBOutlet UILabel *descriptionTxt;
@property (nonatomic) IBOutlet UILabel *planName;
@property (nonatomic) BOOL isGeofencingView;

- (IBAction)buySubscription:(id)sender;
- (void)changeLanguageTextForGeofencing;
- (void)changeLanguageTextForUpgradePro;

@end
