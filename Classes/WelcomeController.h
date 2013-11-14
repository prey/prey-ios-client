//
//  WelcomeController.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 04/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <UIKit/UIKit.h>
#import "GAITrackedViewController.h"


@interface WelcomeController : GAITrackedViewController {
    UIButton *buttnewUser;
    UIButton *buttoldUser;
}
-(IBAction)newUserClicked:(id)sender;
-(IBAction)oldUserClicked:(id)sender;

@property (nonatomic, retain) IBOutlet UIButton *buttnewUser;
@property (nonatomic, retain) IBOutlet UIButton *buttoldUser;

@end
