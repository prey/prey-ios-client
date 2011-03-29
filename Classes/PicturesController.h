//
//  PicturesController.h
//  Prey
//
//  Created by Carlos Yaconi on 29/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface PicturesController : NSObject {
    AVCaptureSession *session;
    NSInteger *numberOfPictures;
    UIImage *lastPicture;
    NSDate *pictureTakenAt;
}
@property (nonatomic,retain) AVCaptureSession *session;
@property (nonatomic,retain) UIImage *lastPicture;

+(PicturesController *)instance;
-(void) take:(NSNumber*)picturesToTake usingCamera:(NSString*)camera;
@end
