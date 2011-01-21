//
//  AlertModule.m
//  Prey
//
//  Created by Carlos Yaconi on 19/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//

#import "AlertModule.h"
#import "PreyAppDelegate.h"


@implementation AlertModule

- (void)main {
	PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
	NSString *alertMessage = [self.configParms objectForKey:@"alert_message"];
	[appDelegate showAlert:alertMessage];
	[alertMessage release];
}

- (NSString *) getName {
	return @"alert";
}
@end
