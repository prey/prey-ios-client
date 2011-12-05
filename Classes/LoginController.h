//
//  LoginController.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 29/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <UIKit/UIKit.h>
#import "PreferencesController.h"
#import "MBProgressHUD.h"

#define kOFFSET_FOR_KEYBOARD 150.0

@interface LoginController : UIViewController <MBProgressHUDDelegate> {
@private
    int movementDistance;

	UITextField *loginPassword;
	MBProgressHUD *HUD;
    UIImageView *loginImage;
    UIImageView *nonCamuflageImage;
    UIImageView *preyLogo;
    UIImageView *buttn;
    UILabel *devReady;
    UILabel *detail;
    UIButton *loginButton;
}

@property (nonatomic, retain) IBOutlet UIImageView *loginImage;
@property (nonatomic, retain) IBOutlet UITextField *loginPassword;
@property (nonatomic, retain) IBOutlet UIImageView *nonCamuflageImage;
@property (nonatomic, retain) IBOutlet UIImageView *buttn;
@property (nonatomic, retain) IBOutlet UIImageView *preyLogo;
@property (nonatomic, retain) IBOutlet UILabel *devReady;
@property (nonatomic, retain) IBOutlet UILabel *detail;
@property (nonatomic, retain) IBOutlet UIButton *loginButton;

- (IBAction) checkLoginPassword: (id) sender;

@end
