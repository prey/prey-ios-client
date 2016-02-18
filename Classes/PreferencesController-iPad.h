//
//  PreferencesController-iPad.h
//  Prey
//
//  Created by Javier Cala Uribe on 17/02/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PreferencesController.h"
#import "DeviceMapController.h"
#import "RecoveriesViewController.h"

@interface PreferencesController_iPad : PreferencesController <UIWebViewDelegate,UITableViewDelegate,UIActionSheetDelegate>

@property (nonatomic, strong) IBOutlet UIView *leftView;
@property (nonatomic, strong) IBOutlet UIView *rightView;

@property (nonatomic, strong) UIViewController *leftViewController;
@property (nonatomic, strong) DeviceMapController *mapController;
@property (nonatomic, strong) RecoveriesViewController *recoveriesViewController;

@end
