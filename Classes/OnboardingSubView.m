//
//  OnboardingSubView.m
//  Prey
//
//  Created by Javier Cala Uribe on 6/7/15.
//  Copyright (c) 2015 Fork Ltd. All rights reserved.
//

#import "OnboardingSubView.h"
#import "PhotoController.h"
#import "DeviceAuth.h"
#import "Constants.h"

@implementation OnboardingSubView

@synthesize cameraSwitch, locationSwitch, notifySwitch, tmpRect;
@synthesize nuController, ouController;

#pragma mark Config PageViews

// Config PageView 00

- (void)configPageView0:(CGFloat)posYiPhone
{
    UIImageView *iconBorder = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"preyIconBorder"]];
    iconBorder.frame = (IS_IPAD) ? CGRectMake(312, 265, 144, 172) : CGRectMake(99.5, 114.5+posYiPhone, 121, 142);
    [self addSubview:iconBorder];
    
    UIImageView *logoType = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logoType"]];
    logoType.frame = (IS_IPAD) ? CGRectMake(279, 470, 210, 42) : CGRectMake(72.5, 285.5+posYiPhone, 175, 35);
    logoType.tag   = kTagLogoType;
    logoType.alpha = 0.7;
    [self addSubview:logoType];
    
    tmpRect = (IS_IPAD) ? CGRectMake(134, 650, 500, 150) : CGRectMake(33, 360+posYiPhone, 255, 75);
    UILabel *welcomeText = [[UILabel alloc] initWithFrame:tmpRect];
    welcomeText.font = (IS_IPAD) ? [UIFont fontWithName:@"Open Sans" size:24] : [UIFont fontWithName:@"Open Sans" size:14];
    welcomeText.textAlignment = UITextAlignmentCenter;
    welcomeText.numberOfLines = 5;
    welcomeText.backgroundColor = [UIColor clearColor];
    welcomeText.textColor = [UIColor colorWithRed:(148/255.f) green:(169/255.f) blue:(183/255.f) alpha:1];
    welcomeText.adjustsFontSizeToFitWidth = YES;
    welcomeText.text = NSLocalizedString(@"Prey will track your laptop, phone and tablet if they ever go missing, whether you're in town or abroad.",nil);
    [self addSubview:welcomeText];
    
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
    [self addSubview:iconBirdLeft];
    
    UIImageView *iconBirdRight = [[UIImageView alloc] initWithImage:rightImageBird];
    iconBirdRight.center = tmpPoint;
    iconBirdRight.layer.anchorPoint = CGPointMake( 0, 0);
    iconBirdRight.alpha = 0.9;
    [self addSubview:iconBirdRight];
    
    
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

// Config PageView 01

- (void)configPageView1:(CGFloat)posYiPhone
{
    tmpRect = (IS_IPAD) ? CGRectMake(194, 120, 380, 100) : CGRectMake(45, 55+posYiPhone, 230, 70);
    UILabel *welcomeText = [[UILabel alloc] initWithFrame:tmpRect];
    welcomeText.font = (IS_IPAD) ? [UIFont fontWithName:@"Roboto" size:36] : [UIFont fontWithName:@"Roboto" size:22];
    welcomeText.textAlignment = UITextAlignmentCenter;
    welcomeText.numberOfLines = 2;
    welcomeText.backgroundColor = [UIColor clearColor];
    welcomeText.textColor = [UIColor colorWithRed:(255/255.f) green:(255/255.f) blue:(255/255.f) alpha:1];
    welcomeText.text = NSLocalizedString(@"Protect your devices from theft",nil);
    [self addSubview:welcomeText];
    
    CGFloat iconEnablePosX = (IS_IPAD) ? 100 : 30;
    tmpRect = (IS_IPAD) ? CGRectMake(iconEnablePosX, 350, 54, 40.5f) : CGRectMake(iconEnablePosX, 210+posYiPhone, 36, 27);
    UIImageView *cameraIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cameraIcon"]];
    cameraIcon.frame = tmpRect;
    [self addSubview:cameraIcon];
    
    tmpRect = (IS_IPAD) ? CGRectMake(iconEnablePosX+11, 530, 33, 54) : CGRectMake(iconEnablePosX+7, 300+posYiPhone, 22, 36);
    UIImageView *locationIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"locationIcon"]];
    locationIcon.frame = tmpRect;
    [self addSubview:locationIcon];
    
    tmpRect = (IS_IPAD) ? CGRectMake(iconEnablePosX, 710, 54, 51) : CGRectMake(iconEnablePosX, 390+posYiPhone, 36, 34);
    UIImageView *notifyIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"notifyIcon"]];
    notifyIcon.frame = tmpRect;
    [self addSubview:notifyIcon];
    
    CGFloat textEnablePosX = (IS_IPAD) ? 230 : 90;
    CGFloat fontZize = (IS_IPAD) ? 26 : 14;
    CGFloat widthText = (IS_IPAD) ? 350 : 150;
    CGFloat heightText = (IS_IPAD) ? 70 : 35;
    
    CGFloat textPosY = (IS_IPAD) ? 340 : 208+posYiPhone;
    UILabel *cameraText = [[UILabel alloc] initWithFrame:CGRectMake(textEnablePosX, textPosY, widthText, heightText)];
    cameraText.font = [UIFont fontWithName:@"Open Sans" size:fontZize];
    cameraText.textAlignment = UITextAlignmentLeft;
    cameraText.backgroundColor = [UIColor clearColor];
    cameraText.textColor = [UIColor colorWithRed:(148/255.f) green:(169/255.f) blue:(183/255.f) alpha:1];
    cameraText.text = NSLocalizedString(@"Enable Camera",nil);
    [self addSubview:cameraText];
    
    textPosY = (IS_IPAD) ? 525 : 300+posYiPhone;
    UILabel *locationText = [[UILabel alloc] initWithFrame:CGRectMake(textEnablePosX, textPosY, widthText, heightText)];
    locationText.font = [UIFont fontWithName:@"Open Sans" size:fontZize];
    locationText.textAlignment = UITextAlignmentLeft;
    locationText.backgroundColor = [UIColor clearColor];
    locationText.textColor = [UIColor colorWithRed:(148/255.f) green:(169/255.f) blue:(183/255.f) alpha:1];
    locationText.text = NSLocalizedString(@"Enable Location",nil);
    [self addSubview:locationText];
    
    textPosY = (IS_IPAD) ? 700 : 388+posYiPhone;
    UILabel *notifyText = [[UILabel alloc] initWithFrame:CGRectMake(textEnablePosX, textPosY, widthText, heightText)];
    notifyText.font = [UIFont fontWithName:@"Open Sans" size:fontZize];
    notifyText.textAlignment = UITextAlignmentLeft;
    notifyText.adjustsFontSizeToFitWidth = YES;
    notifyText.backgroundColor = [UIColor clearColor];
    notifyText.textColor = [UIColor colorWithRed:(148/255.f) green:(169/255.f) blue:(183/255.f) alpha:1];
    notifyText.text = NSLocalizedString(@"Enable Notification",nil);
    [self addSubview:notifyText];
    
    DeviceAuth *config = [DeviceAuth instance];
    CGFloat switchModePosX = (IS_IPAD) ? 640 : 265;
    cameraSwitch = [[UISwitch alloc]init];
    cameraSwitch.center = (IS_IPAD) ? CGPointMake(switchModePosX, 370) : CGPointMake(switchModePosX, 223+posYiPhone);
    cameraSwitch.tag = kTagCameraSwitch;
    [cameraSwitch addTarget:self action:@selector(switchModeState:) forControlEvents:UIControlEventValueChanged];
    [cameraSwitch setOn:config.cameraAuth];
    [self addSubview:cameraSwitch];
    
    locationSwitch = [[UISwitch alloc]init];
    locationSwitch.center = (IS_IPAD) ? CGPointMake(switchModePosX, 555) : CGPointMake(switchModePosX, 315+posYiPhone);
    locationSwitch.tag = kTagLocationSwitch;
    [locationSwitch addTarget:self action:@selector(switchModeState:) forControlEvents:UIControlEventValueChanged];
    [locationSwitch setOn:config.locationAuth];
    [self addSubview:locationSwitch];
    
    notifySwitch = [[UISwitch alloc]init];
    notifySwitch.center = (IS_IPAD) ? CGPointMake(switchModePosX, 740) : CGPointMake(switchModePosX, 406+posYiPhone);
    notifySwitch.tag = kTagNotifySwitch;
    [notifySwitch addTarget:self action:@selector(switchModeState:) forControlEvents:UIControlEventValueChanged];
    [notifySwitch setOn:config.notifyAuth];
    [self addSubview:notifySwitch];
}

// Config PageView 02

- (void)configPageView2:(CGRect)frameView
{
    UIView *flashView = [[UIView alloc] initWithFrame:frameView];
    [flashView setBackgroundColor:[UIColor whiteColor]];
    [flashView setTag:kTagFlashView];
    [flashView setAlpha:0];
    [self addSubview:flashView];
}

// Config PageView 03

- (void)configPageView3
{
    [self setBackgroundColor:[UIColor whiteColor]];
    
    ouController = [[OldUserController alloc] init];
    ouController.title = NSLocalizedString(@"Log in to Prey",nil);
    ouController.view.tag = kTagOldUser;
    ouController.view.center = (IS_IPAD) ? CGPointMake(ouController.view.frame.size.width/2, ouController.view.frame.size.height/2+50) : CGPointMake(ouController.view.frame.size.width/2, ouController.view.frame.size.height/2+50);
    ouController.view.hidden = YES;
    [self addSubview:ouController.view];
    
    
    nuController = [[NewUserController alloc] init];
    nuController.title = NSLocalizedString(@"Create Prey account",nil);
    nuController.view.tag = kTagNewUser;
    nuController.view.center = (IS_IPAD) ? CGPointMake(nuController.view.frame.size.width/2, nuController.view.frame.size.height/2+50) : CGPointMake(nuController.view.frame.size.width/2, nuController.view.frame.size.height/2+50);
    nuController.view.hidden = NO;
    [self addSubview:nuController.view];
    
    
    NSArray *itemArray = [NSArray arrayWithObjects:NSLocalizedString(@"Sign Up",nil), NSLocalizedString(@"Log In",nil), nil];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = (IS_IPAD) ?  CGRectMake(259, 30, 250, 30) : CGRectMake(35, 10, 250, 30);
    segmentedControl.segmentedControlStyle = UISegmentedControlStylePlain;
    [segmentedControl addTarget:self action:@selector(segmentControlAction) forControlEvents: UIControlEventValueChanged];
    segmentedControl.selectedSegmentIndex = 0;
    segmentedControl.tag = kTagSegmentedControl;
    [segmentedControl setBackgroundColor:[UIColor whiteColor]];
    [self addSubview:segmentedControl];
}


#pragma mark Methods

// Methods Page01

- (IBAction)switchModeState:(UISwitch*)modeSwitch
{
    DeviceAuth *config = [DeviceAuth instance];
    
    switch (modeSwitch.tag) {
        case kTagCameraSwitch:
            [modeSwitch setOn:config.cameraAuth];
            break;
        case kTagLocationSwitch:
            if (modeSwitch.on) [config checkLocationDeviceAuthorizationStatus:locationSwitch];
            [modeSwitch setOn:config.locationAuth];
            break;
            
        case kTagNotifySwitch:
            if (modeSwitch.on) [config checkNotifyDeviceAuthorizationStatus:notifySwitch];
            [modeSwitch setOn:config.notifyAuth];
            break;
    }
}

- (void)checkCameraAuth
{
    [[DeviceAuth instance] checkCameraDeviceAuthorizationStatus:cameraSwitch];
}

// Methods Page02

- (void)checkConfigPage2:(CGFloat)posYiPhone
{
    UIView *tmpFlashView  = (UIView*)[self viewWithTag:kTagFlashView];
    
    if (tmpFlashView != nil)
    {
#if !(TARGET_IPHONE_SIMULATOR)
        [self takeFirstPicture];
#endif
        [UIView animateWithDuration:0.5 animations:^{tmpFlashView.alpha = 1.0;}
                         completion:^(BOOL finished){
                             [self animateReportPage2:posYiPhone withFlashView:tmpFlashView];
                         }];
    }
}

- (void)animateReportPage2:(CGFloat)posYiPhone withFlashView:(UIView*)tmpFlashView
{
    [self playShutterSound];
    
    NSString *reportImageFile = (IS_IPAD) ? @"reportImage-ipad" : @"reportImage";
    tmpRect = (IS_IPAD) ? CGRectMake(84, 320, 600, 420) : CGRectMake(10, 170+posYiPhone, 300, 210);
    UIImageView *reportImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:reportImageFile]];
    reportImage.frame = tmpRect;
    [self addSubview:reportImage];
    
    tmpRect = (IS_IPAD) ? CGRectMake(194, 120, 380, 100) : CGRectMake(45, 55+posYiPhone, 230, 70);
    UILabel *theftText = [[UILabel alloc] initWithFrame:tmpRect];
    theftText.font = (IS_IPAD) ? [UIFont fontWithName:@"Roboto" size:36] : [UIFont fontWithName:@"Roboto" size:22];
    theftText.textAlignment = UITextAlignmentCenter;
    theftText.numberOfLines = 2;
    theftText.backgroundColor = [UIColor clearColor];
    theftText.textColor = [UIColor colorWithRed:(255/255.f) green:(255/255.f) blue:(255/255.f) alpha:1];
    theftText.text = NSLocalizedString(@"They can run but they can't hide",nil);
    [self addSubview:theftText];
    
    tmpRect = (IS_IPAD) ? CGRectMake(134, 760, 500, 200) : CGRectMake(33, 405+posYiPhone, 255, 100);
    UILabel *infoText = [[UILabel alloc] initWithFrame:tmpRect];
    infoText.font = (IS_IPAD) ? [UIFont fontWithName:@"Open Sans" size:24] : [UIFont fontWithName:@"Open Sans" size:14];
    infoText.textAlignment = UITextAlignmentCenter;
    infoText.numberOfLines = 5;
    infoText.backgroundColor = [UIColor clearColor];
    infoText.textColor = [UIColor colorWithRed:(148/255.f) green:(169/255.f) blue:(183/255.f) alpha:1];
    infoText.text = NSLocalizedString(@"Sensitive data is gathered only when you request it, and is for your eyes only. Nothing is sent without your permission.",nil);
    [self addSubview:infoText];
    
    
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
    
    [self addSubview:photoImage];
    
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
    UIImageView *photoImage = (UIImageView*)[self viewWithTag:kTagPhotoImage];
    photoImage.image = (pictureTaken != nil) ? pictureTaken : [UIImage imageNamed:@"theft"];
    
    NSLog(@"Picture finished");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"pictureReady" object:nil];
}

// Methods Page03

- (void)preloadView
{
    [nuController keyboardWillShow];
}

- (void)segmentControlAction
{
    UIView *newUserView = (UIView*)[self viewWithTag:kTagNewUser];
    UIView *oldUserView = (UIView*)[self viewWithTag:kTagOldUser];
    
    UISegmentedControl *segment = (UISegmentedControl*)[self viewWithTag:kTagSegmentedControl];
    
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
