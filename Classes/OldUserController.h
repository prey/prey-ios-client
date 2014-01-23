//
//  OldUserController.h
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

@interface OldUserController : UITableViewController <UITextFieldDelegate, MBProgressHUDDelegate>
{
    UITextField *email;
    UITextField *password;
    UITableViewCell *buttonCell;
    
    MBProgressHUD *HUD;
    NSString *strEmailMatchstring;
    BOOL enableToSubmit;
}

@property (nonatomic, retain) UITextField *email;
@property (nonatomic, retain) UITextField *password;
@property (nonatomic, retain) UITableViewCell *buttonCell;
@property (nonatomic, retain) NSString *strEmailMatchstring;

- (void) activatePreyService;
- (void) showCongratsView:(id) congratsText;


@end