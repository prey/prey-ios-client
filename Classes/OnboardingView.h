//
//  OnboardingView.h
//  Prey
//
//  Created by Javier Cala Uribe on 16/6/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OnboardingView : UIViewController <UIScrollViewDelegate>

- (void)initScrollViewAndPageControl;
- (UIScrollView*)createScrollView:(int)numberPages tagID:(int)value;
- (UIPageControl*)createPageControl:(int)numberPages tagID:(int)value;

@end