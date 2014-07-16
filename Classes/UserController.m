//
//  UserController.m
//  Prey
//
//  Created by Javier Cala Uribe on 16/7/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

#import "UserController.h"

@implementation UserController

@synthesize name, email, password, btnNewUser, strEmailMatchstring, infoInputs, scrollView;

#pragma mark Requests methods

- (void)addDeviceForCurrentUser
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
        tmpFont = [UIFont fontWithName:fontString size:16];
    else
        tmpFont = [UIFont fontWithName:fontString size:24];
    
    return tmpFont;
}

- (CGRect)returnRectToInputsTable
{
    CGRect rect;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        rect = CGRectMake(20,12,255,30);
    else
        rect = CGRectMake(20,12,500,45);
    
    return rect;
}

- (CGRect)returnRectToBtnNewUser
{
    CGRect rect;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        rect = IS_IPHONE5 ? CGRectMake(35, 420, 250, 45) : CGRectMake(35, 360, 250, 45);
    else
        rect = CGRectMake(134, 680, 500, 90);
    
    return rect;
}

- (CGRect)returnRectToPreyTxt
{
    CGRect rect;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        rect = IS_IPHONE5 ? CGRectMake(90, 130, 140, 30) : CGRectMake (90, 90, 140, 30);
    else
        rect = CGRectMake(244, 200, 280, 60);
    
    return rect;
}

- (CGRect)returnRectToTableView
{
    CGRect rect;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        rect = IS_IPHONE5 ? CGRectMake(10, 180, 280, 190) : CGRectMake(10, 140, 280, 190);
    else
        rect = CGRectMake(109, 350, 530, 250);
    
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
    else if (self.view.frame.origin.y < 0)
        [self setViewMovedUp:NO];
}

-(void)textFieldDidBeginEditing:(UITextField *)sender{
    if  (self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
}

-(void)setViewMovedUp:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    
    CGRect rect      = self.view.frame;
    CGRect rectBtn   = btnNewUser.frame;
    if (movedUp)
    {
        rect.origin.y    -= IS_IPHONE5 ? kMoveTableView_iPhone5 : kMoveTableView_iPhone;
        rect.size.height += IS_IPHONE5 ? kMoveTableView_iPhone5 : kMoveTableView_iPhone;
        
        rectBtn.origin.y -= IS_IPHONE5 ? kMoveButton_iPhone5 : kMoveButton_iPhone;
    }
    else
    {
        rect.origin.y    += IS_IPHONE5 ? kMoveTableView_iPhone5 : kMoveTableView_iPhone;
        rect.size.height -= IS_IPHONE5 ? kMoveTableView_iPhone5 : kMoveTableView_iPhone;
        
        rectBtn.origin.y += IS_IPHONE5 ? kMoveButton_iPhone5 : kMoveButton_iPhone;
    }
    self.view.frame  = rect;
    btnNewUser.frame = rectBtn;
    
    [UIView commitAnimations];
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
