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


@interface CongratulationsController : UIViewController {

	UILabel *congratsTitle;
	UITextView *congratsMsg;
	UIButton *ok;
    NSString *txtToShow;
}

@property (nonatomic, retain) IBOutlet UILabel *congratsTitle;
@property (nonatomic, retain) IBOutlet UITextView *congratsMsg;
@property (nonatomic, retain) IBOutlet UIButton *ok;
@property (nonatomic, retain) NSString *txtToShow;

- (IBAction) okPressed: (id) sender;

@end
