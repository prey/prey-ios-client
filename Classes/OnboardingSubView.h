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
- (void)configPageView2:(CGFloat)posYiPhone;
- (void)configPageView3:(CGFloat)posYiPhone;
- (void)configPageView4:(CGFloat)posYiPhone;
- (void)configPageView5:(CGFloat)posYiPhone;
- (void)configPageView6:(CGFloat)posYiPhone;
- (void)configPageView7:(CGFloat)posYiPhone;

- (void)startAnimatePage2:(CGFloat)posYiPhone;

- (void)addElementsPage04:(CGFloat)posYiPhone;
- (void)addElementsPage05:(CGFloat)posYiPhone;
- (void)addElementsPage06:(CGFloat)posYiPhone;
- (void)addElementsPage07:(CGFloat)posYiPhone;

@end
