//
//  GrettingsProViewController.m
//  Prey
//
//  Created by Diego Torres on 3/15/12.
//  Copyright (c) 2012 Fork Ltd. All rights reserved.
//

#import "GrettingsProViewController.h"
#import "PreyAppDelegate.h"

@interface GrettingsProViewController ()

@end

@implementation GrettingsProViewController
@synthesize BUTTON, textMsg, textTitle;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    self.screenName = @"Grettings Pro Accounts";
    
    [super viewDidLoad];
    [self.textMsg setText:NSLocalizedString(@"Thanks for your support. You've just gained access to all the Pro features, including private and direct support from us, the Prey Team.", nil)];
    [self.textTitle setText:NSLocalizedString(@"Congrats,\nyou're now Pro", nil)];
    [self.BUTTON setTitle:NSLocalizedString(@"Go back to preferences", nil) forState:UIControlStateNormal];
    // Do any additional setup after loading the view from its nib.
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"proUpdated" object:nil];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];    
}

-(IBAction)CLICKY:(id)sender
{
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    if ([appDelegate.viewController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) // Check iOS 5.0 or later
        [appDelegate.viewController dismissViewControllerAnimated:YES completion:NULL];
    else
        [appDelegate.viewController dismissModalViewControllerAnimated:YES];
    
    [appDelegate.viewController popViewControllerAnimated:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
