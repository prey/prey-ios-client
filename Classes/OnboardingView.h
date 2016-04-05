//
//  OnboardingView.h
//  Prey
//
//  Created by Javier Cala Uribe on 16/6/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "GAITrackedViewController.h"

@interface OnboardingView : GAITrackedViewController <UIScrollViewDelegate>

@property (nonatomic) CGFloat widthScreen;
@property (nonatomic) CGFloat heightScreen;
@property (nonatomic) CGFloat posYiPhone;
@property (nonatomic) CGFloat posYiPhoneBtn;
@property (nonatomic) CGRect tmpRect;

- (void)initScrollViewAndPageControl;
- (UIScrollView*)createScrollView:(int)numberPages tagID:(int)value;
- (UIPageControl*)createPageControl:(int)numberPages tagID:(int)value;

@end