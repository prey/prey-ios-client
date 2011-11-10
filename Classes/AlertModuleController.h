//
//  AlertModuleController.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 19/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <UIKit/UIKit.h>


@interface AlertModuleController : UIViewController {

	UILabel *preyName;
	UILabel *text;
	NSString *textToShow;
}

@property (nonatomic, retain) IBOutlet UILabel *preyName;
@property (nonatomic, retain) IBOutlet UILabel *text;
@property (nonatomic, retain) NSString *textToShow;

@end
