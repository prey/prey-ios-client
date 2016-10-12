//
//  ReportPhoto.swift
//  Prey
//
//  Created by Javier Cala Uribe on 26/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

protocol PhotoServiceDelegate {
    func photoReceived(_ photos:NSMutableDictionary)
}


// Context
var CapturingStillImageContext = "CapturingStillImageContext"


class ReportPhoto: NSObject {
 
    // MARK: Properties
    
    // Check device authorization
    var isDeviceAuthorized : Bool {
        let authStatus:AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        return (authStatus == AVAuthorizationStatus.authorized) ? true : false
    }
    
    // Check camera number
    var isTwoCameraAvailable : Bool {
        if let videoDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {
            return (videoDevices.count > 1) ? true : false
        }
        return false
    }
    
    // Photo array
    var photoArray    = NSMutableDictionary()
    
    var waitForRequest = false
    
    // ReportPhoto Delegate
    var delegate: PhotoServiceDelegate?
    
    // Session Device
    let sessionDevice:AVCaptureSession
    
    // Session Queue
    let sessionQueue:DispatchQueue
    
    // Device Input
    var videoDeviceInput:AVCaptureDeviceInput?
    
    // Image Output
    let stillImageOutput = AVCaptureStillImageOutput()
    
    
    // MARK: Init
    
    // Init camera session
    override init() {
        
        // Create AVCaptureSession
        sessionDevice = AVCaptureSession()
        
        // Set session to PresetLow
        if sessionDevice.canSetSessionPreset(AVCaptureSessionPresetLow) {
            sessionDevice.sessionPreset = AVCaptureSessionPresetLow
        }

        // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, 
        // or connections from multiple threads at the same time.
        // Why not do all of this on the main queue?
        // AVCaptureSession.startRunning() is a blocking call which can take a long time. We dispatch session setup 
        // to the sessionQueue so that the main queue isn't blocked (which keeps the UI responsive).
        sessionQueue = DispatchQueue(label: "session queue", attributes: [])
    }
    
    // Start Session
    func startSession() {
        
        sessionQueue.async {
            
            // Check error with device
            guard let videoDevice = ReportPhoto.deviceWithPosition(AVCaptureDevicePosition.back) else {
                PreyLogger("Error with AVCaptureDevice")
                self.delegate?.photoReceived(self.photoArray)
                return
            }
            
            // Set AVCaptureDeviceInput
            do {
                self.videoDeviceInput = try AVCaptureDeviceInput(device:videoDevice)
                
                // Add session input
                guard self.sessionDevice.canAddInput(self.videoDeviceInput) else {
                    PreyLogger("Error add session input")
                    self.delegate?.photoReceived(self.photoArray)
                    return
                }
                self.sessionDevice.addInput(self.videoDeviceInput)
                
                // Add session output
                guard self.sessionDevice.canAddOutput(self.stillImageOutput) else {
                    PreyLogger("Error add session output")
                    self.delegate?.photoReceived(self.photoArray)
                    return
                }
                self.stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                self.sessionDevice.addOutput(self.stillImageOutput)
                
                // Start session
                self.sessionDevice.startRunning()
                
                // KeyObserver
                self.addObserver(self, forKeyPath:"stillImageOutput.capturingStillImage", options: ([.old,.new]), context: &CapturingStillImageContext)
                
                // Delay 
                let timeValue = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                self.sessionQueue.asyncAfter(deadline: timeValue, execute: { () -> Void in
                    
                    // Set flash off
                    if let deviceInput = self.videoDeviceInput {
                        self.setFlashModeOff(deviceInput.device)
                    }
                    
                    // Capture a still image
                    if let videoConnection = self.stillImageOutput.connection(withMediaType: AVMediaTypeVideo) {
                        self.stillImageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler:self.checkPhotoCapture(true))
                    } else {
                        // Error: return to delegate
                        self.delegate?.photoReceived(self.photoArray)
                    }
                })
                
            } catch let error {
                PreyLogger("AVCaptureDeviceInput error: \(error.localizedDescription)")
                self.delegate?.photoReceived(self.photoArray)
            }
        }
    }
    
    // Stop Session
    func stopSession() {
        sessionQueue.async {
            
            // Remove current device input
            self.sessionDevice.beginConfiguration()
            
            // Remove session input
            if !self.sessionDevice.canAddInput(self.videoDeviceInput) {
                self.sessionDevice.removeInput(self.videoDeviceInput)
            }
            
            // Remove session output
            if !self.sessionDevice.canAddOutput(self.stillImageOutput) {
                self.sessionDevice.removeOutput(self.stillImageOutput)
            }
            
            // Set session to PresetLow
            if self.sessionDevice.canSetSessionPreset(AVCaptureSessionPresetLow) {
                self.sessionDevice.sessionPreset = AVCaptureSessionPresetLow
            }
            
            // End session config
            self.sessionDevice.commitConfiguration()
            
            // Stop session
            self.sessionDevice.stopRunning()
        }
    }
    
    // MARK: Functions

    // Remove observer
    func removeObserverForImage() {
        // Remove key oberver
        self.removeObserver(self, forKeyPath:"stillImageOutput.capturingStillImage", context:&CapturingStillImageContext)
    }
    
    // Completion Handler to Photo Capture
    func checkPhotoCapture(_ isFirstPhoto:Bool) -> (CMSampleBuffer?, Error?) -> Void {
        
        let actionPhotoCapture: (CMSampleBuffer?, Error?) -> Void = { (sampleBuffer, error) in
            
            guard error == nil else {
                PreyLogger("Error CMSampleBuffer")
                self.delegate?.photoReceived(self.photoArray)
                return
            }
            
            // Change SampleBuffer to NSData
            guard let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer) else {
                PreyLogger("Error CMSampleBuffer to NSData")
                self.delegate?.photoReceived(self.photoArray)
                return
            }
            
            // Save image to Photo Array
            guard let image = UIImage(data: imageData) else {
                PreyLogger("Error NSData to UIImage")
                self.delegate?.photoReceived(self.photoArray)
                return
            }
            
            if isFirstPhoto {
                self.photoArray.removeAllObjects()
                self.photoArray.setObject(image, forKey: "picture" as NSCopying)
            } else {
                self.photoArray.setObject(image, forKey: "screenshot" as NSCopying)
            }
            
            // Check if two camera available
            if self.isTwoCameraAvailable && isFirstPhoto {
                self.sessionQueue.async {
                    self.getSecondPhoto()
                }
            } else {
                // Send Photo Array to Delegate
                self.delegate?.photoReceived(self.photoArray)
            }
        }
     
        return actionPhotoCapture
    }

    // Get second photo
    func getSecondPhoto() {
        
        // Set captureDevice
        guard let videoDevice = ReportPhoto.deviceWithPosition(AVCaptureDevicePosition.front) else {
            PreyLogger("Error with AVCaptureDevice")
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        
        // Set AVCaptureDeviceInput
        do {
            let frontDeviceInput = try AVCaptureDeviceInput(device:videoDevice)
            
            // Remove current device input
            self.sessionDevice.beginConfiguration()
            self.sessionDevice.removeInput(self.videoDeviceInput)
            
            // Add session input
            guard self.sessionDevice.canAddInput(frontDeviceInput) else {
                PreyLogger("Error add session input")
                self.delegate?.photoReceived(self.photoArray)
                return
            }
            self.sessionDevice.addInput(frontDeviceInput)
            self.videoDeviceInput = frontDeviceInput
            
            // Set session to PresetLow
            if self.sessionDevice.canSetSessionPreset(AVCaptureSessionPresetLow) {
                self.sessionDevice.sessionPreset = AVCaptureSessionPresetLow
            }
            
            // End session config
            self.sessionDevice.commitConfiguration()
            
            
            // Delay
            let timeValue = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            self.sessionQueue.asyncAfter(deadline: timeValue, execute: { () -> Void in
                
                // Set flash off
                if let deviceInput = self.videoDeviceInput {
                    self.setFlashModeOff(deviceInput.device)
                }
                
                // Capture a still image
                if let videoConnection = self.stillImageOutput.connection(withMediaType: AVMediaTypeVideo) {
                    self.stillImageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler:self.checkPhotoCapture(false))
                } else {
                    // Error: return to delegate
                    self.delegate?.photoReceived(self.photoArray)
                }
            })
            
        } catch let error {
            PreyLogger("AVCaptureDeviceInput error: \(error.localizedDescription)")
            self.delegate?.photoReceived(self.photoArray)
        }
    }
    
    // Set shutter sound off
    func setShutterSoundOff() {
        var soundID:SystemSoundID = 0
        let pathFile = Bundle.main.path(forResource: "shutter", ofType: "aiff")
        let shutterFile = URL(fileURLWithPath: pathFile!)
        AudioServicesCreateSystemSoundID((shutterFile as CFURL), &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
    
    // Set Flash Off
    func setFlashModeOff(_ device:AVCaptureDevice) {
        
        if (device.hasFlash && device.isFlashModeSupported(AVCaptureFlashMode.off)) {
            // Set AVCaptureFlashMode
            do {
                try device.lockForConfiguration()
                device.flashMode = AVCaptureFlashMode.off
                device.unlockForConfiguration()
                
            } catch let error {
                PreyLogger("AVCaptureFlashMode error: \(error.localizedDescription)")
            }
        }
    }
    
    // Observer Key
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if ( (context == &CapturingStillImageContext) && ((change![NSKeyValueChangeKey.newKey] as AnyObject).boolValue == true) ) {
            // Set shutter sound off
            self.setShutterSoundOff()
        }
    }
    
    // Return AVCaptureDevice
    class func deviceWithPosition(_ position:AVCaptureDevicePosition) -> AVCaptureDevice! {
        
        let devicesArray = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        
        for device in devicesArray! {
            if (device as AnyObject).position == position {
                return device as! AVCaptureDevice
            }
        }
        return nil
    }
}
