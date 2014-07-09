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
#import "GAITrackedViewController.h"

@interface AlertModuleController : GAITrackedViewController {

    UILabel *preyName;
	UILabel *text;
	NSString *textToShow;
}

@property (nonatomic) IBOutlet UILabel *preyName;
@property (nonatomic) IBOutlet UILabel *text;
@property (nonatomic) NSString *textToShow;

@end
