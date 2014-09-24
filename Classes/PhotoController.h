//
//  PhotoController.h
//  Prey-iOS
//
//  Created by Javier Cala on 24/04/2014.
//  Copyright 2014 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <UIKit/UIKit.h>

@interface PhotoController : NSObject

+ (PhotoController *)instance;
- (void)snapStillImage;
- (void)changeCamera;
- (BOOL)isTwoCameraAvailable;

@end
