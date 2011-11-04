//
//  LoginController.h
//  Prey
//
//  Created by Carlos Yaconi on 29/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
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
}

@property (nonatomic, retain) IBOutlet UIImageView *loginImage;
@property (nonatomic, retain) IBOutlet UITextField *loginPassword;

- (IBAction) checkLoginPassword: (id) sender;

@end
