//
//  PicturesController.h
//  Prey-iOS
//
//  Created by Carlos Yaconi on 29/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface PicturesController : NSObject {
    AVCaptureSession *session;
    NSInteger *numberOfPictures;
    UIImage *lastPictureTaken;
    NSDate *pictureTakenAt;
}
@property (nonatomic,retain) AVCaptureSession *session;
@property (nonatomic,retain) UIImage *lastPictureTaken;

+(PicturesController *)instance;
-(void) takePictureAndNotifyTo:(SEL)method onTarget:(id)target;
- (UIImage*) lastPicture;
@end
