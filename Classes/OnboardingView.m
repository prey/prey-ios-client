//
//  OnboardingView.m
//  Prey
//
//  Created by Javier Cala Uribe on 16/6/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

#import "OnboardingView.h"
#import "PhotoController.h"
#import "Constants.h"

@interface OnboardingView ()

@end

@implementation OnboardingView

@synthesize nuController, ouController, widthScreen, heightScreen, posYiPhone, posYiPhoneBtn;
@synthesize cameraAuth, locationAuth, notifyAuth, tmpRect;
@synthesize cameraSwitch, locationSwitch, notifySwitch, authLocation;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *bgImage;
    
    if (IS_IPAD) {
        widthScreen   = 768;
        heightScreen  = 1024;
        bgImage       = @"bg-welcome-iPad";
    }
    else
    {
        widthScreen   = 320;
        heightScreen  = (IS_IPHONE5) ? 568 : 480;
        bgImage       = (IS_IPHONE5) ? @"bg-welcome-iPhone5" : @"bg-welcome-iPhone";
        posYiPhone    = (IS_IPHONE5) ? 0 : -45;
        posYiPhoneBtn = (IS_IPHONE5) ? 0 : -80;
    }
    
    UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:bgImage]];
    bg.frame = CGRectMake(0, 0, widthScreen, heightScreen);
    [self.view addSubview:bg];
    
    [self initScrollViewAndPageControl];
    [self initButtons];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark Config UIButton

- (void)initButtons
{
    // Get Started
    tmpRect = (IS_IPAD) ? CGRectMake(259, 900, 250, 60) : CGRectMake(85, 500+posYiPhoneBtn, 150, 40);
    UIButton *startButton = [[UIButton alloc] initWithFrame:tmpRect];
    [self configNewButton:startButton withText:NSLocalizedString(@"Get Rolling",nil) clearBackground:NO];
    startButton.tag = kTagButtonStart;
    [self.view addSubview:startButton];

    
    // Back Button
    tmpRect = (IS_IPAD) ? CGRectMake(40, 950, 43, 37) : CGRectMake(20, 535+posYiPhoneBtn, 24, 21);
    UIButton *backButton = [[UIButton alloc] initWithFrame:tmpRect];
    [backButton setBackgroundImage:[UIImage imageNamed:@"arrowBack"] forState:UIControlStateNormal];
    //[self configNewButton:backButton withText:@"Skip Tour" clearBackground:NO];
    backButton.tag = kTagButtonBack;
    backButton.alpha = 0.0f;
    [backButton addTarget:self action:@selector(changeButtonItem:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    

    // Next Button
    tmpRect = (IS_IPAD) ? CGRectMake(685, 950, 43, 37) : CGRectMake(276, 535+posYiPhoneBtn, 24, 21);
    UIButton *nextButton = [[UIButton alloc] initWithFrame:tmpRect];
    [nextButton setBackgroundImage:[UIImage imageNamed:@"arrowNext"] forState:UIControlStateNormal];
    //[self configNewButton:nextButton withText:@"next >" clearBackground:NO];
    nextButton.tag = kTagButtonNext;
    nextButton.alpha = 0.0f;
    [nextButton addTarget:self action:@selector(changeButtonItem:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:nextButton];
}

- (void)configNewButton:(UIButton*)tmpButton withText:(NSString*)titleText clearBackground:(BOOL)isClearBackground
{
    if (isClearBackground)
    {
        [tmpButton setBackgroundColor:[UIColor clearColor]];
        tmpButton.layer.shadowColor = [UIColor clearColor].CGColor;
        tmpButton.layer.borderColor = [UIColor clearColor].CGColor;
    }
    else
    {
        [tmpButton setBackgroundColor:[UIColor colorWithRed:(23/255.f) green:(117/255.f) blue:(195/255.f) alpha:1]];
        [tmpButton setBackgroundImage:[UIImage imageNamed:@"whitegradient.png"] forState:UIControlStateNormal];
        [tmpButton setBackgroundImage:[UIImage imageNamed:@"whitegradientR.png"] forState:UIControlStateHighlighted];
        tmpButton.layer.shadowColor = [UIColor colorWithWhite:1 alpha:.4].CGColor;
        tmpButton.layer.shadowOffset = CGSizeMake(0, 1);
        tmpButton.layer.shadowOpacity = 0.7;
        tmpButton.layer.shadowRadius = 0;
        tmpButton.layer.borderColor = [UIColor colorWithRed:0 green:(90/255.f) blue:0 alpha:.4].CGColor;
        tmpButton.layer.borderWidth = 1;
        tmpButton.layer.cornerRadius = 3;
    }
    
    [tmpButton setTitle:titleText forState:UIControlStateNormal];
    [[tmpButton titleLabel] setFont:[UIFont boldSystemFontOfSize:17]];
    [[tmpButton titleLabel] setShadowColor:[UIColor colorWithWhite:0 alpha:.4]];
    [[tmpButton titleLabel] setShadowOffset:CGSizeMake(0, 1)];
    
    [tmpButton addTarget:self action:@selector(changeButtonItem:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)changeButtonItem:(UIButton *)sender
{
    UIPageControl *tmpPageControl = (UIPageControl*)[self.view viewWithTag:kTagViewPage];
    UIScrollView  *tmpScrollControl = (UIScrollView*) [self.view viewWithTag:kTagViewScroll];
    CGRect frame   = tmpScrollControl.frame;
    
    if (sender.tag == kTagButtonBack)
        frame.origin.x = frame.size.width * (tmpPageControl.currentPage - 1);
    
    else // Next Button
        frame.origin.x = frame.size.width * (tmpPageControl.currentPage + 1);

    frame.origin.y = 0;
    [tmpScrollControl scrollRectToVisible:frame animated:YES];
}

- (void)changeButtonText:(long)currentPage
{
    UIButton *backButton  = (UIButton*)[self.view viewWithTag:kTagButtonBack];
    UIButton *nextButton  = (UIButton*)[self.view viewWithTag:kTagButtonNext];
    UIButton *startButton = (UIButton*)[self.view viewWithTag:kTagButtonStart];
    UIPageControl *pageControl = (UIPageControl*)[self.view viewWithTag:kTagViewPage];
    
    currentPage = (currentPage < 0) ? 0 : currentPage;
    currentPage = (currentPage > (kNumberPages-1)) ? (kNumberPages-1) : currentPage;
    
    switch (currentPage)
    {
        case 2:
            startButton.hidden = NO;
            backButton.hidden  = NO;
            nextButton.hidden  = NO;
            pageControl.hidden = NO;
            break;
         
        case 3:
            startButton.hidden = YES;
            backButton.hidden  = YES;
            nextButton.hidden  = YES;
            pageControl.hidden = YES;
            break;
    }
}

#pragma mark Config ScrollView - PageControl

- (void)initScrollViewAndPageControl
{
    [self.view addSubview:[self createScrollView:kNumberPages  tagID:kTagViewScroll]];
    [self.view addSubview:[self createPageControl:kNumberPages tagID:kTagViewPage]];
}

- (UIScrollView*)createScrollView:(int)numberPages tagID:(int)value
{
    UIScrollView *tmpScrollView       = [[UIScrollView alloc] initWithFrame:CGRectMake(0,0,widthScreen,heightScreen)];
    //tmpScrollView.backgroundColor     = [UIColor redColor];
    tmpScrollView.contentSize         = CGSizeMake(widthScreen*numberPages, heightScreen);
    tmpScrollView.maximumZoomScale    = 1.0;
    tmpScrollView.minimumZoomScale    = 1.0;
    tmpScrollView.clipsToBounds       = YES;
    tmpScrollView.pagingEnabled       = YES;
    tmpScrollView.delegate            = self;
    tmpScrollView.tag                 = value;
    tmpScrollView.showsHorizontalScrollIndicator = NO;
    
    
    for (int i = 0; i < numberPages; i++)
    {
        UIView *tmpView = [[UIView alloc] initWithFrame:CGRectMake(i*widthScreen, 0, widthScreen, heightScreen)];
        tmpView.tag = i+300;
        [self configViewController:tmpView setNumberOfPage:i];
        [tmpScrollView addSubview:tmpView];
    }
    
    return tmpScrollView;
}

- (UIPageControl*)createPageControl:(int)numberPages tagID:(int)value
{
    tmpRect = (IS_IPAD) ? CGRectMake(334, 960, kPageWidth, kPageHeight) : CGRectMake(110, 538+posYiPhoneBtn, kPageWidth, kPageHeight);
    UIPageControl *tmpPageControl    = [[UIPageControl alloc] initWithFrame:tmpRect];
    //tmpPageControl.backgroundColor = [UIColor colorWithRed:0.9294f green:0.9137f blue:0.8588f alpha:1.0f];
    tmpPageControl.backgroundColor   = [UIColor clearColor];
    tmpPageControl.numberOfPages     = numberPages;
    tmpPageControl.currentPage       = 0;
    tmpPageControl.tag               = value;
    tmpPageControl.alpha             = 0.0f;
    [tmpPageControl addTarget:self action:@selector(changePageSlide:) forControlEvents:UIControlEventValueChanged];
    
    return tmpPageControl;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    float roundedValue = round(scrollView.contentOffset.x / frame.size.width);
    
    UIPageControl *tmpPageControl = (UIPageControl*)[self.view viewWithTag:kTagViewPage];
    tmpPageControl.currentPage = roundedValue;

    if ( (tmpPageControl.currentPage == 0) || (tmpPageControl.currentPage == 1) )
        [self animatePage0:scrollView.contentOffset.x];
    
    if (tmpPageControl.currentPage == 1)
        [self animatePage1:scrollView.contentOffset.x];

    if (tmpPageControl.currentPage == 2)
        [self animatePage2:scrollView.contentOffset.x];

    if (tmpPageControl.currentPage == 3)
        [self animatePage3:scrollView.contentOffset.x];

    
    [self changeButtonText:tmpPageControl.currentPage];
}

- (void)changePageSlide:(id)sender
{
    UIPageControl *tmpPageControl   = (UIPageControl*)sender;
    UIScrollView  *tmpScrollControl = (UIScrollView*) [self.view viewWithTag:kTagViewScroll];
	NSInteger pageIndex = tmpPageControl.currentPage;
    
	// update the scroll view to the appropriate page
    CGRect frame   = tmpScrollControl.frame;
    frame.origin.x = frame.size.width * pageIndex;
    frame.origin.y = 0;
    [tmpScrollControl scrollRectToVisible:frame animated:YES];
}

#pragma mark Config UIView

- (void)configViewController:(UIView*)pageView setNumberOfPage:(int)numberOfPage
{
    switch (numberOfPage)
    {
        case 0:
            [self configPageView0:pageView];
            break;
        case 1:
            [self configPageView1:pageView];
            break;
        case 2:
            [self configPageView2:pageView];
            break;
        case 3:
            [self configPageView3:pageView];
            break;
    }
}

- (void)animatePage0:(CGFloat)scrollMoveX
{
    UIButton *startButton = (UIButton*)[self.view viewWithTag:kTagButtonStart];
    UIButton *backButton  = (UIButton*)[self.view viewWithTag:kTagButtonBack];
    UIButton *nextButton  = (UIButton*)[self.view viewWithTag:kTagButtonNext];
    UIPageControl *pageControl = (UIPageControl*)[self.view viewWithTag:kTagViewPage];
    
    startButton.alpha = 1 - (scrollMoveX/320.0f);
    backButton.alpha  = nextButton.alpha = pageControl.alpha = (scrollMoveX/320.0f);
}

- (void)configPageView0:(UIView*)pageView
{
    UIImageView *iconBorder = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"preyIconBorder"]];
    iconBorder.frame = (IS_IPAD) ? CGRectMake(312, 265, 144, 172) : CGRectMake(99.5, 114.5+posYiPhone, 121, 142);
    [pageView addSubview:iconBorder];

    UIImageView *logoType = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logoType"]];
    logoType.frame = (IS_IPAD) ? CGRectMake(279, 470, 210, 42) : CGRectMake(72.5, 285.5+posYiPhone, 175, 35);
    logoType.tag   = kTagLogoType;
    logoType.alpha = 0.7;
    [pageView addSubview:logoType];
    
    tmpRect = (IS_IPAD) ? CGRectMake(134, 650, 500, 150) : CGRectMake(33, 360+posYiPhone, 255, 75);
    UILabel *welcomeText = [[UILabel alloc] initWithFrame:tmpRect];
    welcomeText.font = (IS_IPAD) ? [UIFont fontWithName:@"Open Sans" size:24] : [UIFont fontWithName:@"Open Sans" size:14];
    welcomeText.textAlignment = UITextAlignmentCenter;
    welcomeText.numberOfLines = 5;
    welcomeText.textColor = [UIColor colorWithRed:(148/255.f) green:(169/255.f) blue:(183/255.f) alpha:1];
    welcomeText.text = NSLocalizedString(@"Prey will track your laptop, phone and tablet if they ever go missing, whether you're in town or abroad.",nil);
    [pageView addSubview:welcomeText];
    
    NSString *iconBirdFile = (IS_IPAD) ? @"preyIconBird-ipad" : @"preyIconBird";
    CGSize tmSize = (IS_IPAD) ? CGSizeMake(96, 128.7f) : CGSizeMake(81, 107);
    tmpRect = (IS_IPAD) ? CGRectMake(0.0f, 0.0f, 96, 128.7f) : CGRectMake(0.0f, 0.0f, 81, 107);
    UIImageView *iconBirdFull = [[UIImageView alloc] initWithImage:[UIImage imageNamed:iconBirdFile]];
    UIGraphicsBeginImageContextWithOptions(tmSize,NO,0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor clearColor] set];
    CGContextFillRect(context, tmpRect);
    [iconBirdFull.layer renderInContext:context];
    UIImage *leftImageBird = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImage* rightImageBird = [UIImage imageWithCGImage:leftImageBird.CGImage scale:leftImageBird.scale
                                            orientation:UIImageOrientationUpMirrored];
    
    //iconBird.frame = CGRectMake(80, 114.5, 162, 107);  Complete image
    //iconBird.transform = CGAffineTransformMakeScale(0.1, 0.1);

    CGPoint tmpPoint = (IS_IPAD) ? CGPointMake(384, 265) : CGPointMake(160, 114.5+posYiPhone);
    UIImageView *iconBirdLeft = [[UIImageView alloc] initWithImage:leftImageBird];
    iconBirdLeft.center = tmpPoint;
    iconBirdLeft.layer.anchorPoint = CGPointMake( 1, 0);
    iconBirdLeft.alpha = 0.7;
    [pageView addSubview:iconBirdLeft];

    UIImageView *iconBirdRight = [[UIImageView alloc] initWithImage:rightImageBird];
    iconBirdRight.center = tmpPoint;
    iconBirdRight.layer.anchorPoint = CGPointMake( 0, 0);
    iconBirdRight.alpha = 0.9;
    [pageView addSubview:iconBirdRight];
    
    
    CATransform3D rotationTransform = CATransform3DIdentity;
    iconBirdLeft.layer.transform  = CATransform3DRotate(rotationTransform, M_PI_2, 0, 1, 0);
    iconBirdRight.layer.transform = CATransform3DRotate(rotationTransform, M_PI_2, 0, -1, 0);
    
    CATransform3D t = CATransform3DIdentity;
    t.m34 = -1/500.0;
    [iconBirdLeft.layer setSublayerTransform:t];
    [iconBirdRight.layer setSublayerTransform:t];
    
    
    [UIImageView beginAnimations:nil context:NULL];
    [UIImageView setAnimationDuration:1.5];
    [UIImageView setAnimationCurve:UIViewAnimationCurveEaseOut];
    //[UIImageView setAnimationRepeatAutoreverses:YES];
    //[UIImageView setAnimationRepeatCount:1.5];
    
    CATransform3D transform       = CATransform3DMakeRotation(M_PI, 0, 1, 0);

    iconBirdLeft.layer.transform  = transform;
    iconBirdRight.layer.transform = transform;

    iconBirdLeft.alpha = 1;
    iconBirdRight.alpha = 1;
    logoType.alpha = 1;
    
    [UIImageView commitAnimations];
}

- (void)animatePage1:(CGFloat)scrollMoveX1
{
    if (scrollMoveX1 == widthScreen*1)
        [self checkCameraDeviceAuthorizationStatus];
}

- (void)configPageView1:(UIView*)pageView
{
    tmpRect = (IS_IPAD) ? CGRectMake(194, 120, 380, 100) : CGRectMake(45, 55+posYiPhone, 230, 70);
    UILabel *welcomeText = [[UILabel alloc] initWithFrame:tmpRect];
    welcomeText.font = (IS_IPAD) ? [UIFont fontWithName:@"Roboto" size:36] : [UIFont fontWithName:@"Roboto" size:22];
    welcomeText.textAlignment = UITextAlignmentCenter;
    welcomeText.numberOfLines = 2;
    welcomeText.textColor = [UIColor colorWithRed:(255/255.f) green:(255/255.f) blue:(255/255.f) alpha:1];
    welcomeText.text = NSLocalizedString(@"Protect your devices from theft",nil);
    [pageView addSubview:welcomeText];
    
    CGFloat iconEnablePosX = (IS_IPAD) ? 100 : 30;
    tmpRect = (IS_IPAD) ? CGRectMake(iconEnablePosX, 350, 54, 40.5f) : CGRectMake(iconEnablePosX, 210+posYiPhone, 36, 27);
    UIImageView *cameraIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cameraIcon"]];
    cameraIcon.frame = tmpRect;
    [pageView addSubview:cameraIcon];
    
    tmpRect = (IS_IPAD) ? CGRectMake(iconEnablePosX+11, 530, 33, 54) : CGRectMake(iconEnablePosX+7, 300+posYiPhone, 22, 36);
    UIImageView *locationIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"locationIcon"]];
    locationIcon.frame = tmpRect;
    [pageView addSubview:locationIcon];

    tmpRect = (IS_IPAD) ? CGRectMake(iconEnablePosX, 710, 54, 51) : CGRectMake(iconEnablePosX, 390+posYiPhone, 36, 34);
    UIImageView *notifyIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"notifyIcon"]];
    notifyIcon.frame = tmpRect;
    [pageView addSubview:notifyIcon];

    CGFloat textEnablePosX = (IS_IPAD) ? 230 : 90;
    CGFloat fontZize = (IS_IPAD) ? 26 : 14;
    CGFloat widthText = (IS_IPAD) ? 350 : 150;
    CGFloat heightText = (IS_IPAD) ? 70 : 35;
    
    CGFloat textPosY = (IS_IPAD) ? 340 : 208+posYiPhone;
    UILabel *cameraText = [[UILabel alloc] initWithFrame:CGRectMake(textEnablePosX, textPosY, widthText, heightText)];
    cameraText.font = [UIFont fontWithName:@"Open Sans" size:fontZize];
    cameraText.textAlignment = UITextAlignmentLeft;
    cameraText.textColor = [UIColor colorWithRed:(148/255.f) green:(169/255.f) blue:(183/255.f) alpha:1];
    cameraText.text = NSLocalizedString(@"Enable Camera",nil);
    [pageView addSubview:cameraText];

    textPosY = (IS_IPAD) ? 525 : 300+posYiPhone;
    UILabel *locationText = [[UILabel alloc] initWithFrame:CGRectMake(textEnablePosX, textPosY, widthText, heightText)];
    locationText.font = [UIFont fontWithName:@"Open Sans" size:fontZize];
    locationText.textAlignment = UITextAlignmentLeft;
    locationText.textColor = [UIColor colorWithRed:(148/255.f) green:(169/255.f) blue:(183/255.f) alpha:1];
    locationText.text = NSLocalizedString(@"Enable Location",nil);
    [pageView addSubview:locationText];

    textPosY = (IS_IPAD) ? 700 : 388+posYiPhone;
    UILabel *notifyText = [[UILabel alloc] initWithFrame:CGRectMake(textEnablePosX, textPosY, widthText, heightText)];
    notifyText.font = [UIFont fontWithName:@"Open Sans" size:fontZize];
    notifyText.textAlignment = UITextAlignmentLeft;
    notifyText.textColor = [UIColor colorWithRed:(148/255.f) green:(169/255.f) blue:(183/255.f) alpha:1];
    notifyText.text = NSLocalizedString(@"Enable Notification",nil);
    [pageView addSubview:notifyText];

    CGFloat switchModePosX = (IS_IPAD) ? 640 : 265;
    cameraSwitch = [[UISwitch alloc]init];
    cameraSwitch.center = (IS_IPAD) ? CGPointMake(switchModePosX, 370) : CGPointMake(switchModePosX, 223+posYiPhone);
    cameraSwitch.tag = kTagCameraSwitch;
    [cameraSwitch addTarget:self action:@selector(cameraModeState:) forControlEvents:UIControlEventValueChanged];
    [cameraSwitch setOn:cameraAuth];
    [pageView addSubview:cameraSwitch];
    
    locationSwitch = [[UISwitch alloc]init];
    locationSwitch.center = (IS_IPAD) ? CGPointMake(switchModePosX, 555) : CGPointMake(switchModePosX, 315+posYiPhone);
    locationSwitch.tag = kTagLocationSwitch;
    [locationSwitch addTarget:self action:@selector(cameraModeState:) forControlEvents:UIControlEventValueChanged];
    [locationSwitch setOn:locationAuth];
    [pageView addSubview:locationSwitch];
    
    notifySwitch = [[UISwitch alloc]init];
    notifySwitch.center = (IS_IPAD) ? CGPointMake(switchModePosX, 740) : CGPointMake(switchModePosX, 406+posYiPhone);
    notifySwitch.tag = kTagNotifySwitch;
    [notifySwitch addTarget:self action:@selector(cameraModeState:) forControlEvents:UIControlEventValueChanged];
    [notifySwitch setOn:notifyAuth];
    [pageView addSubview:notifySwitch];
}

- (IBAction)cameraModeState:(UISwitch*)modeSwitch{
    
    switch (modeSwitch.tag) {
        case kTagCameraSwitch:
            [modeSwitch setOn:cameraAuth];
            break;
        case kTagLocationSwitch:
            if (modeSwitch.on) [self checkLocationDeviceAuthorizationStatus];
            [modeSwitch setOn:locationAuth];
            break;
            
        case kTagNotifySwitch:
            if (modeSwitch.on) [self checkNotifyDeviceAuthorizationStatus];
            [modeSwitch setOn:notifyAuth];
            break;
    }
}
- (void)checkNotifyDeviceAuthorizationStatus
{
    notifyAuth = NO;
    
    if (IS_OS_8_OR_LATER)
    {
        if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications])
        {
            notifyAuth = YES;
            notifySwitch.on = notifyAuth;
        }
    }
    else
    {
        UIRemoteNotificationType notificationTypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        if (notificationTypes & UIRemoteNotificationTypeAlert) {
            notifyAuth = YES;
            notifySwitch.on = notifyAuth;
        }
    }
    
    if (notifyAuth)
        PreyLogMessage(@"App Delegate", 10, @"Alert notification set. Good!");
    else
    {
        PreyLogMessage(@"App Delegate", 10, @"User has disabled alert notifications");
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert notification disabled",nil)
                                                            message:NSLocalizedString(@"You need to grant Prey access to show alert notifications in order to remotely mark it as missing.",nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                  otherButtonTitles:nil];
        [alertView show];
    }

}

- (void)checkLocationDeviceAuthorizationStatus
{
    if ( [CLLocationManager locationServicesEnabled] &&
       ( [CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied) &&
       ( [CLLocationManager authorizationStatus] != kCLAuthorizationStatusRestricted) )
    {
        locationAuth = YES;
        locationSwitch.on = locationAuth;
    }
    else
    {
        authLocation = [[CLLocationManager alloc] init];
        
        if (IS_OS_8_OR_LATER)
        {
            [authLocation requestAlwaysAuthorization];
        }
        else
        {
            [authLocation  startUpdatingLocation];
            [authLocation stopUpdatingLocation];
        }
        locationAuth = NO;
        locationSwitch.on = locationAuth;
    }
}

- (void)checkCameraDeviceAuthorizationStatus
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusAuthorized)
    {
        cameraAuth = YES;
        cameraSwitch.on = cameraAuth;
    }
    else if(authStatus == AVAuthorizationStatusNotDetermined)
    {
        // Camera access not determined. Ask for permission
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted)
            {
                cameraAuth = YES;
                cameraSwitch.on = cameraAuth;
            }
            else
            {
                [self cameraDeniedAccess];
            }
        }];
    }
    else
    {
        [self cameraDeniedAccess];
    }
}

- (void)cameraDeniedAccess
{
    //Not granted access to mediaType
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[UIAlertView alloc] initWithTitle:@"Camera Authorization"
                                    message:@"Prey doesn't have permission to use Camera, please change privacy settings"
                                   delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];

        cameraAuth = NO;
        cameraSwitch.on = cameraAuth;
    });
}


- (void)configPageView2:(UIView*)pageView
{
    UIView *flashView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, widthScreen, heightScreen)];
    [flashView setBackgroundColor:[UIColor whiteColor]];
    [flashView setTag:kTagFlashView];
    [flashView setAlpha:0];
    [pageView addSubview:flashView];
}

- (void)animatePage2:(CGFloat)scrollMoveX
{
    if (scrollMoveX == widthScreen*2)
    {
        // Config page SignUp / LogIn
        UITextField *nameField = (UITextField*)[nuController.view viewWithTag:kTagNameNewUser];
        [nameField resignFirstResponder];
        UITextField *emailField = (UITextField*)[ouController.view viewWithTag:kTagNameOldUser];
        [emailField resignFirstResponder];
        [UIView setAnimationsEnabled:YES];
        [nuController keyboardWillShow];
        
        
        UIView *currentViewK  = (UIView*)[self.view viewWithTag:302];
        UIView *tmpFlashView  = (UIView*)[currentViewK viewWithTag:kTagFlashView];
        
        if (tmpFlashView != nil)
        {
            [self takeFirstPicture];
            
        [UIView animateWithDuration:0.5 animations:^{tmpFlashView.alpha = 1.0;}
                         completion:^(BOOL finished){
                             
                             [self playShutterSound];
                             
                             NSString *reportImageFile = (IS_IPAD) ? @"reportImage-ipad" : @"reportImage";
                             tmpRect = (IS_IPAD) ? CGRectMake(84, 320, 600, 420) : CGRectMake(10, 170+posYiPhone, 300, 210);
                             UIImageView *reportImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:reportImageFile]];
                             reportImage.frame = tmpRect;
                             [currentViewK addSubview:reportImage];
                             
                             tmpRect = (IS_IPAD) ? CGRectMake(194, 120, 380, 100) : CGRectMake(45, 55+posYiPhone, 230, 70);
                             UILabel *theftText = [[UILabel alloc] initWithFrame:tmpRect];
                             theftText.font = (IS_IPAD) ? [UIFont fontWithName:@"Roboto" size:36] : [UIFont fontWithName:@"Roboto" size:22];
                             theftText.textAlignment = UITextAlignmentCenter;
                             theftText.numberOfLines = 2;
                             theftText.textColor = [UIColor colorWithRed:(255/255.f) green:(255/255.f) blue:(255/255.f) alpha:1];
                             theftText.text = NSLocalizedString(@"They can run but they can't hide",nil);
                             [currentViewK addSubview:theftText];

                             tmpRect = (IS_IPAD) ? CGRectMake(134, 760, 500, 200) : CGRectMake(33, 405+posYiPhone, 255, 100);
                             UILabel *infoText = [[UILabel alloc] initWithFrame:tmpRect];
                             infoText.font = (IS_IPAD) ? [UIFont fontWithName:@"Open Sans" size:24] : [UIFont fontWithName:@"Open Sans" size:14];
                             infoText.textAlignment = UITextAlignmentCenter;
                             infoText.numberOfLines = 5;
                             infoText.textColor = [UIColor colorWithRed:(148/255.f) green:(169/255.f) blue:(183/255.f) alpha:1];
                             infoText.text = NSLocalizedString(@"Sensitive data is gathered only when you request it, and is for your eyes only. Nothing is sent without your permission.",nil);
                             [currentViewK addSubview:infoText];


                             tmpRect = (IS_IPAD) ? CGRectMake(0,0,768,1024) : CGRectMake(0,90+posYiPhone,320,428);
                             UIImageView *photoImage = [[UIImageView alloc] initWithFrame:tmpRect];
                             [photoImage setBackgroundColor:[UIColor whiteColor]];
                             photoImage.tag = kTagPhotoImage;
                             CALayer *borderLayer = [CALayer layer];
                             CGRect borderFrame = CGRectMake(0, 0, (photoImage.frame.size.width), (photoImage.frame.size.height));
                             [borderLayer setBackgroundColor:[[UIColor clearColor] CGColor]];
                             [borderLayer setFrame:borderFrame];
                             [borderLayer setCornerRadius:2];
                             [borderLayer setBorderWidth:10];
                             [borderLayer setBorderColor:[[UIColor whiteColor] CGColor]];
                             [photoImage.layer addSublayer:borderLayer];
                             
                             [currentViewK addSubview:photoImage];
                             
                             CGFloat moveX = (IS_IPAD) ? -160 : -81;
                             CGFloat moveY = (IS_IPAD) ? 50 : -13;
                             CGFloat scaleX = (IS_IPAD) ? 0.30f : 0.37f;
                             CGFloat scaleY = (IS_IPAD) ? 0.30f : 0.37f;

                             
                             
                             [UIView animateWithDuration:0.8 delay:0.7  options:UIViewAnimationOptionBeginFromCurrentState
                                              animations:(void (^)(void)) ^{
                                                  
                                                  photoImage.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scaleX, scaleY), CGAffineTransformMakeTranslation(moveX, moveY));
                                              }completion:^(BOOL finished){
                                              }];
                             
                             [UIView animateWithDuration:0.7 delay:0.5 options:nil animations :^{tmpFlashView.alpha = 0.0;}
                                              completion:^(BOOL finished){
                                                  
                                                  [tmpFlashView removeFromSuperview];
                                                  NSLog(@"animation finished");
                                              }];
                         }];
        }
    }
}

- (void)playShutterSound
{
    SystemSoundID soundID;
    NSURL* shutterFile = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                                 pathForResource:@"shutter"
                                                 ofType:@"aiff"]];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)shutterFile, &soundID);
    AudioServicesPlaySystemSound(soundID);
}

- (void)takeFirstPicture
{
 [[PhotoController instance] changeCamera];
    
    [NSTimer scheduledTimerWithTimeInterval:2
                                     target:[PhotoController instance]
                                   selector:@selector(snapStillImage)
                                   userInfo:nil repeats:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pictureReady:)
                                                 name:@"pictureReady"
                                               object:nil];
}

- (void)pictureReady:(NSNotification *)notification
{
    UIImage *pictureTaken = (UIImage*)[notification object];
    
    if (pictureTaken != nil)
    {
        UIView *tmpView = (UIView*)[self.view viewWithTag:302];
        UIImageView *photoImage = (UIImageView*)[tmpView viewWithTag:kTagPhotoImage];
        photoImage.image = pictureTaken;
        
        NSLog(@"Picture finished");
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"pictureReady" object:nil];
}

- (void)configPageView3:(UIView*)pageView
{
    [pageView setBackgroundColor:[UIColor whiteColor]];
    
    ouController = [[OldUserController alloc] init];
    ouController.title = NSLocalizedString(@"Log in to Prey",nil);
    ouController.view.tag = kTagOldUser;
    ouController.view.center = (IS_IPAD) ? CGPointMake(ouController.view.frame.size.width/2, ouController.view.frame.size.height/2+50) : CGPointMake(ouController.view.frame.size.width/2, ouController.view.frame.size.height/2+50);
    ouController.view.hidden = YES;
    [pageView addSubview:ouController.view];
    
    
    nuController = [[NewUserController alloc] init];
    nuController.title = NSLocalizedString(@"Create Prey account",nil);
    nuController.view.tag = kTagNewUser;
    nuController.view.center = (IS_IPAD) ? CGPointMake(nuController.view.frame.size.width/2, nuController.view.frame.size.height/2+50) : CGPointMake(nuController.view.frame.size.width/2, nuController.view.frame.size.height/2+50);
    nuController.view.hidden = NO;
    [pageView addSubview:nuController.view];

    
    NSArray *itemArray = [NSArray arrayWithObjects: @"Sign Up", @"Log In", nil];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = (IS_IPAD) ?  CGRectMake(259, 30, 250, 30) : CGRectMake(35, 10, 250, 30);
    segmentedControl.segmentedControlStyle = UISegmentedControlStylePlain;
    [segmentedControl addTarget:self action:@selector(segmentControlAction:) forControlEvents: UIControlEventValueChanged];
    segmentedControl.selectedSegmentIndex = 0;
    segmentedControl.tag = kTagSegmentedControl;
    [segmentedControl setBackgroundColor:[UIColor whiteColor]];
    [pageView addSubview:segmentedControl];
}

- (void)animatePage3:(CGFloat)scrollMoveX
{
    if (scrollMoveX == widthScreen*3)
    {
        UIView *tmpView = (UIView*)[self.view viewWithTag:303];
        UISegmentedControl *tmpControl = (UISegmentedControl*)[tmpView viewWithTag:kTagSegmentedControl];
        [self segmentControlAction:tmpControl];
    }
}

- (void)segmentControlAction:(UISegmentedControl *)segment
{
    UIView *tmpView = (UIView*)[self.view viewWithTag:303];
    UIView *newUserView = (UIView*)[tmpView viewWithTag:kTagNewUser];
    UIView *oldUserView = (UIView*)[tmpView viewWithTag:kTagOldUser];
    
    UITextField *newField = (UITextField*)[nuController.view viewWithTag:kTagNameNewUser];
    UITextField *oldField = (UITextField*)[ouController.view viewWithTag:kTagNameOldUser];

    [UIView setAnimationsEnabled:NO];
    
    if (segment.selectedSegmentIndex == 0)
    {
        newUserView.hidden = NO;
        oldUserView.hidden = YES;
        
        [newField becomeFirstResponder];
    }
    
    if (segment.selectedSegmentIndex == 1)
    {
        newUserView.hidden = YES;
        oldUserView.hidden = NO;
        
        [oldField becomeFirstResponder];
    }
}

@end
