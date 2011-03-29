//
//  PicturesController.m
//  Prey
//
//  Created by Carlos Yaconi on 29/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//

#import "PicturesController.h"
#import "PicturesControllerDelegate.h"


@implementation PicturesController
@synthesize session;

- (id) init {
	self = [super init];
	if(self != nil){
		pictureTakenAt = [[NSDate dateWithTimeIntervalSince1970:1]retain];
    }
	return self;
}

+(PicturesController *)instance  {
	static PicturesController *instance;
	
	@synchronized(self) {
		if(!instance) {
			instance = [[PicturesController alloc] init];
            
		}
	}
	return instance;
}

- (UIImage*) lastPicture{
    NSTimeInterval lastRunInterval = -[pictureTakenAt timeIntervalSinceNow];
    return lastRunInterval > 60 ? nil : lastPicture;
}
- (void) setLastPicture:(UIImage *) picture {
    lastPicture = picture;
    [pictureTakenAt release];
    pictureTakenAt = [[NSDate date]retain];
}

-(void) take:(NSNumber*)picturesToTake usingCamera:(NSString*)camera {

    // Create the session
    session = [[AVCaptureSession alloc] init];
    // Configure the session to produce lower resolution video frames, if your 
    // processing algorithm can cope. We'll specify medium quality for the
    // chosen device.
    session.sessionPreset = AVCaptureSessionPresetLow;
    
    //numberOfPictures = picturesToTake;
    NSError *error = nil;
    
    // Find a suitable AVCaptureDevice
    AVCaptureDevice *device = nil;
    if (camera){
        
        device = [camera isEqualToString:@"front"]?[self frontFacingCameraIfAvailable]:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    else
        device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device 
                                                                        error:&error];
    if (!input) {
        // Handling the error appropriately.
        return nil;
    }
    [session addInput:input];
    
    // Create a VideoDataOutput and add it to the session
    AVCaptureVideoDataOutput *output = [[[AVCaptureVideoDataOutput alloc] init] autorelease];
    [session addOutput:output];
    
    // Configure your output.
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    PicturesControllerDelegate *delegate = [PicturesControllerDelegate initWithSession:session AndWhenFinishSendImageTo:@selector(setLastPicture:) onTarget:self];
    
    [output setSampleBufferDelegate:delegate queue:queue];
    //[delegate release];
    
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



- (AVCaptureDevice *)frontFacingCameraIfAvailable
{
    //  look at all the video devices and get the first one that's on the front
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices)
    {
        if (device.position == AVCaptureDevicePositionFront)
        {
            captureDevice = device;
            break;
        }
    }
    
    //  couldn't find one on the front, so just get the default video device.
    if ( ! captureDevice)
    {
        captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return captureDevice;
}


- (void)dealloc {
    [session release];
    [pictureTakenAt release];
	[super dealloc];
}

@end
