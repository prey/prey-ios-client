//
//  SignInVC.m
//  Prey
//
//  Created by Javier Cala Uribe on 11/12/15.
//  Copyright © 2015 Fork Ltd. All rights reserved.
//

#import "SignInVC.h"
#import "SignUpVC.h"
#import "GAIDictionaryBuilder.h"
#import "GAI.h"
#import "QRCodeScannerVC.h"

@interface SignInVC ()

@end

@implementation SignInVC

- (IBAction)addDeviceWithQRCode:(id)sender {
    
#warning Available only iOS 7 or later
    UIViewController *controller = [[QRCodeScannerVC alloc] init];
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    if (controller)
        [appDelegate.viewController presentViewController:controller animated:YES completion:NULL];
}

- (void)addDeviceForCurrentUser
{
    [UIView setAnimationsEnabled:YES];
    
    UITextField *email    = (UITextField*)[self.view viewWithTag:102];
    UITextField *password = (UITextField*)[self.view viewWithTag:103];

    
    if (![self validateString:email.text withPattern:EMAIL_REG_EXP])
    {
        UIAlertView *objAlert = [[UIAlertView alloc] initWithTitle:@"Error!" message:NSLocalizedString(@"Enter a valid e-mail address",nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Try Again",nil),nil];
        [objAlert show];
        
        [email becomeFirstResponder];
        return;
    }
    
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
    HUD.label.text = NSLocalizedString(@"Attaching device...",nil);
    
    // Get Token for Control Panel
    PreyConfig *config = [PreyConfig instance];
    [User getTokenFromPanel:email.text password:password.text
                  withBlock:^(NSString *token, NSError *error)
     {
         if (!error) // User Login
         {
             [config setTokenPanel:token];
             [config saveValues];
         }
     }]; // End Block User

    // Add new device to Control Panel
    [User allocWithEmail:[email text] password:[password text]
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
                          NSString *txtCongrats = NSLocalizedString(@"Congratulations! You have successfully associated this iOS device with your Prey account.",nil);
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

- (void)callSignUpView
{
    PreyAppDelegate *appDelegate = (PreyAppDelegate*)[[UIApplication sharedApplication] delegate];
    SignUpVC *nextController;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        if (IS_IPHONE5)
            nextController = [[SignUpVC alloc] initWithNibName:@"SignUpVC-iPhone-568h" bundle:nil];
        else
            nextController = [[SignUpVC alloc] initWithNibName:@"SignUpVC-iPhone" bundle:nil];
    }
    else
        nextController = [[SignUpVC alloc] initWithNibName:@"SignUpVC-iPad" bundle:nil];
    
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
    self.screenName = @"Sign In";

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

    UIButton *callSignUpBtn = (UIButton*)[self.view viewWithTag:202];
    [callSignUpBtn addTarget:self action:@selector(callSignUpView) forControlEvents:UIControlEventTouchUpInside];
    
    [self changeTexts];
}

- (void)changeTexts
{
    _subtitleView.text                  = NSLocalizedString(@"prey account",nil);
    _titleView.text                     = NSLocalizedString(@"SIGN IN", nil);
    _emailField.placeholder             = NSLocalizedString(@"email", nil);
    _passwordField.placeholder          = NSLocalizedString(@"password", nil);
    
    [_createAccountBtn setTitle:[NSLocalizedString(@"ACCESS TO MY ACCOUNT", nil) uppercaseString] forState: UIControlStateNormal];
    [_signInBtn setTitle:NSLocalizedString(@"don’t have an account?", nil) forState: UIControlStateNormal];
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
