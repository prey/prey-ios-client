//
//  CongratulationsController.h
//  Prey
//
//  Created by Carlos Yaconi on 04/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
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
