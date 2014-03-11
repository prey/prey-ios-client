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
#import "AccuracyManager.h"
#import "DelayManager.h"
#import "MBProgressHUD.h"

#define kDetachAction  1;

@interface PreferencesController : UITableViewController <UIActionSheetDelegate, MBProgressHUDDelegate>  {
    UIActivityIndicatorView *cLoadingView;
	AccuracyManager *accManager;
	DelayManager *delayManager;
    BOOL pickerShowed;
    MBProgressHUD *HUD;
    
}

@property (nonatomic, retain) AccuracyManager *accManager;
@property (nonatomic, retain) DelayManager *delayManager;

- (void) setupNavigatorForPicker:(BOOL)showed withSelector:(SEL)action;

@end