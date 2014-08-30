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

@interface LoginController : GAITrackedViewController <UIWebViewControllerDelegate,MBProgressHUDDelegate, UIAlertViewDelegate> {
@private
	UITextField *loginPassword;
	MBProgressHUD *HUD;
    UIImageView *loginImage;
    UIScrollView *scrollView;
    UIImageView *nonCamuflageImage;
    UIImageView *preyLogo;
    UIImageView *buttn;
    UILabel *devReady;
    UILabel *detail;
    UIButton *loginButton;
}

@property (nonatomic) IBOutlet UIImageView *loginImage;
@property (nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) IBOutlet UITextField *loginPassword;
@property (nonatomic) IBOutlet UIImageView *nonCamuflageImage;
@property (nonatomic) IBOutlet UIImageView *buttn;
@property (nonatomic) IBOutlet UIImageView *preyLogo;
@property (nonatomic) IBOutlet UILabel *devReady;
@property (nonatomic) IBOutlet UILabel *detail;
@property (nonatomic) IBOutlet UILabel *tipl;
@property (nonatomic) IBOutlet UIButton *loginButton;

- (IBAction) checkLoginPassword: (id) sender;

@end
