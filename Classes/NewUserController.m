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
#import "GAI.h"
#import "GAIDictionaryBuilder.h"

#define kLogoPosX_iPhone5        99.0
#define kLogoPosY_iPhone5        83.0
#define kLogoPosWidth_iPhone5   122.0
#define kLogoPosHeight_iPhone5  144.0

#define kLogoPosY_iPhone         49.0

#define kLogoPosX_iPad          314.0
#define kLogoPosY_iPad          189.0
#define kLogoPosWidth_iPad      140.0
#define kLogoPosHeight_iPad     161.0

#define kBtnAddPosX_iPhone5        35.0
#define kBtnAddPosY_iPhone5       465.0
#define kBtnAddPosWidth_iPhone5   250.0
#define kBtnAddPosHeight_iPhone5   43.0

#define kBtnAddPosY_iPhone        405.0

#define kBtnAddPosX_iPad          189.0
#define kBtnAddPosY_iPad          749.0
#define kBtnAddPosWidth_iPad      390.0
#define kBtnAddPosHeight_iPad      66.0

#define kTablePosX_iPhone5        15.0
#define kTablePosY_iPhone5       265.0
#define kTablePosWidth_iPhone5   290.0
#define kTablePosHeight_iPhone5  180.0

#define kTablePosY_iPhone        208.0

#define kTablePosX_iPad          149.0
#define kTablePosY_iPad          418.0
#define kTablePosWidth_iPad      470.0
#define kTablePosHeight_iPad     290.0

#define kMoveTableView_iPhone5  180.0
#define kMoveTableView_iPhone   148.0
#define kMoveLogo_iPhone5       -27.0
#define kMoveLogo_iPhone         20.0
#define kMoveLogo_iPad          -45.0


@implementation NewUserController

@synthesize repassword;

#pragma mark Request methods

- (void)addDeviceForCurrentUser
{
    if (![email.text isMatchedByRegex:strEmailMatchstring]){
        UIAlertView *objAlert = [[UIAlertView alloc] initWithTitle:@"Error!" message:NSLocalizedString(@"Enter a valid e-mail address",nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Try Again",nil) ,nil];
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
    
    if (IS_OS_7_OR_LATER)
        cell.separatorInset = UIEdgeInsetsMake(0.f, 0.f, 0.f, cell.bounds.size.width);

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
    infoInputs.separatorColor = [UIColor clearColor];
    infoInputs.rowHeight = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? 44 : 72.5;
    //infoInputs.contentInset = UIEdgeInsetsMake(-36, 0, 0, 0);

    [scrollView addSubview:infoInputs];

    UIColor *colorPlaceholder = [UIColor colorWithRed:(72/255.f) green:(84/255.f) blue:(102/255.f) alpha:1.f];
    
    UIImage *preyText = [UIImage imageNamed:@"prey-text"];
    preyImage = [[UIImageView alloc] initWithImage:preyText];
    preyImage.frame = [self returnRectToPreyTxt];
    [scrollView addSubview:preyImage];
    
    name = [[UITextField alloc] initWithFrame:[self returnRectToInputsTable]];
    name.clearsOnBeginEditing = NO;
    name.returnKeyType = UIReturnKeyNext;
    name.tag = 28;
    name.font = [self returnFontToChange:@"OpenSans"];
    name.borderStyle = UITextBorderStyleRoundedRect;
    [name setDelegate:self];
    [name setBackgroundColor:[UIColor colorWithRed:(240/255.f) green:(243/255.f) blue:(247/255.f) alpha:1.f]];
    if (IS_OS_6_OR_LATER)
        name.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Your name",nil)
                                                                      attributes:@{NSForegroundColorAttributeName:colorPlaceholder}];
    else
        name.placeholder = NSLocalizedString(@"Your name",nil);

    
    email = [[UITextField alloc] initWithFrame:[self returnRectToInputsTable]];
    email.clearsOnBeginEditing = NO;
    email.returnKeyType = UIReturnKeyNext;
    email.tag = 29;
    email.font = [self returnFontToChange:@"OpenSans"];
    email.borderStyle = UITextBorderStyleRoundedRect;
    email.keyboardType = UIKeyboardTypeEmailAddress;
    email.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [email setDelegate:self];
    [email setBackgroundColor:[UIColor clearColor]];
    if (IS_OS_6_OR_LATER)
        email.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Your email",nil)
                                                                         attributes:@{NSForegroundColorAttributeName:colorPlaceholder}];
    else
        email.placeholder = NSLocalizedString(@"Your email",nil);

    
    password = [[UITextField alloc] initWithFrame:[self returnRectToInputsTable]];
    password.clearsOnBeginEditing = NO;
    password.returnKeyType = UIReturnKeyNext;
    password.tag = 30;
    password.font = [self returnFontToChange:@"OpenSans"];
    password.borderStyle = UITextBorderStyleRoundedRect;
    [password setSecureTextEntry:YES];
    [password setDelegate:self];
    [password setBackgroundColor:[UIColor clearColor]];
    if (IS_OS_6_OR_LATER)
        password.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Choose a 6 characters password",nil)
                                                                      attributes:@{NSForegroundColorAttributeName:colorPlaceholder}];
    else
        password.placeholder = NSLocalizedString(@"Choose a 6 characters password",nil);

    
    repassword = [[UITextField alloc] initWithFrame:[self returnRectToInputsTable]];
    repassword.clearsOnBeginEditing = NO;
    repassword.returnKeyType = UIReturnKeyDone;
    repassword.tag = 31;
    repassword.font = [self returnFontToChange:@"OpenSans"];
    repassword.borderStyle = UITextBorderStyleRoundedRect;
    [repassword setSecureTextEntry:YES];
    repassword.placeholder = NSLocalizedString(@"Repeat your password",nil);
    [repassword setDelegate:self];
    [repassword setBackgroundColor:[UIColor clearColor]];
    if (IS_OS_6_OR_LATER)
        repassword.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Repeat your password",nil)
                                                                         attributes:@{NSForegroundColorAttributeName:colorPlaceholder}];
    else
        repassword.placeholder = NSLocalizedString(@"Repeat your password",nil);

    
    
    btnNewUser = [[UIButton alloc] initWithFrame:[self returnRectToBtnNewUser]];
    [btnNewUser setBackgroundColor:[UIColor clearColor]];
    [btnNewUser setBackgroundImage:[UIImage imageNamed:@"bt-welcome"] forState:UIControlStateNormal];
    [btnNewUser setBackgroundImage:[UIImage imageNamed:@"bt-welcome-press"] forState:UIControlStateHighlighted];
    [btnNewUser.titleLabel setFont:[self returnFontToChange:@"OpenSans"]];
    [btnNewUser setTitleColor:[UIColor colorWithRed:0 green:(129/255.f) blue:(194/255.f) alpha:1.f] forState:UIControlStateNormal];
    [btnNewUser setTitleColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1.f] forState:UIControlStateHighlighted];
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

- (CGRect)returnRectToPreyTxt
{
    CGRect rect;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        rect = IS_IPHONE5 ? CGRectMake(kLogoPosX_iPhone5, kLogoPosY_iPhone5, kLogoPosWidth_iPhone5, kLogoPosHeight_iPhone5) :
        CGRectMake(kLogoPosX_iPhone5, kLogoPosY_iPhone, kLogoPosWidth_iPhone5, kLogoPosHeight_iPhone5);
    else
        rect = CGRectMake(kLogoPosX_iPad, kLogoPosY_iPad, kLogoPosWidth_iPad, kLogoPosHeight_iPad);
    
    return rect;
}

- (CGRect)returnRectToBtnNewUser
{
    CGRect rect;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        rect = IS_IPHONE5 ? CGRectMake(kBtnAddPosX_iPhone5, kBtnAddPosY_iPhone5, kBtnAddPosWidth_iPhone5, kBtnAddPosHeight_iPhone5) :
        CGRectMake(kBtnAddPosX_iPhone5, kBtnAddPosY_iPhone, kBtnAddPosWidth_iPhone5, kBtnAddPosHeight_iPhone5);
    else
        rect = CGRectMake(kBtnAddPosX_iPad, kBtnAddPosY_iPad, kBtnAddPosWidth_iPad, kBtnAddPosHeight_iPad);
    
    return rect;
}

- (CGRect)returnRectToTableView
{
    CGRect rect;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        rect = IS_IPHONE5 ? CGRectMake(kTablePosX_iPhone5, kTablePosY_iPhone5, kTablePosWidth_iPhone5, kTablePosHeight_iPhone5) :
        CGRectMake(kTablePosX_iPhone5, kTablePosY_iPhone, kTablePosWidth_iPhone5, kTablePosHeight_iPhone5);
    else
        rect = CGRectMake(kTablePosX_iPad, kTablePosY_iPad, kTablePosWidth_iPad, kTablePosHeight_iPad);
    
    return rect;
}

-(void)setViewMovedUp:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    
    CGRect rect      = self.view.frame;
    CGRect rectLogo  = preyImage.frame;
    if (movedUp)
    {
        rect.origin.y     -= IS_IPHONE5 ? kMoveTableView_iPhone5 : kMoveTableView_iPhone;
        rect.size.height  += IS_IPHONE5 ? kMoveTableView_iPhone5 : kMoveTableView_iPhone;
        
        if (IS_IPAD)
            rectLogo.origin.y -= kMoveLogo_iPad;
        else
            rectLogo.origin.y -= IS_IPHONE5 ? kMoveLogo_iPhone5 : kMoveLogo_iPhone;
    }
    else
    {
        rect.origin.y     += IS_IPHONE5 ? kMoveTableView_iPhone5 : kMoveTableView_iPhone;
        rect.size.height  -= IS_IPHONE5 ? kMoveTableView_iPhone5 : kMoveTableView_iPhone;
        
        if (IS_IPAD)
            rectLogo.origin.y += kMoveLogo_iPad;
        else
            rectLogo.origin.y += IS_IPHONE5 ? kMoveLogo_iPhone5 : kMoveLogo_iPhone;
        
    }
    self.view.frame  = rect;
    preyImage.frame  = rectLogo;
    
    [UIView commitAnimations];
}

@end
