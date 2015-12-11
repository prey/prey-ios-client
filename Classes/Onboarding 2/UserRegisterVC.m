//
//  UserRegisterVC.m
//  Prey
//
//  Created by Javier Cala Uribe on 11/12/15.
//  Copyright © 2015 Fork Ltd. All rights reserved.
//

#import "UserRegisterVC.h"
#import "CongratulationsController.h"

@interface UserRegisterVC ()

@end

@implementation UserRegisterVC

@synthesize offsetForKeyboard;

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark Requests methods

- (void)addDeviceForCurrentUser
{
    
}

- (void)setViewMovedUp:(BOOL)movedUp
{
    
}

#pragma mark Private methods

- (BOOL)validateString:(NSString *)string withPattern:(NSString *)pattern
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSRange textRange = NSMakeRange(0, string.length);
    NSRange matchRange = [regex rangeOfFirstMatchInString:string options:NSMatchingReportProgress range:textRange];
    
    BOOL didValidate = NO;
    
    // Did we find a matching range
    if (matchRange.location != NSNotFound)
        didValidate = YES;
    
    return didValidate;
}

- (void)showCongratsView:(id)congratsText
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


#pragma mark UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
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


#pragma mark Move up/down when show/hide keyboard

- (void)keyboardWillShow {
    
    if (self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
}

- (void)keyboardWillHide {

    if (self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}

-(void)textFieldDidBeginEditing:(UITextField *)sender
{
    //move the main view, so that the keyboard does not hide it.
    if  (self.view.frame.origin.y >= 0)
        [self setViewMovedUp:YES];
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
    
    if (CGRectContainsPoint(self.view.frame, [tapGesture locationInView:self.view]))
        [self.view endEditing:YES];
}

@end
