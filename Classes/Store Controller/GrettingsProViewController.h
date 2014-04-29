//
//  GrettingsProViewController.h
//  Prey
//
//  Created by Diego Torres on 3/15/12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GAITrackedViewController.h"

@interface GrettingsProViewController : GAITrackedViewController

-(IBAction)CLICKY:(id)sender;   
@property (nonatomic, retain) IBOutlet UIButton *BUTTON;
@property (nonatomic, retain) IBOutlet UILabel *textMsg;
@property (nonatomic, retain) IBOutlet UILabel *textTitle;
@end
