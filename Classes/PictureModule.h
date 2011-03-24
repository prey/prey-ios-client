//
//  PictureModule.h
//  Prey
//
//  Created by Carlos Yaconi on 24/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "PreyModule.h"

@interface PictureModule : PreyModule <AVCaptureVideoDataOutputSampleBufferDelegate> {
    int frame;
    AVCaptureSession *session;
}
@property (nonatomic,retain) AVCaptureSession *session;

@end
