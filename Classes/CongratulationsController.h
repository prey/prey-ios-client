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

@interface CongratulationsController : GAITrackedViewController {

	UILabel *congratsTitle;
	UILabel *congratsMsg;
	UIButton *ok;
    NSString *txtToShow;
    CLLocationManager *authLocation;
}

@property (nonatomic, retain) IBOutlet UILabel *congratsTitle;
@property (nonatomic, retain) IBOutlet UILabel *congratsMsg;
@property (nonatomic, retain) IBOutlet UIButton *ok;
@property (nonatomic, retain) NSString *txtToShow;
@property (nonatomic, retain) CLLocationManager *authLocation;

- (IBAction) okPressed: (id) sender;

@end
