//
//  OldUserController.h
//  Prey
//
//  Created by Carlos Yaconi on 01/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SetupControllerTemplate.h"



//@interface OldUserController : SetupControllerTemplate < UITableViewDelegate, UITableViewDataSource > {
@interface OldUserController : SetupControllerTemplate <UITextFieldDelegate>{
	
	UITextField *email;
	UITextField *password;


}

@end
