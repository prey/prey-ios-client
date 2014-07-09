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
#import "CongratulationsController.h"
#import "User.h"
#import "Device.h"
#import "PreyConfig.h"
#import "PreyAppDelegate.h"
#import "GAITrackedViewController.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#import "CongratulationsController.h"
#import "PreyAppDelegate.h"
#import "Constants.h"



@interface OldUserController ()

- (void) addDeviceForCurrentUser;

@end

@implementation OldUserController

@synthesize email, password, buttonCell, strEmailMatchstring;

- (void) addDeviceForCurrentUser
{
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


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    switch (section) {
        case 0:
            return 2;
            break;
            
        default:
            return 1;
            break;
    }
    
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        UILabel *label =[[UILabel alloc] initWithFrame:CGRectMake(10, 10, 75, 25)];
        label.textAlignment = UITextAlignmentLeft;
        label.tag = kLabelTag;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont boldSystemFontOfSize:14];
        [cell.contentView addSubview:label];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    UILabel *label = (UILabel *)[cell viewWithTag:kLabelTag];
    
    switch ([indexPath section]) {
        case 0:
            if ([indexPath row] == 0){
                label.text = NSLocalizedString(@"Email",nil);
                [cell.contentView addSubview:email];
                
            }
            else if ([indexPath row] == 1){
                label.text = NSLocalizedString(@"Password",nil);
                [cell.contentView addSubview:password];
            }
            break;
        case 1:
            return buttonCell;
            break;
            
        default:
            break;
    }
    
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([indexPath section]) {
        case 0:
            if ([indexPath row] == 0)
                [email becomeFirstResponder];
            
            else if ([indexPath row] == 1)
                [password becomeFirstResponder];
            break;
            
        case 1:
            
            //if (enableToSubmit) {
            if (![email.text isMatchedByRegex:strEmailMatchstring]){
                UIAlertView *objAlert = [[UIAlertView alloc] initWithTitle:@"Error!" message:NSLocalizedString(@"Enter a valid e-mail address",nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Try Again",nil];
                [objAlert show];
                [email becomeFirstResponder];
                return;
            }
            [email resignFirstResponder];
            [password resignFirstResponder];
            
            HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            HUD.delegate = self;
            HUD.labelText = NSLocalizedString(@"Attaching device...",nil);
            
            [self addDeviceForCurrentUser];

            //}
            
            break;
            
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
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
    }
    return NO; // We do not want UITextField to insert line-breaks.
}


- (void)checkFieldsToEnableSendButton:(id)sender {
    if (email.text != nil &&
        ![email.text isEqualToString:@""] &&
        password.text != nil &&
        ![password.text isEqualToString:@""]) {
        buttonCell.selectionStyle = UITableViewCellSelectionStyleBlue;
        buttonCell.textLabel.textColor = [UIColor blackColor];
        enableToSubmit = YES;
    } else {
        buttonCell.selectionStyle = UITableViewCellSelectionStyleNone;
        buttonCell.textLabel.textColor = [UIColor grayColor];
        enableToSubmit = NO;
    }
}

#pragma mark -

- (void)viewDidLoad
{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Old User"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    
    strEmailMatchstring =   @"\\b([a-zA-Z0-9%_.+\\-]+)@([a-zA-Z0-9.\\-]+?\\.[a-zA-Z]{2,6})\\b";
    
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    
    UIView *fondo = [[UIView alloc] initWithFrame:screenRect];
    [fondo setBackgroundColor:[UIColor whiteColor]];
    
    UIImage *btm     = [UIImage imageNamed:@"bg-mnts2.png"];
    UIImageView *imv = [[UIImageView alloc] initWithImage:btm];
    
    if (IS_OS_7_OR_LATER)
    {
        imv.frame        = CGRectMake(0, screenHeight-99, 320, 99);
    }
    else
        imv.frame        = CGRectMake(0, screenHeight-143, 320, 99); // 143
    
    
    [fondo addSubview:imv];
    
    [self.tableView setBackgroundView:fondo];
    
    
    email = [[UITextField alloc] initWithFrame:CGRectMake(90,12,200,25)];
    email.clearsOnBeginEditing = NO;
    email.returnKeyType = UIReturnKeyNext;
    email.tag = 50;
    email.placeholder = @"Your Prey account email";
    email.keyboardType = UIKeyboardTypeEmailAddress;
    email.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [email setDelegate:self];
    //[email addTarget:self action:@selector(checkFieldsToEnableSendButton:) forControlEvents:UIControlEventEditingChanged];
    
    password = [[UITextField alloc] initWithFrame:CGRectMake(90,12,200,25)];
    password.clearsOnBeginEditing = NO;
    password.returnKeyType = UIReturnKeyDone;
    password.tag = 51;
    [password setSecureTextEntry:YES];
    password.placeholder = @"Your Prey account password";
    [password setDelegate:self];
    //[password addTarget:self action:@selector(checkFieldsToEnableSendButton:) forControlEvents:UIControlEventEditingChanged];
    
    buttonCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"buttonCell"];
    buttonCell.selectionStyle = UITableViewCellSelectionStyleBlue;
    buttonCell.textLabel.textColor = [UIColor blackColor];
    //buttonCell.selectionStyle = UITableViewCellSelectionStyleNone;
    //buttonCell.textLabel.textColor = [UIColor grayColor];
    buttonCell.textLabel.textAlignment = UITextAlignmentCenter;
    buttonCell.textLabel.text = NSLocalizedString(@"Add this device!",nil);
    
    [super viewDidLoad];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


#pragma mark -
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

@end
