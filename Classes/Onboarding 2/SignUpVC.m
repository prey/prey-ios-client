//
//  SignUpVC.m
//  Prey
//
//  Created by Javier Cala Uribe on 11/12/15.
//  Copyright © 2015 Fork Ltd. All rights reserved.
//

#import "SignUpVC.h"
#import "SignInVC.h"
#import "GAIDictionaryBuilder.h"
#import "GAI.h"

@interface SignUpVC ()

@end

@implementation SignUpVC

- (void)addDeviceForCurrentUser
{
    [UIView setAnimationsEnabled:YES];
    
    UITextField *name     = (UITextField*)[self.view viewWithTag:101];
    UITextField *email    = (UITextField*)[self.view viewWithTag:102];
    UITextField *password = (UITextField*)[self.view viewWithTag:103];
    
    if (![self validateString:email.text withPattern:EMAIL_REG_EXP])
    {
        UIAlertView *objAlert = [[UIAlertView alloc] initWithTitle:@"Error!" message:NSLocalizedString(@"Enter a valid e-mail address",nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Try Again",nil) ,nil];
        [objAlert show];
        
        [email becomeFirstResponder];
        return;
    }
    
    if ([name.text length] < 1)
    {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"We have a situation!",nil) message:NSLocalizedString(@"Name can't be blank",nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        
        [name becomeFirstResponder];
        return;
    }
    /*
    if (![password.text isEqualToString:repassword.text])
    {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"We have a situation!",nil) message:NSLocalizedString(@"Passwords do not match",nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        
        [repassword becomeFirstResponder];
        return;
    }
    */
    if ([password.text length] <6)
    {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"We have a situation!",nil) message:NSLocalizedString(@"Password must be at least 6 characters",nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        
        [password becomeFirstResponder];
        return;
    }
    
    [self.view endEditing:YES];
    
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    HUD = [MBProgressHUD showHUDAddedTo:appDelegate.viewController.view animated:YES];
    HUD.labelText = NSLocalizedString(@"Creating account...",nil);
    
    [User createNew:[name text] email:[email text] password:[password text] repassword:[password text]
          withBlock:^(User *user, NSError *error)
     {
         if (!error) // User Login
         {
             [Device newDeviceForApiKey:user
                              withBlock:^(User *user, Device *dev, NSError *error)
              {
                  PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
                  [MBProgressHUD hideHUDForView:appDelegate.viewController.view animated:NO];
                  
                  if (!error) // Device created
                  {
                      PreyConfig *config = [PreyConfig initWithUser:user andDevice:dev];
                      if (config != nil)
                      {
                          // Send Event to GAnalytics
                          id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                          [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Acquisition"
                                                                                action:@"Sign Up"
                                                                                 label:@"Sign Up"
                                                                                 value:nil] build]];
                          
                          
                          NSString *txtCongrats = NSLocalizedString(@"Account created! Remember to verify your account by opening your inbox and clicking on the link we sent to your email address.",nil);
                          [(PreyAppDelegate*)[UIApplication sharedApplication].delegate registerForRemoteNotifications];
                          [self performSelectorOnMainThread:@selector(showCongratsView:) withObject:txtCongrats waitUntilDone:NO];
                      }
                  }
              }]; // End Block Device
         }
         else
         {
             PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
             [MBProgressHUD hideHUDForView:appDelegate.viewController.view animated:NO];
         }
     }]; // End Block User
}

- (void)callSignInView
{
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    SignInVC *nextController;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        if (IS_IPHONE5)
            nextController = [[SignInVC alloc] initWithNibName:@"SignInVC-iPhone-568h" bundle:nil];
        else
            nextController = [[SignInVC alloc] initWithNibName:@"SignInVC-iPhone" bundle:nil];
    }
    else
        nextController = [[SignInVC alloc] initWithNibName:@"SignInVC-iPad" bundle:nil];
    
    [appDelegate.viewController setViewControllers:[NSArray arrayWithObjects:nextController, nil] animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Config Keyboard
    if (IS_IPAD)
        offsetForKeyboard = 230;
    else
        offsetForKeyboard = (IS_IPHONE5) ? 200 : 170;
    
    
    // GoogleAnalytics Config
    self.screenName = @"Sign Up";

    // Dismiss Keyboard on tap outside
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
    [self.view addGestureRecognizer:tap];

    // Config delegate UITextField    
    for (UIView *view in [self.view subviews])
    {
        if ([view isKindOfClass:[UITextField class]])
             [(UITextField*)view setDelegate:self];
    }

    // Config selector UIButton
    UIButton *createNewAccount = (UIButton*)[self.view viewWithTag:201];
    [createNewAccount addTarget:self action:@selector(addDeviceForCurrentUser) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *callSignInBtn = (UIButton*)[self.view viewWithTag:202];
    [callSignInBtn addTarget:self action:@selector(callSignInView) forControlEvents:UIControlEventTouchUpInside];
    
    [self changeTexts];
}

- (void)changeTexts
{
    _subtitleView.text                  = NSLocalizedString(@"prey account",nil);
    _titleView.text                     = NSLocalizedString(@"SIGN UP", nil);
    _usernameField.placeholder          = NSLocalizedString(@"username", nil);
    _emailField.placeholder             = NSLocalizedString(@"email", nil);
    _passwordField.placeholder          = NSLocalizedString(@"password", nil);
    _createAccountBtn.titleLabel.text   = NSLocalizedString(@"CREATE MY NEW ACCOUNT", nil);
    _signInBtn.titleLabel.text          = NSLocalizedString(@"already have an account?", nil);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)setViewMovedUp:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    
    CGRect rect = self.view.frame;
    if (movedUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y -= offsetForKeyboard;
        rect.size.height += offsetForKeyboard;
    }
    else
    {
        // revert back to the normal state.
        rect.origin.y += offsetForKeyboard;
        rect.size.height -= offsetForKeyboard;
    }
    self.view.frame = rect;
    
    [UIView commitAnimations];
}

@end
