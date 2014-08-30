//
//  NewUserController.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 01/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "NewUserController.h"

@implementation NewUserController

@synthesize repassword;

#pragma mark Request methods

- (void)addDeviceForCurrentUser
{
    if (![email.text isMatchedByRegex:strEmailMatchstring]){
        UIAlertView *objAlert = [[UIAlertView alloc] initWithTitle:@"Error!" message:NSLocalizedString(@"Enter a valid e-mail address",nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Try Again",nil];
        [objAlert show];
        
        [email becomeFirstResponder];
        return;
    }
    
    if (![password.text isEqualToString:repassword.text])
    {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"We have a situation!",nil) message:NSLocalizedString(@"Passwords do not match",nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        
        [repassword becomeFirstResponder];
        return;
    }
    
    if ([password.text length] <6)
    {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"We have a situation!",nil) message:NSLocalizedString(@"Password must be at least 6 characters",nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        
        [password becomeFirstResponder];
        return;
    }

    [self hideKeyboard];
    
    HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    HUD.delegate = self;
    HUD.labelText = NSLocalizedString(@"Creating account...",nil);
    
    [User createNew:[name text] email:[email text] password:[password text] repassword:[repassword text]
               withBlock:^(User *user, NSError *error)
     {
         if (!error) // User Login
         {
             [Device newDeviceForApiKey:user
                              withBlock:^(User *user, Device *dev, NSError *error)
              {
                  [MBProgressHUD hideHUDForView:self.navigationController.view animated:NO];
                  
                  if (!error) // Device created
                  {
                      PreyConfig *config = [PreyConfig initWithUser:user andDevice:dev];
                      if (config != nil)
                      {
                          NSString *txtCongrats = NSLocalizedString(@"Account created! Remember to verify your account by opening your inbox and clicking on the link we sent to your email address.",nil);
                          [(PreyAppDelegate*)[UIApplication sharedApplication].delegate registerForRemoteNotifications];
                          [self performSelectorOnMainThread:@selector(showCongratsView:) withObject:txtCongrats waitUntilDone:NO];
                      }
                  }
              }]; // End Block Device
         }
         else
             [MBProgressHUD hideHUDForView:self.navigationController.view animated:NO];
     }]; // End Block User
}

#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    switch (section) {
        case 0:
            return 4;
            break;
    }
    return 4;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"CellNew";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    switch ([indexPath section]) {
      
        case 0:
            if ([indexPath row] == 0){
                [cell.contentView addSubview:name];
                
            }
            else if ([indexPath row] == 1){
                [cell.contentView addSubview:email];
            }
            else if ([indexPath row] == 2){
                [cell.contentView addSubview:password];
            }
            else if ([indexPath row] == 3){
                [cell.contentView addSubview:repassword];
            }
            break;
    }
    
    return cell;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //LogMessageCompat(@"Table cell press. Section: %i, Row: %i",[indexPath section],[indexPath row]);
    switch ([indexPath section]) {
        case 0:
            if ([indexPath row] == 0){
                [name becomeFirstResponder];
            }
            else if ([indexPath row] == 1){
                [email becomeFirstResponder];
            }
            else if ([indexPath row] == 2){
                [password becomeFirstResponder];
            }
            else if ([indexPath row] == 3){
                [repassword becomeFirstResponder];
            }
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark Init
- (void)viewDidLoad
{
    // GoogleAnalytics Config
    self.screenName = @"New User";
    
    // Dismiss Keyboard on tap outside
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
    [self.view addGestureRecognizer:tap];
    
    // Add ScrollView to main View
    scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    scrollView.contentInset = UIEdgeInsetsMake(-36, 0, 0, 0);
    
    // Check email inputs
    strEmailMatchstring =   @"\\b([a-zA-Z0-9%_.+\\-]+)@([a-zA-Z0-9.\\-]+?\\.[a-zA-Z]{2,6})\\b";

    // Main View Color:White
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // TableView Config
    infoInputs = [[UITableView alloc] initWithFrame:[self returnRectToTableView] style:UITableViewStylePlain];
    [infoInputs setDataSource:self];
    [infoInputs setDelegate:self];
    [infoInputs setScrollEnabled:NO];
    infoInputs.rowHeight = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? 44 : 60;    
    //infoInputs.contentInset = UIEdgeInsetsMake(-36, 0, 0, 0);

    [scrollView addSubview:infoInputs];

    
    UIImage *preyImage = [UIImage imageNamed:@"prey-text"];
    UIImageView *preyText = [[UIImageView alloc] initWithImage:preyImage];
    preyText.frame = [self returnRectToPreyTxt];
    [scrollView addSubview:preyText];
    
    name = [[UITextField alloc] initWithFrame:[self returnRectToInputsTable]];
    name.clearsOnBeginEditing = NO;
    name.returnKeyType = UIReturnKeyNext;
    name.tag = 28;
    name.font = [self returnFontToChange:@"OpenSans"];
    name.placeholder = NSLocalizedString(@"Your name",nil);
    [name setDelegate:self];
    
    email = [[UITextField alloc] initWithFrame:[self returnRectToInputsTable]];
    email.clearsOnBeginEditing = NO;
    email.returnKeyType = UIReturnKeyNext;
    email.tag = 29;
    email.font = [self returnFontToChange:@"OpenSans"];
    email.placeholder = NSLocalizedString(@"Your email",nil);
    email.keyboardType = UIKeyboardTypeEmailAddress;
    email.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [email setDelegate:self];
    
    password = [[UITextField alloc] initWithFrame:[self returnRectToInputsTable]];
    password.clearsOnBeginEditing = NO;
    password.returnKeyType = UIReturnKeyNext;
    password.tag = 30;
    password.font = [self returnFontToChange:@"OpenSans"];
    [password setSecureTextEntry:YES];
    password.placeholder = NSLocalizedString(@"Choose a 6 characters password",nil);
    [password setDelegate:self];
    
    repassword = [[UITextField alloc] initWithFrame:[self returnRectToInputsTable]];
    repassword.clearsOnBeginEditing = NO;
    repassword.returnKeyType = UIReturnKeyDone;
    repassword.tag = 31;
    repassword.font = [self returnFontToChange:@"OpenSans"];
    [repassword setSecureTextEntry:YES];
    repassword.placeholder = NSLocalizedString(@"Repeat your password",nil);
    [repassword setDelegate:self];
    
    
    btnNewUser = [[UIButton alloc] initWithFrame:[self returnRectToBtnNewUser]];
    [btnNewUser setBackgroundColor:[UIColor clearColor]];
    [btnNewUser setBackgroundImage:[UIImage imageNamed:@"signupbtn"] forState:UIControlStateNormal];
    [btnNewUser setBackgroundImage:[UIImage imageNamed:@"signupbtn"] forState:UIControlStateHighlighted];
    [btnNewUser.titleLabel setFont:[self returnFontToChange:@"OpenSans"]];
    [btnNewUser setTitleColor:[UIColor colorWithRed:1 green:(255/255.f) blue:(255/255.f) alpha:1.f] forState:UIControlStateNormal];
    btnNewUser.titleLabel.textAlignment = UITextAlignmentCenter;
    [btnNewUser setTitle:[NSLocalizedString(@"Create my account!",nil) uppercaseString] forState:UIControlStateNormal];
    [btnNewUser addTarget:self action:@selector(addDeviceForCurrentUser) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:btnNewUser];

    
    [self.view addSubview:scrollView];
    
    [super viewDidLoad];
}

#pragma mark Private methods

- (void) hideKeyboard {
    [email resignFirstResponder];
    [name resignFirstResponder];
    [password resignFirstResponder];
    [repassword resignFirstResponder];
}


@end
