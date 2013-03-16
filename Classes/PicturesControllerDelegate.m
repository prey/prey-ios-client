//
//  PicturesControllerDelegate.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 29/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "PicturesControllerDelegate.h"



@implementation PicturesControllerDelegate
@synthesize methodToInvoke,targetObject,session;

- (id) init {
	self = [super init];
	if(self != nil){
		pictures = [[NSMutableArray alloc] init];
    }
	return self;
}

+ (id) initWithSession:(AVCaptureSession*)session AndWhenFinishSendImageTo:(SEL)method onTarget:(id)target {
    PicturesControllerDelegate *delegate = [[[PicturesControllerDelegate alloc] init] autorelease];
    delegate.methodToInvoke = method;
    delegate.targetObject = target;
    delegate.session = session;
    return delegate;
}

// Delegate routine that is called when a sample buffer was written
- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
       fromConnection:(AVCaptureConnection *)connection
{ 
    // Create a UIImage from the sample buffer data
    UIImage *image = [[self imageFromSampleBuffer:sampleBuffer] retain];
    
    if ([pictures count] < 1){
        //UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        PreyLogMessage(@"PicturesControllerDelegate", 10, @"Picture taken!");
        [pictures addObject:[self rotateImage:image]];
    }
    else{
        [self joinImagesAndNotify];
        [self.session stopRunning];
    }
    
    [image release];
    
}

- (void) joinImagesAndNotify {
    CGSize pictureSize = [(UIImage*)[pictures objectAtIndex:0] size];
    CGSize finalSize = CGSizeMake(pictureSize.width, pictureSize.height * [pictures count]);
    UIGraphicsBeginImageContext(finalSize);
    int i = 0;
    for (UIImage *picture  in pictures) {
        CGPoint point = CGPointMake(0, i*pictureSize.height);
        [picture drawAtPoint:point];
        i++;
    }
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [targetObject performSelector:methodToInvoke withObject:finalImage];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"pictureReady" object:finalImage];
}


-(UIImage *)rotateImage:(UIImage *)image {
    
    int orient = image.imageOrientation;
    
    UIImageView *imageView = [[[UIImageView alloc] init] autorelease];
    
    UIImage *imageCopy = [[UIImage alloc] initWithCGImage:image.CGImage];
    
    
    switch (orient) {
        case UIImageOrientationLeft:
            imageView.transform = CGAffineTransformMakeRotation(3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationRight:
            imageView.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
            break;
        case UIImageOrientationDown: //EXIF = 3
            imageView.transform = CGAffineTransformMakeRotation(M_PI);
        default:
            break;
    }
    
    imageView.image = imageCopy;
    [imageCopy release];
    
    return (imageView.image);
}

// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer 
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0); 
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer); 
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer); 
    size_t height = CVPixelBufferGetHeight(imageBuffer); 
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, 
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst); 
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context); 
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context); 
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

- (void) dealloc {
    [pictures release];
    [targetObject release];
    [session release];
    [super dealloc];
}
@end
