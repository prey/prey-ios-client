//
//  OnboardingSubView.h
//  Prey
//
//  Created by Javier Cala Uribe on 6/7/15.
//  Copyright (c) 2015 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NewUserController.h"
#import "OldUserController.h"

@interface OnboardingSubView : UIView

@property (nonatomic) CGRect tmpRect;
@property (nonatomic, strong) UISwitch *cameraSwitch;
@property (nonatomic, strong) UISwitch *locationSwitch;
@property (nonatomic, strong) UISwitch *notifySwitch;
@property (nonatomic, strong) NewUserController *nuController;
@property (nonatomic, strong) OldUserController *ouController;


- (void)configPageView0:(CGFloat)posYiPhone;
- (void)configPageView1:(CGFloat)posYiPhone;
- (void)configPageView2:(CGRect)frameView;
- (void)configPageView3;
- (void)checkCameraAuth;
- (void)checkConfigPage2:(CGFloat)posYiPhone;
- (void)segmentControlAction;
- (void)preloadView;

@end
