//
//  PreferencesController.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 29/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import "MBProgressHUD.h"
#import "GAITrackedViewController.h"

@interface PreferencesController : GAITrackedViewController <UIWebViewDelegate,UITableViewDataSource,UITableViewDelegate,UIActionSheetDelegate>
{
    MBProgressHUD *HUD;    
    UITableView *tableViewInfo;
    BOOL currentCamouflageMode;
    
    NSArray *textsToShareArrayEN;
    NSArray *textsToShareArrayES;
}

@property (nonatomic) UITableView *tableViewInfo;
@property (nonatomic, strong) NSArray *textsToShareArrayEN;
@property (nonatomic, strong) NSArray *textsToShareArrayES;

- (void)postToSocialFramework:(NSString *)socialNetwork;
- (void)showAppStoreVC;
- (void)showGeofenceMapVC;
- (void)showDetachDeviceAction;

@end