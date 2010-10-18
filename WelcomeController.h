//
//  WelcomeController.h
//  Prey
//
//  Created by Carlos Yaconi on 04/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WelcomeController : UIViewController {
	UILabel *welcomeTitle;
	UITextView *welcomeText;
	UIButton *yes;
	UIButton *no;

}

@property (nonatomic, retain) IBOutlet UILabel *welcomeTitle;
@property (nonatomic, retain) IBOutlet UITextView *welcomeText;
@property (nonatomic, retain) IBOutlet UIButton *yes;
@property (nonatomic, retain) IBOutlet UIButton *no;

- (IBAction) notRegistered: (id) sender;
- (IBAction) alreadyRegistered: (id) sender;

@end
