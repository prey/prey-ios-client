//
//  PreferencesController.h
//  Prey
//
//  Created by Carlos Yaconi on 29/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
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
	UISwitch *missing;
	BOOL pickerShowed;
    MBProgressHUD *HUD;
	
}

- (void) setupNavigatorForPicker:(BOOL)showed withSelector:(SEL)action;

@end
