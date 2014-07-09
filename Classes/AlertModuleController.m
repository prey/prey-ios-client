//
//  AlertModuleController.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 19/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "AlertModuleController.h"


@implementation AlertModuleController

@synthesize preyName, text, textToShow;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Alert";
    
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    self.view.frame = CGRectMake(0, 20, appFrame.size.width, appFrame.size.height);
	//[[UIApplication sharedApplication] setStatusBarHidden:YES];
	[preyName setFont:[UIFont fontWithName:@"large9" size:60]];
	[text setText:textToShow];
	PreyLogMessage(@"alert", 10, @"Text: %@",text.text);
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

@end