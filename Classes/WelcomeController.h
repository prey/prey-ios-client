//
//  WelcomeController.h
//  Prey
//
//  Created by Carlos Yaconi on 04/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WelcomeController : UIViewController < UITableViewDelegate, UITableViewDataSource > {
	UITableView *optionsTable;

}
@property (nonatomic, retain) IBOutlet UITableView *optionsTable;


@end
