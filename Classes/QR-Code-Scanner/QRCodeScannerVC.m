//
//  QR-Code-Scanner-VC.m
//  Prey
//
//  Created by Javier Cala Uribe on 30/03/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

#import "QRCodeScannerVC.h"
#import "PreyDeployment.h"
#import "PreyRestHttp.h"
#import "Constants.h"

@interface QRCodeScannerVC ()

@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureMetadataOutput *output;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preview;

@end

@implementation QRCodeScannerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:[UIColor redColor]];
    
    CGFloat widthScreen     = [[UIScreen mainScreen] bounds].size.width;
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, widthScreen, 44)];
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:navBar];
    
    UINavigationItem  *navItem = [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Prey Control Panel", nil)];
    navItem.leftBarButtonItem  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                               target:self action:@selector(cancel:)];
    [navBar pushNavigationItem:navItem animated: NO];

    if ([self isCameraAvailable]) {
        // config session QR-Code
        [self setupScanner];
        
        // start scannning
        [self startScanning];        
    }
}

- (void)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (BOOL)isCameraAvailable;
{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    return [videoDevices count] > 0;
}

- (void)startScanning {
    [self.session startRunning];
}

- (void)stopScanning {
    [self.session stopRunning];
}

- (void) setupScanner {
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
    self.session = [[AVCaptureSession alloc] init];
    
    self.output = [[AVCaptureMetadataOutput alloc] init];
    [self.session addOutput:self.output];
    [self.session addInput:self.input];
    
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    self.output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    
    self.preview                    = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.preview.videoGravity       = AVLayerVideoGravityResizeAspectFill;
    self.preview.frame              = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    AVCaptureConnection *con        = self.preview.connection;
    con.videoOrientation            = AVCaptureVideoOrientationPortrait;
    
    [self.view.layer insertSublayer:self.preview atIndex:0];
    
    CGSize  screen      = [[UIScreen mainScreen] bounds].size;
    CGFloat widthLbl    = screen.width;
    CGFloat fontSize    = (IS_IPAD) ? 16.f : 12.f;
    NSString *message   = (IS_IPAD) ?   NSLocalizedString(@"Visit panel.preyproject.com/qr on your computer and scan the QR code",nil) :
                                        NSLocalizedString(@"Visit panel.preyproject.com/qr \non your computer and scan the QR code",nil);
    
    UILabel *infoQR         = [[UILabel alloc] initWithFrame:CGRectMake(0, screen.height-50, widthLbl, 50)];
    infoQR.textColor        = [UIColor colorWithRed:.3019f green:.3411f blue:.4f alpha:0.7f];
    infoQR.backgroundColor  = [UIColor whiteColor];
    infoQR.textAlignment    = NSTextAlignmentCenter;
    infoQR.font             = [UIFont fontWithName:@"OpenSans-Bold" size:fontSize];
    infoQR.text             = message;
    infoQR.numberOfLines    = 2;
    infoQR.adjustsFontSizeToFitWidth = YES;
    
    [self.view addSubview:infoQR];
    
    CGFloat qrZoneSize  = (IS_IPAD) ? screen.width*0.6f : screen.width*0.78f;
    CGFloat qrZonePosY  = (screen.height - qrZoneSize)/2;
    CGFloat qrZonePosX  = (screen.width  - qrZoneSize)/2;
    UIImageView *qrZone = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"qr-zone"]];
    qrZone.frame        = CGRectMake(qrZonePosX, qrZonePosY, qrZoneSize, qrZoneSize);
    
    [self.view addSubview:qrZone];
}

#pragma mark AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection
{
    for(AVMetadataObject *current in metadataObjects)
    {
        if ([current isKindOfClass:[AVMetadataMachineReadableCodeObject class]])
        {
            if ([self respondsToSelector:@selector(scanViewController:didSuccessfullyScan:)])
            {
                NSString *scannedValue = [((AVMetadataMachineReadableCodeObject *) current) stringValue];
                [self scanViewController:self didSuccessfullyScan:scannedValue];
            }
        }
    }
}

- (void)scanViewController:(QRCodeScannerVC *)aCtler didSuccessfullyScan:(NSString *)aScannedValue {

    //NSLog(@"Code: %@", aScannedValue);
    NSString *validQr  = @"prey?api_key=";
    NSString *checkQr  = (aScannedValue.length > validQr.length) ? [aScannedValue substringToIndex:validQr.length]   : @"";
    NSString *apikeyQr = (aScannedValue.length > validQr.length) ? [aScannedValue substringFromIndex:validQr.length] : @"";
    
    [self stopScanning];

    [self dismissViewControllerAnimated:YES completion:^{
        
        if ([checkQr isEqualToString:validQr])
            [[PreyDeployment instance] addDeviceForApiKey:apikeyQr fromQRCode:YES];
        else
            [PreyRestHttp displayErrorAlert:NSLocalizedString(@"The scanned QR code is invalid", nil)
                                      title:NSLocalizedString(@"Couldn't add your device",nil)];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
