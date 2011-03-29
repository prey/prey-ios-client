//
//  PicturesControllerDelegate.h
//  Prey
//
//  Created by Carlos Yaconi on 29/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface PicturesControllerDelegate : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> {
    NSMutableArray *pictures;
    SEL methodToInvoke;
    NSObject *targetObject;
    AVCaptureSession *session;
}

@property (nonatomic,retain) NSObject *targetObject;
@property (nonatomic) SEL methodToInvoke;
@property (nonatomic,retain) AVCaptureSession *session;

+ (id) initWithSession:(AVCaptureSession*)session AndWhenFinishSendImageTo:(SEL)method onTarget:(id)target;
@end
