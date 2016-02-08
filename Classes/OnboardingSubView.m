//
//  OnboardingSubView.m
//  Prey
//
//  Created by Javier Cala Uribe on 6/7/15.
//  Copyright (c) 2015 Fork Ltd. All rights reserved.
//

#import "OnboardingSubView.h"
#import "Constants.h"

@implementation OnboardingSubView

@synthesize tmpRect;

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

- (void)addMessageOnView:(NSString*)message
{
    if (IS_IPAD)
        tmpRect = CGRectMake(84, 600, 600, 340);
    else
        tmpRect = (IS_IPHONE5) ? CGRectMake(10, 340, 300, 170) : CGRectMake(10, 270, 300, 170);
    
    UILabel *storyText = [[UILabel alloc] initWithFrame:tmpRect];
    storyText.font = (IS_IPAD) ? [UIFont fontWithName:@"Roboto" size:27] : [UIFont fontWithName:@"Roboto" size:16];
    storyText.textAlignment = UITextAlignmentCenter;
    storyText.numberOfLines = 6;
    storyText.backgroundColor = [UIColor clearColor];
    storyText.textColor = [UIColor colorWithRed:(245/255.f) green:(245/255.f) blue:(245/255.f) alpha:1];
    storyText.text = message;
    [self addSubview:storyText];
}

// Config PageView 01
- (void)configPageView1:(CGFloat)posYiPhone
{
    [self addMessageOnView:NSLocalizedString(@"Ashley uses Prey on all her devices: her Macbook, her iPhone and iPad. But one day, she was at the wrong place at the wrong time and someone stole her tablet.",nil)];
    
    // Add girl to page
    tmpRect = (IS_IPAD) ? CGRectMake(260, 260, 340, 406) : CGRectMake(130, 130+posYiPhone, 170, 203);
    UIImageView *girlImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ashley1"]];
    girlImage.frame = tmpRect;
    [self insertSubview:girlImage atIndex:101];

    /*
    storyText.alpha = 0;
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn
                     animations:^{ storyText.alpha = 1;}
                     completion:nil];
    */
}

// Config PageView 02
- (void)configPageView2:(CGFloat)posYiPhone
{
    [self addMessageOnView:NSLocalizedString(@"Meet Steve, he steals objects left unattended.",nil)];
}

// Config PageView 03
- (void)configPageView3:(CGFloat)posYiPhone
{
    [self addMessageOnView:NSLocalizedString(@"Losing a device means losing precious data, memories, information and some really expensive equipment.",nil)];
    
    // Add girl to page
    tmpRect = (IS_IPAD) ? CGRectMake(220, 160, 340, 492) : CGRectMake(110, 80+posYiPhone, 170, 246);
    UIImageView *girlImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ashley2"]];
    girlImage.frame = tmpRect;
    [self insertSubview:girlImage atIndex:101];
}

// Config PageView 04
- (void)configPageView4:(CGFloat)posYiPhone
{
    [self addMessageOnView:NSLocalizedString(@"Without him knowing it, Prey is silently capturing pictures, location, and sending the legitimate owner complete reports.\nAshley can also use Prey to remotely lock her device down and wipe her sensitive data.",nil)];
}

// Config PageView 05
- (void)configPageView5:(CGFloat)posYiPhone
{
    [self addMessageOnView:NSLocalizedString(@"Good thing Ashley has PREY activated! She just got the reports from her stolen device, so now the police has accurate evidence to work with.",nil)];
}


// Config PageView 06
- (void)configPageView6:(CGFloat)posYiPhone
{
    [self addMessageOnView:NSLocalizedString(@"With the detailed reports on the missing device, Ashley had more worries, she got her device back.",nil)];
}

// Config PageView 07
- (void)configPageView7:(CGFloat)posYiPhone
{
    [self addMessageOnView:NSLocalizedString(@"Don\'t wait for the worst to happen to take action. Sign up, enter your registration details and set up Prey on your phone.",nil)];
}

#pragma mark Methods

// Methods Page02

- (void)startAnimatePage2:(CGFloat)posYiPhone
{
    // Add theft to page
    tmpRect = (IS_IPAD) ? CGRectMake(260, 240, 340, 402) : CGRectMake(130, 120+posYiPhone, 170, 201);
    UIImageView *girlImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dude"]];
    girlImage.frame = tmpRect;
    [self insertSubview:girlImage atIndex:101];
}

// Methods Page04

- (void)addElementsPage04:(CGFloat)posYiPhone
{
    // Add theft to page
    tmpRect = (IS_IPAD) ? CGRectMake(80, 320, 340, 316) : CGRectMake(40, 160+posYiPhone, 170, 158);
    UIImageView *dudeImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dude2"]];
    dudeImage.tag = kTagDudeRoom;
    dudeImage.frame = tmpRect;
    [self insertSubview:dudeImage atIndex:101];

    NSTimeInterval animationDelay = 1.0f;
    
    
    CGFloat elementPosYiPhone = (IS_IPHONE5) ? 0 : -65;
    // Add Snapshot to page
    tmpRect = (IS_IPAD) ? CGRectMake(260, 120, 200, 214) : CGRectMake(130, 80+elementPosYiPhone, 100, 107);
    UIImageView *featSnap = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"featuresSnapshot"]];
    featSnap.frame = tmpRect;
    featSnap.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [self insertSubview:featSnap atIndex:101];
    [self animateFeatureIcon:featSnap withDelay:animationDelay*0];
    
    // Add Geo to page
    tmpRect = (IS_IPAD) ? CGRectMake(440, 240, 200, 226) : CGRectMake(220, 140+elementPosYiPhone, 100, 113);
    UIImageView *featGeo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"featuresGeo"]];
    featGeo.frame = tmpRect;
    featGeo.transform = CGAffineTransformMakeScale(0, 0);
    [self insertSubview:featGeo atIndex:101];
    [self animateFeatureIcon:featGeo withDelay:animationDelay*1];
    
    // Add Report to page
    tmpRect = (IS_IPAD) ? CGRectMake(420, 460, 200, 226) : CGRectMake(210, 250+elementPosYiPhone, 100, 113);
    UIImageView *featReport = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"featuresReport"]];
    featReport.frame = tmpRect;
    featReport.transform = CGAffineTransformMakeScale(0, 0);
    [self insertSubview:featReport atIndex:101];
    [self animateFeatureIcon:featReport withDelay:animationDelay*2];
}

- (void)animateFeatureIcon:(UIImageView*)image withDelay:(NSTimeInterval)animationDelay
{
    CGFloat scaleX = (IS_IPAD) ? 1.0f : 1.0f;
    CGFloat scaleY = (IS_IPAD) ? 1.0f : 1.0f;
    
    [UIView animateWithDuration:1.0 delay:animationDelay  options:UIViewAnimationOptionBeginFromCurrentState
                     animations:(void (^)(void)) ^{
                         image.transform = CGAffineTransformMakeScale(scaleX, scaleY);
                     }completion:^(BOOL finished){
                     }];
}

// Methods Page05

- (void)addElementsPage05:(CGFloat)posYiPhone
{
    // Add police-2 to page
    tmpRect = (IS_IPAD) ? CGRectMake(440, 280, 300, 304) : CGRectMake(180, 140+posYiPhone, 150, 152); // x:160
    UIImageView *police2Image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"police2"]];
    police2Image.tag = kTagPoliceRoom2;
    police2Image.frame = tmpRect;
    [self insertSubview:police2Image atIndex:0];

    // Add police-1 to page
    tmpRect = (IS_IPAD) ? CGRectMake(470, 380, 260, 252) : CGRectMake(180, 190+posYiPhone, 130, 126);
    UIImageView *police1Image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"police1"]];
    police1Image.tag = kTagPoliceRoom;
    police1Image.frame = tmpRect;
    [self insertSubview:police1Image atIndex:110];
    
    // Add girl to page
    tmpRect = (IS_IPAD) ? CGRectMake(-200, 240, 260, 394) : CGRectMake(-100, 120+posYiPhone, 130, 197);
    UIImageView *girlImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ashley3"]];
    girlImage.frame = tmpRect;
    [self insertSubview:girlImage atIndex:101];
    
    CGFloat moveX = (IS_IPAD) ? 240 : 120;
    CGFloat moveY = (IS_IPAD) ? 0 : 0;
    [UIView animateWithDuration:2.0 delay:0.1f  options:UIViewAnimationOptionBeginFromCurrentState
                     animations:(void (^)(void)) ^{
                         girlImage.transform = CGAffineTransformMakeTranslation(moveX, moveY);
                     }completion:^(BOOL finished){
                     }];
    
    moveX = (IS_IPAD) ? -40 : -20;
    moveY = (IS_IPAD) ? 0 : 0;
    [UIView animateWithDuration:1.0 delay:2.0f  options:UIViewAnimationOptionBeginFromCurrentState
                     animations:(void (^)(void)) ^{
                         police2Image.transform = CGAffineTransformMakeTranslation(moveX, moveY);
                     }completion:^(BOOL finished){
                     }];
}

// Methods Page06

- (void)addElementsPage06:(CGFloat)posYiPhone
{
    /*
    UIView      *tmpView   = [self superview];
    UIImageView *police    = (UIImageView*)[tmpView viewWithTag:kTagPoliceRoom2];
    if (police != nil)
    {
        tmpRect = (IS_IPAD) ? CGRectMake(84, 320, 600, 420) : CGRectMake(160, 140, 150, 152);
        police.frame = tmpRect;
        [police stopAnimating];
    }
    */
    
    // Add Ashley to page
    tmpRect = (IS_IPAD) ? CGRectMake(240, 196, 300, 438) : CGRectMake(120, 98+posYiPhone, 150, 219);
    UIImageView *ashleyImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ashley4"]];
    ashleyImage.tag = kTagAshleyRoom;
    ashleyImage.frame = tmpRect;
    [self insertSubview:ashleyImage atIndex:101];
}

// Methods Page07

- (void)addElementsPage07:(CGFloat)posYiPhone
{
    // Add Ashley to page
    tmpRect = (IS_IPAD) ? CGRectMake(200, 236, 400, 400) : CGRectMake(100, 118+posYiPhone, 200, 200);
    UIImageView *ashleyImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ashley5"]];
    ashleyImage.tag = kTagAshleyStreet;
    ashleyImage.frame = tmpRect;
    [self insertSubview:ashleyImage atIndex:101];
}


@end
