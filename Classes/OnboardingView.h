//
//  OnboardingView.h
//  Prey
//
//  Created by Javier Cala Uribe on 16/6/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import "NewUserController.h"
#import "OldUserController.h"

@interface OnboardingView : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) NewUserController *nuController;
@property (nonatomic, strong) OldUserController *ouController;
@property (nonatomic) CGFloat widthScreen;
@property (nonatomic) CGFloat heightScreen;
@property (nonatomic) BOOL cameraAuth;
@property (nonatomic) BOOL locationAuth;
@property (nonatomic) BOOL notifyAuth;
@property (nonatomic) CGRect tmpRect;
@property (nonatomic) CLLocationManager *authLocation;
@property (nonatomic, strong) UISwitch *cameraSwitch;
@property (nonatomic, strong) UISwitch *locationSwitch;
@property (nonatomic, strong) UISwitch *notifySwitch;


- (void)initScrollViewAndPageControl;
- (UIScrollView*)createScrollView:(int)numberPages tagID:(int)value;
- (UIPageControl*)createPageControl:(int)numberPages tagID:(int)value;

@end