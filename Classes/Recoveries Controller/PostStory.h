//
//  PostStory.h
//  Prey
//
//  Created by Javier Cala Uribe on 19/3/15.
//  Copyright (c) 2015 Javier Cala Uribe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PostStory : NSObject

@property (nonatomic,copy) NSString *imageMainUrl;
@property (nonatomic,copy) NSString *title;
@property (nonatomic,copy) NSString *content;
@property (nonatomic, strong) UIImage *image;

@end
