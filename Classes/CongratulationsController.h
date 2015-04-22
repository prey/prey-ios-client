//
//  CongratulationsController.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 04/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <UIKit/UIKit.h>
#import "GAITrackedViewController.h"

@interface CongratulationsController : GAITrackedViewController <UIAlertViewDelegate> {

	UILabel *congratsTitle;
	UILabel *congratsMsg;
	UIButton *ok;
    NSString *txtToShow;
    CLLocationManager *authLocation;
}

@property (nonatomic) IBOutlet UILabel *congratsTitle;
@property (nonatomic) IBOutlet UILabel *congratsMsg;
@property (nonatomic) IBOutlet UIButton *ok;
@property (nonatomic) NSString *txtToShow;
@property (nonatomic) CLLocationManager *authLocation;

- (IBAction) okPressed: (id) sender;

@end
