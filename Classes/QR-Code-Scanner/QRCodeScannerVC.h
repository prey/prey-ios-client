//
//  QR-Code-Scanner-VC.h
//  Prey
//
//  Created by Javier Cala Uribe on 30/03/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol QRCodeScannerVCDelegate;

@interface QRCodeScannerVC : UIViewController <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, weak) id<QRCodeScannerVCDelegate> delegate;


@end


@protocol QRCodeScannerVCDelegate <NSObject>

@optional

- (void)scanViewController:(QRCodeScannerVC *)aCtler didSuccessfullyScan:(NSString *) aScannedValue;

@end