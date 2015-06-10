//
//  PostViewController.h
//  Prey
//
//  Created by Javier Cala Uribe on 7/4/15.
//  Copyright (c) 2015 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GAITrackedViewController.h"

@interface PostViewController : GAITrackedViewController <UIWebViewDelegate>

@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) UILabel      *titlePost;
@property (nonatomic,strong) UIImageView  *imagePost;
@property (nonatomic,strong) UIWebView   *contentView;

@end
