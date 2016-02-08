//
//  OnboardingSubView.h
//  Prey
//
//  Created by Javier Cala Uribe on 6/7/15.
//  Copyright (c) 2015 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OnboardingSubView : UIView

@property (nonatomic) CGRect tmpRect;

- (void)configPageView0:(CGFloat)posYiPhone;
- (void)configPageView1:(CGFloat)posYiPhone;
- (void)configPageView2;
- (void)configPageView3;
- (void)configPageView4;
- (void)configPageView5;
- (void)configPageView6;
- (void)configPageView7;

- (void)startAnimatePage2;

- (void)addElementsPage04;
- (void)addElementsPage05;
- (void)addElementsPage06;
- (void)addElementsPage07;

@end
