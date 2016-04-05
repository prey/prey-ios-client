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
#import "MBProgressHUD.h"
#import "UIWebViewController.h"
#import "GAITrackedViewController.h"


#define kOFFSET_FOR_KEYBOARD 150.0

@interface LoginController : GAITrackedViewController <UIWebViewControllerDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>
{
    UIImageView     *loginImage;
    UIScrollView    *scrollView;
	UITextField     *loginPassword;
    UIImageView     *nonCamuflageImage;
    UIImageView     *preyLogo;
    UILabel         *devReady;
    UILabel         *detail;
    UILabel         *tipl;
    UIButton        *loginButton;
    UIButton        *panelButton;
    UIButton        *settingButton;
    MBProgressHUD   *HUD;
    BOOL            hideLogin;
}

@property (nonatomic) IBOutlet UIImageView *loginImage;
@property (nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic) IBOutlet UITextField *loginPassword;
@property (nonatomic) IBOutlet UIImageView *nonCamuflageImage;
@property (nonatomic) IBOutlet UIImageView *preyLogo;
@property (nonatomic) IBOutlet UILabel *devReady;
@property (nonatomic) IBOutlet UILabel *detail;
@property (nonatomic) IBOutlet UILabel *tipl;
@property (nonatomic) IBOutlet UIButton *loginButton;
@property (nonatomic) IBOutlet UIButton *panelButton;
@property (nonatomic) IBOutlet UIButton *settingButton;

@property (nonatomic) IBOutlet UILabel *remoteControlLbl;
@property (nonatomic) IBOutlet UILabel *preyAccountLbl;
@property (nonatomic) IBOutlet UILabel *configureLbl;
@property (nonatomic) IBOutlet UILabel *preySettingsLbl;
@property (nonatomic) BOOL hideLogin;

- (IBAction)checkLoginPassword:(id)sender;
- (IBAction)goToControlPanel:(UIButton *)sender;
- (IBAction)goToSettings:(UIButton *)sender;
- (void)checkPassword;
- (void)hideKeyboard;
- (void)animateTextField:(UITextField*)textField up:(BOOL)up;

@end
