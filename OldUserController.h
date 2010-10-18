//
//  OldUserController.h
//  Prey
//
//  Created by Carlos Yaconi on 01/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SetupControllerTemplate.h"

@interface OldUserController : SetupControllerTemplate  {
	
	UITextField *email;
	UITextField *password;

}

@property (nonatomic, retain) IBOutlet UITextField *email;
@property (nonatomic, retain) IBOutlet UITextField *password;

@end
