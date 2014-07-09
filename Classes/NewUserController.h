//
//  NewUserController.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 01/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//


#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "RegexKitLite.h"


@interface NewUserController : UITableViewController <UITextFieldDelegate, MBProgressHUDDelegate>
{
    UITextField *name;
    UITextField *email;
    UITextField *password;
    UITextField *repassword;
    UITableViewCell *buttonCell;
    
    MBProgressHUD *HUD;
    NSString *strEmailMatchstring;
    BOOL enableToSubmit;
}

@property (nonatomic) UITextField *name;
@property (nonatomic) UITextField *email;
@property (nonatomic) UITextField *password;
@property (nonatomic) UITextField *repassword;
@property (nonatomic) UITableViewCell *buttonCell;
@property (nonatomic) NSString *strEmailMatchstring;

- (void) showCongratsView:(id) congratsText;


@end