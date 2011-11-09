//
//  WelcomeController.h
//  Prey
//
//  Created by Carlos Yaconi on 04/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WelcomeController : UIViewController {
    UIButton *buttnewUser;
    UIButton *buttoldUser;
}
-(IBAction)newUserClicked:(id)sender;
-(IBAction)oldUserClicked:(id)sender;

@property (nonatomic, retain) IBOutlet UIButton *buttnewUser;
@property (nonatomic, retain) IBOutlet UIButton *buttoldUser;

@end
