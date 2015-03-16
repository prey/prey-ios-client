//
//  UserController.h
//  Prey
//
//  Created by Javier Cala Uribe on 16/7/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RegexKitLite.h"
#import "MBProgressHUD.h"
#import "User.h"
#import "Device.h"
#import "PreyConfig.h"
#import "GAITrackedViewController.h"
#import "CongratulationsController.h"
#import "PreyAppDelegate.h"
#import "Constants.h"

@interface UserController : GAITrackedViewController <UITextFieldDelegate, MBProgressHUDDelegate>
{
    UITextField *name;
    UITextField *email;
    UITextField *password;
    UIButton *btnNewUser;
    UIImageView *preyImage;
    
    NSString *strEmailMatchstring;
    
    UITableView *infoInputs;
    UIScrollView *scrollView;
    MBProgressHUD *HUD;    
}

@property (nonatomic) UITextField *name;
@property (nonatomic) UITextField *email;
@property (nonatomic) UITextField *password;
@property (nonatomic) UIButton *btnNewUser;
@property (nonatomic) UIImageView *preyImage;
@property (nonatomic) NSString *strEmailMatchstring;
@property (nonatomic) UITableView *infoInputs;
@property (nonatomic) UIScrollView *scrollView;

- (void) showCongratsView:(id) congratsText;
- (void) addDeviceForCurrentUser;
- (CGRect)returnRectToInputsTable;
- (UIFont*)returnFontToChange:(NSString *)fontString;
- (void)keyboardWillShow;

@end