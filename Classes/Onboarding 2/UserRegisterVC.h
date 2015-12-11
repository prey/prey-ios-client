//
//  UserRegisterVC.h
//  Prey
//
//  Created by Javier Cala Uribe on 11/12/15.
//  Copyright © 2015 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GAITrackedViewController.h"
#import "PreyAppDelegate.h"
#import "MBProgressHUD.h"
#import "PreyConfig.h"
#import "User.h"
#import "Device.h"
#import "Constants.h"

static NSString *const EMAIL_REG_EXP = @"\\b([a-zA-Z0-9%_.+\\-]+)@([a-zA-Z0-9.\\-]+?\\.[a-zA-Z]{2,21})\\b";

@interface UserRegisterVC : GAITrackedViewController <UITextFieldDelegate>
{
    CGFloat         offsetForKeyboard;
    MBProgressHUD   *HUD;
}

@property (nonatomic) CGFloat offsetForKeyboard;


- (BOOL)validateString:(NSString *)string withPattern:(NSString *)pattern;
- (void)showCongratsView:(id)congratsText;

@end
