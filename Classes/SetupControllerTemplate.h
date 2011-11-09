//
//  SetupControllerTemplate.h
//  Prey
//
//  Created by Carlos Yaconi on 13/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "RegexKitLite.h"

#define kLabelTag	4096

@interface SetupControllerTemplate : UITableViewController <MBProgressHUDDelegate> {
	
	MBProgressHUD *HUD;
	UITableViewCell *buttonCell;
	NSString *strEmailMatchstring;
	BOOL enableToSubmit;
}

//- (IBAction) next: (id) sender;
//- (IBAction) cancel: (id) sender;
//- (IBAction) doneEditing:(id)sender;
- (void) activatePreyService;
- (void) showCongratsView:(id) congratsText;

@end
