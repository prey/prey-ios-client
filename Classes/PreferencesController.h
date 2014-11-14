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
#import "MBProgressHUD.h"
#import "GAITrackedViewController.h"

#define kDetachAction  1;

@interface PreferencesController : GAITrackedViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;    
    UITableView *tableViewInfo;
    BOOL currentCamouflageMode;
}

@property (nonatomic) UITableView *tableViewInfo;

@end