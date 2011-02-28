//
//  PreferencesController.h
//  Prey
//
//  Created by Carlos Yaconi on 29/09/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AccuracyManager.h"

@interface PreferencesController : UITableViewController  {
UIActivityIndicatorView *cLoadingView;
	AccuracyManager *accManager;
	
}
@property (nonatomic, retain) UIActivityIndicatorView *cLoadingView;
- (void)initSpinner;
- (void)spinBegin;
- (void)spinEnd;

@end
