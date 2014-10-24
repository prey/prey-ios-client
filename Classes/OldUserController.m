//
//  OldUserController.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 01/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "OldUserController.h"

@implementation OldUserController

#pragma mark Request methods

- (void)addDeviceForCurrentUser
{
    if (![email.text isMatchedByRegex:strEmailMatchstring]){
        UIAlertView *objAlert = [[UIAlertView alloc] initWithTitle:@"Error!" message:NSLocalizedString(@"Enter a valid e-mail address",nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Try Again",nil];
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
    
    [self hideKeyboard];
    
    HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    HUD.delegate = self;
    HUD.labelText = NSLocalizedString(@"Attaching device...",nil);
    
    [User allocWithEmail:[email text] password:[password text]
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
                          NSString *txtCongrats = NSLocalizedString(@"Congratulations! You have successfully associated this iOS device with your Prey account.",nil);
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
            return 2;
            break;
    }
    return 2;
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
                [cell.contentView addSubview:email];
                
            }
            else if ([indexPath row] == 1){
                [cell.contentView addSubview:password];
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
                [email becomeFirstResponder];
            }
            else if ([indexPath row] == 1){
                [password becomeFirstResponder];
            }
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark Init
- (void)viewDidLoad
{
    // GoogleAnalytics Config
    self.screenName = @"Old User";
    
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
    
    email = [[UITextField alloc] initWithFrame:[self returnRectToInputsTable]];
    email.clearsOnBeginEditing = NO;
    email.returnKeyType = UIReturnKeyNext;
    email.tag = 29;
    email.font = [self returnFontToChange:@"OpenSans"];
    email.placeholder = @"Your Prey account email";
    email.keyboardType = UIKeyboardTypeEmailAddress;
    email.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [email setDelegate:self];
    
    password = [[UITextField alloc] initWithFrame:[self returnRectToInputsTable]];
    password.clearsOnBeginEditing = NO;
    password.returnKeyType = UIReturnKeyDone;
    password.tag = 30;
    password.font = [self returnFontToChange:@"OpenSans"];
    [password setSecureTextEntry:YES];
    password.placeholder = @"Your Prey account password";
    [password setDelegate:self];
    
    btnNewUser = [[UIButton alloc] initWithFrame:[self returnRectToBtnNewUser]];
    [btnNewUser setBackgroundColor:[UIColor clearColor]];
    [btnNewUser setBackgroundImage:[UIImage imageNamed:@"bt-welcome"] forState:UIControlStateNormal];
    [btnNewUser setBackgroundImage:[UIImage imageNamed:@"bt-welcome"] forState:UIControlStateHighlighted];
    [btnNewUser.titleLabel setFont:[self returnFontToChange:@"OpenSans"]];
    [btnNewUser setTitleColor:[UIColor colorWithRed:0 green:(146/255.f) blue:(187/255.f) alpha:1.f] forState:UIControlStateNormal];
    btnNewUser.titleLabel.textAlignment = UITextAlignmentCenter;
    [btnNewUser setTitle:[NSLocalizedString(@"Add this device!",nil) uppercaseString] forState:UIControlStateNormal];
    [btnNewUser addTarget:self action:@selector(addDeviceForCurrentUser) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:btnNewUser];
    
    
    [self.view addSubview:scrollView];
    
    [super viewDidLoad];
}

#pragma mark Private methods

- (void) hideKeyboard {
    [email resignFirstResponder];
    [password resignFirstResponder];
}

- (CGRect)returnRectToBtnNewUser
{
    CGRect rect;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        rect = IS_IPHONE5 ? CGRectMake(35, 390, 250, 45) : CGRectMake(35, 320, 250, 45);
    else
        rect = CGRectMake(134, 630, 500, 90);
    
    return rect;
}

- (CGRect)returnRectToTableView
{
    CGRect rect;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        rect = IS_IPHONE5 ? CGRectMake(10, 210, 280, 100) : CGRectMake(10, 170, 280, 100);
    else
        rect = CGRectMake(109, 380, 530, 120);
    
    return rect;
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
        
        rectBtn.origin.y -= IS_IPHONE5 ? kMoveButton_iPhone5 : 35;
    }
    else
    {
        rect.origin.y    += IS_IPHONE5 ? kMoveTableView_iPhone5 : kMoveTableView_iPhone;
        rect.size.height -= IS_IPHONE5 ? kMoveTableView_iPhone5 : kMoveTableView_iPhone;
        
        rectBtn.origin.y += IS_IPHONE5 ? kMoveButton_iPhone5 : 35;
    }
    self.view.frame  = rect;
    btnNewUser.frame = rectBtn;
    
    [UIView commitAnimations];
}


@end