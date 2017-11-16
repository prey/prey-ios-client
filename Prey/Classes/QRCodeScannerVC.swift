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

class QRCodeScannerVC: GAITrackedViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    // MARK: Properties
    
    let device  : AVCaptureDevice!          = AVCaptureDevice.default(for: AVMediaType.video)
    let session : AVCaptureSession          = AVCaptureSession()
    let output  : AVCaptureMetadataOutput   = AVCaptureMetadataOutput()

    weak var preview : AVCaptureVideoPreviewLayer!
    
    // MARK: Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // View title for GAnalytics
        self.screenName = "QRCodeScanner"        
        
        // Set background color
        self.view.backgroundColor   = UIColor.black
        
        // Config navigationBar
        let widthScreen             = UIScreen.main.bounds.size.width
        let navBar                  = UINavigationBar(frame:CGRect(x: 0,y: 0,width: widthScreen,height: 44))
        navBar.autoresizingMask     = [.flexibleWidth, .flexibleBottomMargin]
        self.view.addSubview(navBar)
        
        // Config navItem
        let navItem                 = UINavigationItem(title:"Prey Control Panel".localized)
        navItem.leftBarButtonItem   = UIBarButtonItem(barButtonSystemItem:.cancel, target:self, action:#selector(cancel))
        navBar.pushItem(navItem, animated:false)
        
        // Check camera available
        guard isCameraAvailable() else {
            displayErrorAlert("Couldn't add your device".localized,
                              titleMessage:"Error camera isn't available".localized)
            return
        }

        // Config session QR-Code
        do {
            let inputDevice : AVCaptureDeviceInput = try AVCaptureDeviceInput(device:device)
            setupScanner(inputDevice)
            // Start scanning
            startScanning()
            
        } catch let error as NSError{
            PreyLogger("QrCode error: \(error.localizedDescription)")
            displayErrorAlert("Couldn't add your device".localized,
                              titleMessage:"The scanned QR code is invalid".localized)
            return
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Methods
    
    
    // Setup scanner
    func setupScanner(_ input:AVCaptureDeviceInput) {

        // Config session
        session.addOutput(output)
        session.addInput(input)
        
        // Config output
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes  = [AVMetadataObject.ObjectType.qr]
        
        // Config preview
        preview                     = AVCaptureVideoPreviewLayer(session:session)
        preview.videoGravity        = AVLayerVideoGravity.resizeAspectFill
        preview.frame               = CGRect(x: 0, y: 0,width: self.view.frame.size.width, height: self.view.frame.size.height)
        preview.connection?.videoOrientation = .portrait
        self.view.layer.insertSublayer(preview, at:0)

        // Config label
        let screen                  = UIScreen.main.bounds.size
        let widthLbl                = screen.width
        let fontSize:CGFloat        = IS_IPAD ? 16.0 : 12.0
        let message                 = IS_IPAD ? "Visit panel.preyproject.com/qr on your computer and scan the QR code".localized :
                                                "Visit panel.preyproject.com/qr \non your computer and scan the QR code".localized
        
        let infoQR                  = UILabel(frame:CGRect(x: 0, y: screen.height-50, width: widthLbl, height: 50))
        infoQR.textColor            = UIColor(red:0.3019, green:0.3411, blue:0.4, alpha:0.7)
        infoQR.backgroundColor      = UIColor.white
        infoQR.textAlignment        = .center
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
        qrZoneImg.frame             = CGRect(x: qrZonePosX, y: qrZonePosY, width: qrZoneSize, height: qrZoneSize)
        self.view.addSubview(qrZoneImg)
    }
    
    // Success scan
    func successfullyScan(_ scannedValue: NSString) {
        
        let validQr           = "prey?api_key=" as NSString
        let checkQr:NSString  = (scannedValue.length > validQr.length) ? scannedValue.substring(to: validQr.length) as NSString  : "" as NSString
        let apikeyQr:NSString = (scannedValue.length > validQr.length) ? scannedValue.substring(from: validQr.length) as NSString : "" as NSString
    
        stopScanning()
    
        self.dismiss(animated: true, completion: {() -> Void in
        
            if checkQr.isEqual(to: validQr as String) {
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
        return AVCaptureDevice.devices(for: AVMediaType.video).count > 0 ? true : false
    }
    
    @objc func cancel() {
        self.dismiss(animated: true, completion:nil)
    }
    
    // MARK: AVCaptureMetadataOutputObjectsDelegate
    
    // CaptureOutput
    func metadataOutput(_ captureOutput: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
     
        for current in metadataObjects {
            if current is AVMetadataMachineReadableCodeObject {
                if let scannedValue = (current as! AVMetadataMachineReadableCodeObject).stringValue {
                    successfullyScan(scannedValue as NSString)
                }
            }
        }
    }
}

