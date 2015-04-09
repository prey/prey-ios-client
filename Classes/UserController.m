//
//  UserController.m
//  Prey
//
//  Created by Javier Cala Uribe on 16/7/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

#import "UserController.h"

@implementation UserController

@synthesize name, email, password, btnNewUser, preyImage, strEmailMatchstring, infoInputs, scrollView;

#pragma mark Requests methods

- (void)addDeviceForCurrentUser
{
    
}

-(void)setViewMovedUp:(BOOL)movedUp
{
    
}

#pragma mark UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    NSInteger nextTag = textField.tag + 1;
    // Try to find next responder
    UIResponder* nextResponder = (UITextField *)[self.view viewWithTag:nextTag];
    if (nextResponder) {
        // Found next responder, so set it.
        [nextResponder becomeFirstResponder];
    } else {
        // Not found, so remove keyboard.
        [textField resignFirstResponder];
        [self addDeviceForCurrentUser];
    }
    return NO; // We do not want UITextField to insert line-breaks.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

#pragma mark Private methods

- (void) showCongratsView:(id) congratsText
{
    CongratulationsController *congratsController;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        if (IS_IPHONE5)
            congratsController = [[CongratulationsController alloc] initWithNibName:@"CongratulationsController-iPhone-568h" bundle:nil];
        else
            congratsController = [[CongratulationsController alloc] initWithNibName:@"CongratulationsController-iPhone" bundle:nil];
    }
    else
        congratsController = [[CongratulationsController alloc] initWithNibName:@"CongratulationsController-iPad" bundle:nil];
    
    congratsController.txtToShow = (NSString*) congratsText;
    
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.viewController setNavigationBarHidden:YES animated:YES];
    [appDelegate.viewController pushViewController:congratsController animated:YES];
}

- (UIFont*)returnFontToChange:(NSString *)fontString
{
    UIFont *tmpFont;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        tmpFont = [UIFont fontWithName:fontString size:14];
    else
        tmpFont = [UIFont fontWithName:fontString size:20];
    
    return tmpFont;
}

- (CGRect)returnRectToInputsTable
{
    CGRect rect;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        rect = CGRectMake(0,0,290,45);
    else
        rect = CGRectMake(0,0,470,73);
    
    return rect;
}

#pragma mark UIScrollView Config

-(void)keyboardWillShow {
    if (self.view.frame.origin.y >= 0)
        [self setViewMovedUp:YES];
}

-(void)keyboardWillHide{
    if (self.view.frame.origin.y >= 0)
        [self setViewMovedUp:YES];

    //else if (self.view.frame.origin.y < 0)
    //    [self setViewMovedUp:NO];
}

-(void)textFieldDidBeginEditing:(UITextField *)sender{
    if  (self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (self.view.frame.origin.y >= 0)
        [self setViewMovedUp:YES];

    //else if (self.view.frame.origin.y < 0)
    //    [self setViewMovedUp:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)dismissKeyboard:(UITapGestureRecognizer *)tapGesture{
    // Dismiss keyboard if is outside from UITableView
    if (!CGRectContainsPoint(infoInputs.frame, [tapGesture locationInView:self.view]))
        [self.view endEditing:YES];
}

@end
