//
//  PictureModule.m
//  Prey
//
//  Created by Carlos Yaconi on 24/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//

#import "PictureModule.h"


@implementation PictureModule

@synthesize session;

-(void) main {
    reportToFill.waitForPicture = YES;
    pictures = [[NSMutableArray alloc] init];
    [self setupCaptureSession];
}

// Create and configure a capture session and start it running
- (void)setupCaptureSession 
{
    NSError *error = nil;
    
    // Create the session
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    
    // Configure the session to produce lower resolution video frames, if your 
    // processing algorithm can cope. We'll specify medium quality for the
    // chosen device.
    session.sessionPreset = AVCaptureSessionPresetLow;
    
    // Find a suitable AVCaptureDevice
    AVCaptureDevice *device = [AVCaptureDevice
                               defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device 
                                                                        error:&error];
    if (!input) {
        // Handling the error appropriately.
    }
    [session addInput:input];
    
    // Create a VideoDataOutput and add it to the session
    AVCaptureVideoDataOutput *output = [[[AVCaptureVideoDataOutput alloc] init] autorelease];
    [session addOutput:output];
    
    // Configure your output.
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [output setSampleBufferDelegate:self queue:queue];
    dispatch_release(queue);
    
    // Specify the pixel format
    output.videoSettings = 
    [NSDictionary dictionaryWithObject:
     [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] 
                                forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    
    // If you wish to cap the frame rate to a known value, such as 15 fps, set 
    // minFrameDuration.
    output.minFrameDuration = CMTimeMake(1, 1);
    
    // Start the session running to start the flow of data
    [session startRunning];
    
    // Assign session to an ivar.
    [self setSession:session];
}


// Delegate routine that is called when a sample buffer was written
- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
       fromConnection:(AVCaptureConnection *)connection
{ 
    // Create a UIImage from the sample buffer data
    UIImage *image = [[self imageFromSampleBuffer:sampleBuffer] retain];
    
    if ([pictures count] < 5){
        //UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        LogMessage(@"PictureModule", 10, @"Picture taken!");
        [pictures addObject:image];
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"pictureReady" object:finalImage];
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

- (NSString *) getName {
	return @"webcam";
}


- (NSMutableDictionary *) reportData {
    //parameters: {geo[lng]=-122.084095, geo[alt]=0.0, geo[lat]=37.422006, geo[acc]=0.0, api_key=rod8vlf13jco}
    return nil;
}

- (void)dealloc {
    [session release];
    [pictures release];
	[super dealloc];
}

@end
