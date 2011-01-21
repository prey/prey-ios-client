//
//  SetupControllerTemplate.h
//  Prey
//
//  Created by Carlos Yaconi on 13/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"


@interface SetupControllerTemplate : UIViewController <MBProgressHUDDelegate> {
	
	MBProgressHUD *HUD;
}

//- (IBAction) next: (id) sender;
- (IBAction) cancel: (id) sender;
- (IBAction) doneEditing:(id)sender;

@end
