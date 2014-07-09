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
@property (nonatomic) IBOutlet UIButton *BUTTON;
@property (nonatomic) IBOutlet UILabel *textMsg;
@property (nonatomic) IBOutlet UILabel *textTitle;
@end
