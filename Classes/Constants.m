//
//  Config.m
//  prey-installer-cocoa
//
//  Created by Carlos Yaconi on 25-03-10.
//  Copyright 2010 Fork Ltd.. All rights reserved.
//

#import "Constants.h"


@implementation Constants
	NSString * const PREY_VERSION = @"0.5.3 (BETA)";
	NSString * const PREY_URL = @"http://control.preyproject.com/";
    //NSString * const PREY_URL = @"http://unstable.share.cl/";
	NSString * const PREY_SECURE_URL = @"https://control.preyproject.com/";
    //NSString * const PREY_SECURE_URL = @"https://unstable.share.cl/";
	NSString * const PREY_USER_AGENT = @"Prey/0.5.3 (iOS BETA)"; //could be linked with version constant. TODO!
	BOOL  const ASK_FOR_LOGIN = YES;
	BOOL const	USE_CONTROL_PANEL_DELAY=NO; //use the preferences page's instead.
@end
