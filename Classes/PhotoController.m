//
//  PhotoController.m
//  Prey-iOS
//
//  Created by Javier Cala on 24/04/2014.
//  Copyright 2014 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "PhotoController.h"
#import <AVFoundation/AVFoundation.h>
#import "Constants.h"

static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;

@interface PhotoController ()

// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;

// Utilities.
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic) BOOL isDeviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) BOOL lockInterfaceRotation;
@property (nonatomic) id runtimeErrorHandlingObserver;

@end

@implementation PhotoController

@synthesize isDeviceAuthorized;

+ (PhotoController *)instance {
    static PhotoController *instance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[PhotoController alloc] init];
    });
    
    return instance;
}

- (id) init
{
	self = [super init];
	if(self != nil)
    {
        PreyLogMessage(@"PhotoController", 10, @"PhotoController instance");
        
        [self start];
        [self inBeginning];
    }
	return self;
}


- (BOOL)isSessionRunningAndDeviceAuthorized
{
	return [[self session] isRunning] && isDeviceAuthorized;
}

+ (NSSet *)keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized
{
	return [NSSet setWithObjects:@"session.running", @"deviceAuthorized", nil];
}

- (void)start
{
	// Create the AVCaptureSession
	AVCaptureSession *session = [[AVCaptureSession alloc] init];
    
    
    if ([session canSetSessionPreset:AVCaptureSessionPresetLow])
        session.sessionPreset = AVCaptureSessionPresetLow;

    
	[self setSession:session];
		
	// Check for device authorization
    isDeviceAuthorized = YES;
	
    if (IS_OS_7_OR_LATER)
        [self checkDeviceAuthorizationStatus];
	
	// In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
	// Why not do all of this on the main queue?
	// -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue so that the main queue isn't blocked (which keeps the UI responsive).
	
	dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
	[self setSessionQueue:sessionQueue];
	
	dispatch_async(sessionQueue, ^{
		[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
		
		NSError *error = nil;
		
		AVCaptureDevice *videoDevice = [PhotoController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
		
		if (error)
		{
			NSLog(@"%@", error);
		}
		
		if ([session canAddInput:videoDeviceInput])
		{
			[session addInput:videoDeviceInput];
			[self setVideoDeviceInput:videoDeviceInput];
		}
        
		AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		if ([session canAddOutput:stillImageOutput])
		{
			[stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
			[session addOutput:stillImageOutput];
			[self setStillImageOutput:stillImageOutput];
		}
	});
}

- (void)inBeginning
{
	dispatch_async([self sessionQueue], ^{
		[self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:SessionRunningAndDeviceAuthorizedContext];
		[self addObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CapturingStillImageContext];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
		
		[[self session] startRunning];
	});
}

- (void)inEnding
{
	dispatch_async([self sessionQueue], ^{
		[[self session] stopRunning];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
		[[NSNotificationCenter defaultCenter] removeObserver:[self runtimeErrorHandlingObserver]];
		
		[self removeObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
		[self removeObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" context:CapturingStillImageContext];
	});
}

- (BOOL)shouldAutorotate
{
	// Disable autorotation of the interface when recording is in progress.
	return ![self lockInterfaceRotation];
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == CapturingStillImageContext)
	{
		BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
		
		if (isCapturingStillImage)
		{
			NSLog(@"isCapturingStillImage");
		}
	}
	else if (context == SessionRunningAndDeviceAuthorizedContext)
	{
		BOOL isRunning = [change[NSKeyValueChangeNewKey] boolValue];
        
        if (isRunning)
            NSLog(@"isRunnig");
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark Actions

- (void)changeCamera
{
    if (isDeviceAuthorized)
    {
        dispatch_async([self sessionQueue], ^{
            AVCaptureDevice *currentVideoDevice = [[self videoDeviceInput] device];
            AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
            AVCaptureDevicePosition currentPosition = [currentVideoDevice position];
            
            switch (currentPosition)
            {
                case AVCaptureDevicePositionUnspecified:
                    preferredPosition = AVCaptureDevicePositionBack;
                    break;
                case AVCaptureDevicePositionBack:
                    preferredPosition = AVCaptureDevicePositionFront;
                    break;
                case AVCaptureDevicePositionFront:
                    preferredPosition = AVCaptureDevicePositionBack;
                    break;
            }
            
            AVCaptureDevice *videoDevice = [PhotoController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
            AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
            
            [[self session] beginConfiguration];
            
            [[self session] removeInput:[self videoDeviceInput]];
            if ([[self session] canAddInput:videoDeviceInput])
            {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
                
                [PhotoController setFlashMode:AVCaptureFlashModeOff forDevice:videoDevice];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:videoDevice];
                
                [[self session] addInput:videoDeviceInput];
                [self setVideoDeviceInput:videoDeviceInput];
            }
            else
            {
                [[self session] addInput:[self videoDeviceInput]];
            }
            
            if ([[self session] canSetSessionPreset:AVCaptureSessionPresetLow])
                [[self session] setSessionPreset:AVCaptureSessionPresetLow];
            
            
            [[self session] commitConfiguration];
        });
    }
}

- (void)snapStillImage
{
    if (isDeviceAuthorized)
    {
        dispatch_async([self sessionQueue], ^{
            // Flash set to Auto for Still Capture
            [PhotoController setFlashMode:AVCaptureFlashModeOff forDevice:[[self videoDeviceInput] device]];
            
            // Turn off shutter sound
            static SystemSoundID soundID = 0;
            if (soundID == 0) {
                NSURL* shutterFile = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                                             pathForResource:@"shutter"
                                                             ofType:@"aiff"]];
                AudioServicesCreateSystemSoundID((__bridge CFURLRef)shutterFile, &soundID);
            }
            AudioServicesPlaySystemSound(soundID);
            
            @try {
                // Capture a still image.
                [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                    
                    if (imageDataSampleBuffer)
                    {
                        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                        UIImage *image = [[UIImage alloc] initWithData:imageData];
                        
                        //UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
                        NSLog(@"saved photo");
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"pictureReady" object:image];
                    }
                }];
            }
            @catch (NSException *exception) {
                NSLog(@"Error saving photo: %@ reason %@", [exception name], [exception reason]);
                [[NSNotificationCenter defaultCenter] postNotificationName:@"pictureReady" object:nil];
            }
            
        });
    }
    else
    {
        NSLog(@"Error saving photo: Device is not Authorized");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"pictureReady" object:nil];
    }
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
	CGPoint devicePoint = CGPointMake(.5, .5);
	[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
	dispatch_async([self sessionQueue], ^{
		AVCaptureDevice *device = [[self videoDeviceInput] device];
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
			{
				[device setFocusMode:focusMode];
				[device setFocusPointOfInterest:point];
			}
			if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
			{
				[device setExposureMode:exposureMode];
				[device setExposurePointOfInterest:point];
			}
			[device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
			[device unlockForConfiguration];
		}
		else
		{
			NSLog(@"%@", error);
		}
	});
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
	if ([device hasFlash] && [device isFlashModeSupported:flashMode])
	{
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			[device setFlashMode:flashMode];
			[device unlockForConfiguration];
		}
		else
		{
			NSLog(@"%@", error);
		}
	}
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
	AVCaptureDevice *captureDevice = [devices firstObject];
	
	for (AVCaptureDevice *device in devices)
	{
		if ([device position] == position)
		{
			captureDevice = device;
			break;
		}
	}
	
	return captureDevice;
}

#pragma mark UI

- (BOOL)isTwoCameraAvailable
{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    int numberCamera = 0;
    BOOL twoCameraAvailable;
    
    for (AVCaptureDevice *device in videoDevices)
    {
        if ( (device.position == AVCaptureDevicePositionBack) || (device.position == AVCaptureDevicePositionFront) )
            numberCamera++;
    }
    
    if (numberCamera == 2)
        twoCameraAvailable = YES;
    else
        twoCameraAvailable = NO;
    
    
    return twoCameraAvailable;
}


- (void)checkDeviceAuthorizationStatus
{
    if (IS_OS_7_OR_LATER)
    {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusAuthorized)
        {
            isDeviceAuthorized = YES;
        }
        else
        {
            isDeviceAuthorized = NO;
            NSString *mediaType = AVMediaTypeVideo;
            
            [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
                if (granted)
                {
                    //Granted access to mediaType
                    isDeviceAuthorized = YES;
                }
                else
                {
                    //Not granted access to mediaType
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        /*[[[UIAlertView alloc] initWithTitle:@"Camera Authorization"
                         message:@"Prey doesn't have permission to use Camera, please change privacy settings"
                         delegate:self
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil] show];
                         */
                        isDeviceAuthorized = NO;
                    });
                }
            }];
        }
    }
}

@end
