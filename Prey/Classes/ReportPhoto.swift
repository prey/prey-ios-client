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
    func photoReceived(photos:NSMutableDictionary)
}


// Context
var CapturingStillImageContext = "CapturingStillImageContext"


class ReportPhoto: NSObject {
 
    // MARK: Properties
    
    // Check device authorization
    var isDeviceAuthorized : Bool {
        if let authStatus:AVAuthorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) {
            return (authStatus == AVAuthorizationStatus.Authorized) ? true : false
        }
        return false
    }
    
    // Check camera number
    var isTwoCameraAvailable : Bool {
        if let videoDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) {
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
    let sessionQueue:dispatch_queue_t
    
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
        sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL)
    }
    
    // Start Session
    func startSession() {
        
        dispatch_async(sessionQueue) {
            
            // Check error with NSURLSession request
            guard let videoDevice = ReportPhoto.deviceWithPosition(AVCaptureDevicePosition.Back) else {
                PreyLogger("Error with AVCaptureDevice")
                return
            }
            
            // Set AVCaptureDeviceInput
            do {
                self.videoDeviceInput = try AVCaptureDeviceInput(device:videoDevice)
                
                // Add session input
                guard self.sessionDevice.canAddInput(self.videoDeviceInput) else {
                    PreyLogger("Error add session input")
                    return
                }
                self.sessionDevice.addInput(self.videoDeviceInput)
                
                // Add session output
                guard self.sessionDevice.canAddOutput(self.stillImageOutput) else {
                    PreyLogger("Error add session output")
                    return
                }
                self.stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                self.sessionDevice.addOutput(self.stillImageOutput)
                
                // Start session
                self.sessionDevice.startRunning()
                
                // KeyObserver
                self.addObserver(self, forKeyPath:"stillImageOutput.capturingStillImage", options: ([.Old,.New]), context: &CapturingStillImageContext)
                
                // Delay 
                let timeValue = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
                dispatch_after(timeValue, self.sessionQueue, { () -> Void in
                    
                    // Set flash off
                    self.setFlashModeOff(self.videoDeviceInput!.device)
                    
                    // Capture a still image
                    self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo), completionHandler: self.checkPhotoCapture(true))
                })
                
            } catch let error as NSError {
                PreyLogger("AVCaptureDeviceInput error: \(error.localizedDescription)")
            }
        }
    }
    
    // Stop Session
    func stopSession() {
        dispatch_async(sessionQueue) {
            
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
    func checkPhotoCapture(isFirstPhoto:Bool) -> (CMSampleBuffer!, NSError?) -> Void {
        
        let actionPhotoCapture: (CMSampleBuffer!, NSError?) -> Void = { (sampleBuffer, error) in
            
            guard error == nil else {
                PreyLogger("Error CMSampleBuffer")
                return
            }
            
            // Change SampleBuffer to NSData
            guard let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer) else {
                PreyLogger("Error CMSampleBuffer to NSData")
                return
            }
            
            // Save image to Photo Array
            guard let image = UIImage(data: imageData) else {
                PreyLogger("Error NSData to UIImage")
                return
            }
            
            if isFirstPhoto {
                self.photoArray.removeAllObjects()
                self.photoArray.setObject(image, forKey: "picture")
            } else {
                self.photoArray.setObject(image, forKey: "screenshot")
            }
            
            // Check if two camera available
            if self.isTwoCameraAvailable && isFirstPhoto {
                dispatch_async(self.sessionQueue) {
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
        guard let videoDevice = ReportPhoto.deviceWithPosition(AVCaptureDevicePosition.Front) else {
            PreyLogger("Error with AVCaptureDevice")
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
            let timeValue = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
            dispatch_after(timeValue, self.sessionQueue, { () -> Void in
                
                // Set flash off
                self.setFlashModeOff(self.videoDeviceInput!.device)
                
                // Capture a still image
                self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo), completionHandler: self.checkPhotoCapture(false))
            })
            
        } catch let error as NSError {
            PreyLogger("AVCaptureDeviceInput error: \(error.localizedDescription)")
        }
    }
    
    // Set shutter sound off
    func setShutterSoundOff() {
        var soundID:SystemSoundID = 0
        let pathFile = NSBundle.mainBundle().pathForResource("shutter", ofType: "aiff")
        let shutterFile = NSURL(fileURLWithPath: pathFile!)
        AudioServicesCreateSystemSoundID((shutterFile as CFURLRef), &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
    
    // Set Flash Off
    func setFlashModeOff(device:AVCaptureDevice) {
        
        if (device.hasFlash && device.isFlashModeSupported(AVCaptureFlashMode.Off)) {
            // Set AVCaptureFlashMode
            do {
                try device.lockForConfiguration()
                device.flashMode = AVCaptureFlashMode.Off
                device.unlockForConfiguration()
                
            } catch let error as NSError {
                PreyLogger("AVCaptureFlashMode error: \(error.localizedDescription)")
            }
        }
    }
    
    // Observer Key
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if ( (context == &CapturingStillImageContext) && (change![NSKeyValueChangeNewKey]?.boolValue == true) ) {
            // Set shutter sound off
            self.setShutterSoundOff()
        }
    }
    
    // Return AVCaptureDevice
    class func deviceWithPosition(position:AVCaptureDevicePosition) -> AVCaptureDevice! {
        
        let devicesArray = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        
        for device in devicesArray {
            if device.position == position {
                return device as! AVCaptureDevice
            }
        }
        return nil
    }
}