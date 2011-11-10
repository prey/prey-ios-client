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
#import "SetupControllerTemplate.h"


@interface NewUserController : SetupControllerTemplate <UITextFieldDelegate> {
	UITextField *name;
	UITextField *email;
	UITextField *password;
	UITextField *repassword;
}

@end
