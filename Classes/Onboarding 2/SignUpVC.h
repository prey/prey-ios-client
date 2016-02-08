//
//  SignUpVC.h
//  Prey
//
//  Created by Javier Cala Uribe on 11/12/15.
//  Copyright © 2015 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserRegisterVC.h"

@interface SignUpVC : UserRegisterVC

@property (nonatomic) IBOutlet UILabel *subtitleView;
@property (nonatomic) IBOutlet UILabel *titleView;
@property (nonatomic) IBOutlet UITextField *usernameField;
@property (nonatomic) IBOutlet UITextField *emailField;
@property (nonatomic) IBOutlet UITextField *passwordField;
@property (nonatomic) IBOutlet UIButton *createAccountBtn;
@property (nonatomic) IBOutlet UIButton *signInBtn;

@end
