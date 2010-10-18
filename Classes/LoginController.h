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

@interface LoginController : UIViewController <MBProgressHUDDelegate> {
	
	UITextField *loginPassword;
	MBProgressHUD *HUD;
}

@property (nonatomic, retain) IBOutlet UITextField *loginPassword;

- (IBAction) checkLoginPassword: (id) sender;

@end
