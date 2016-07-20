//
//  QRCodeScannerVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 19/07/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class QRCodeScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    // MARK: Properties
    
    let device  : AVCaptureDevice           = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    let session : AVCaptureSession          = AVCaptureSession()
    let output  : AVCaptureMetadataOutput   = AVCaptureMetadataOutput()

    weak var preview : AVCaptureVideoPreviewLayer!
    
    // MARK: Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Set background color
        self.view.backgroundColor   = UIColor.blackColor()
        
        // Config navigationBar
        let widthScreen             = UIScreen.mainScreen().bounds.size.width
        let navBar                  = UINavigationBar(frame:CGRectMake(0,0,widthScreen,44))
        navBar.autoresizingMask     = [.FlexibleWidth, .FlexibleBottomMargin]
        self.view.addSubview(navBar)
        
        // Config navItem
        let navItem                 = UINavigationItem(title:"Prey Control Panel".localized)
        navItem.leftBarButtonItem   = UIBarButtonItem(barButtonSystemItem:.Cancel, target:self, action:#selector(cancel))
        navBar.pushNavigationItem(navItem, animated:false)
        
        // Check camera available
        guard isCameraAvailable() else {
            displayErrorAlert("Couldn't add your device".localized,
                              titleMessage:"Error".localized)
            return
        }

        // Config session QR-Code
        do {
            if let inputDevice :AVCaptureDeviceInput = try AVCaptureDeviceInput(device:device) {
                setupScanner(inputDevice)
                // Start scanning
                startScanning()
            }
            
        } catch let error as NSError{
            print("QrCode error: \(error.localizedDescription)")
            displayErrorAlert("Couldn't add your device".localized,
                              titleMessage:"Error".localized)
            return
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Methods
    
    
    // Setup scanner
    func setupScanner(input:AVCaptureDeviceInput) {

        // Config session
        session.addOutput(output)
        session.addInput(input)
        
        // Config output
        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        output.metadataObjectTypes  = [AVMetadataObjectTypeQRCode]
        
        // Config preview
        preview                     = AVCaptureVideoPreviewLayer(session:session)
        preview.videoGravity        = AVLayerVideoGravityResizeAspectFill
        preview.frame               = CGRectMake(0, 0,self.view.frame.size.width, self.view.frame.size.height)
        preview.connection.videoOrientation = .Portrait
        self.view.layer.insertSublayer(preview, atIndex:0)

        // Config label
        let screen                  = UIScreen.mainScreen().bounds.size
        let widthLbl                = screen.width
        let fontSize:CGFloat        = IS_IPAD ? 16.0 : 12.0
        let message                 = IS_IPAD ? "Visit panel.preyproject.com/qr on your computer and scan the QR code".localized :
                                                "Visit panel.preyproject.com/qr \non your computer and scan the QR code".localized
        
        let infoQR                  = UILabel(frame:CGRectMake(0, screen.height-50, widthLbl, 50))
        infoQR.textColor            = UIColor(red:0.3019, green:0.3411, blue:0.4, alpha:0.7)
        infoQR.backgroundColor      = UIColor.whiteColor()
        infoQR.textAlignment        = .Center
        infoQR.font                 = UIFont(name:fontTitilliumRegular, size:fontSize)
        infoQR.text                 = message
        infoQR.numberOfLines        = 2
        infoQR.adjustsFontSizeToFitWidth = true
        self.view.addSubview(infoQR)
        
        // Config QrZone image
        let qrZoneSize              = IS_IPAD ? screen.width*0.6 : screen.width*0.78
        let qrZonePosY              = (screen.height - qrZoneSize)/2
        let qrZonePosX              = (screen.width  - qrZoneSize)/2
        let qrZoneImg               = UIImageView(image:UIImage(named:"QrZone"))
        qrZoneImg.frame             = CGRectMake(qrZonePosX, qrZonePosY, qrZoneSize, qrZoneSize)
        self.view.addSubview(qrZoneImg)
    }
    
    // Success scan
    func successfullyScan(scannedValue: NSString) {
        
        let validQr           = "prey?api_key=" as NSString
        let checkQr:NSString  = (scannedValue.length > validQr.length) ? scannedValue.substringToIndex(validQr.length)   : ""
        let apikeyQr:NSString = (scannedValue.length > validQr.length) ? scannedValue.substringFromIndex(validQr.length) : ""
    
        stopScanning()
    
        self.dismissViewControllerAnimated(true, completion: {() -> Void in
        
            if checkQr.isEqualToString(validQr as String) {
                PreyDeployment.sharedInstance.addDeviceWith(apikeyQr as String, fromQRCode:true)                
            } else {
                displayErrorAlert("The scanned QR code is invalid".localized,
                    titleMessage:"Couldn't add your device".localized)
            }
        })
    }
    
    func startScanning() {
        self.session.startRunning()
    }
    
    func stopScanning() {
        self.session.stopRunning()
    }
    
    func isCameraAvailable() -> Bool {
        return AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo).count > 0 ? true : false
    }
    
    func cancel() {
        self.dismissViewControllerAnimated(true, completion:nil)
    }
    
    // MARK: AVCaptureMetadataOutputObjectsDelegate
    
    // CaptureOutput
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
     
        for current in metadataObjects {
            if current.isKindOfClass(AVMetadataMachineReadableCodeObject) {
                let scannedValue = (current as! AVMetadataMachineReadableCodeObject).stringValue
                successfullyScan(scannedValue)
            }
        }
    }
}

