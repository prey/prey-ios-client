//
//  ReportPhoto.swift
//  Prey
//
//  Created by Javier Cala Uribe on 26/05/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

protocol PhotoServiceDelegate {
    func photoReceived(_ photos:NSMutableDictionary)
}


class ReportPhoto: NSObject {
 
    // MARK: Properties
    
    // Check device authorization
    var isDeviceAuthorized : Bool {
        let authStatus:AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        return (authStatus == AVAuthorizationStatus.authorized) ? true : false
    }
    
    // Check camera number
    var isTwoCameraAvailable : Bool {
        let videoDevices = AVCaptureDevice.devices(for: AVMediaType.video)
        return (videoDevices.count > 1) ? true : false
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
    
    
    // MARK: Init
    
    // Init camera session
    override init() {
        
        // Create AVCaptureSession
        sessionDevice = AVCaptureSession()
        
        // Set session to PresetLow
        if sessionDevice.canSetSessionPreset(AVCaptureSession.Preset.low) {
            sessionDevice.sessionPreset = AVCaptureSession.Preset.low
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
    }
    
    // Stop Session
    func stopSession() {
    }
    
    // MARK: Functions

    // Remove observer
    func removeObserver() {
        NotificationCenter.default.removeObserver(self)
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
        
        if (device.hasFlash && device.isFlashModeSupported(AVCaptureDevice.FlashMode.off)) {
            // Set AVCaptureFlashMode
            do {
                try device.lockForConfiguration()
                device.flashMode = AVCaptureDevice.FlashMode.off
                device.unlockForConfiguration()
                
            } catch let error {
                PreyLogger("AVCaptureFlashMode error: \(error.localizedDescription)")
            }
        }
    }
    
    // Observer Key
    @objc func sessionRuntimeError(notification: NSNotification) {
        PreyLogger("Capture session runtime error")
        self.delegate?.photoReceived(self.photoArray)
    }

    @objc func sessionWasInterrupted(notification: NSNotification) {
        PreyLogger("Capture session interrupted")
        self.delegate?.photoReceived(self.photoArray)
    }
    
    // Return AVCaptureDevice
    class func deviceWithPosition(_ position:AVCaptureDevice.Position) -> AVCaptureDevice? {
        // Get devices array
        let devicesArray = AVCaptureDevice.devices(for: AVMediaType.video)
        
        // Search for device
        for device in devicesArray {
            if device.position == position {
                return device
            }
        }
        return nil
    }
}

// ====
// MARK: ReportPhotoiOS10
// ====
@available(iOS 10.0, *)
class ReportPhotoiOS10: ReportPhoto, AVCapturePhotoCaptureDelegate {
    
    // MARK: Properties
    
    private var isFirstPhoto = true
    
    // Photo Output
    private let photoOutput = AVCapturePhotoOutput()
    
    // MARK: Init
    
    // Start Session
    override func startSession() {
        sessionQueue.async {
            self.getFirstPhoto()
        }
    }
    
    // Stop Session
    override func stopSession() {
        sessionQueue.async {
            
            // Remove current device input
            self.sessionDevice.beginConfiguration()
            
            // Remove session input
            if let deviceInput = self.videoDeviceInput {
                if !self.sessionDevice.canAddInput(deviceInput) {
                    self.sessionDevice.removeInput(deviceInput)
                }
            }
            
            // Remove session output
            if !self.sessionDevice.canAddOutput(self.photoOutput) {
                self.sessionDevice.removeOutput(self.photoOutput)
            }
            
            // Set session to PresetLow
            if self.sessionDevice.canSetSessionPreset(AVCaptureSession.Preset.low) {
                self.sessionDevice.sessionPreset = AVCaptureSession.Preset.low
            }
            
            // Disable wide-gamut color
            self.sessionDevice.automaticallyConfiguresCaptureDeviceForWideColor = false
            
            // End session config
            self.sessionDevice.commitConfiguration()
            
            // Stop session
            self.sessionDevice.stopRunning()
        }
    }
    
    // MARK: Functions
    
    // Get first photo
    func getFirstPhoto() {
        // Check error with device
        guard let videoDevice = ReportPhoto.deviceWithPosition(AVCaptureDevice.Position.back) else {
            PreyLogger("Error with AVCaptureDevice")
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        
        // Set AVCaptureDeviceInput
        do {
            self.videoDeviceInput = try AVCaptureDeviceInput(device:videoDevice)
            
            // Check videoDeviceInput
            guard let videoDevInput = self.videoDeviceInput else {
                PreyLogger("Error videoDeviceInput")
                self.delegate?.photoReceived(self.photoArray)
                return
            }
            
            // Add session input
            guard self.sessionDevice.canAddInput(videoDevInput) else {
                PreyLogger("Error add session input")
                self.delegate?.photoReceived(self.photoArray)
                return
            }
            self.sessionDevice.addInput(videoDevInput)
            
        } catch let error {
            PreyLogger("AVCaptureDeviceInput error: \(error.localizedDescription)")
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        // Add session output
        guard self.sessionDevice.canAddOutput(self.photoOutput) else {
            PreyLogger("Error add session output")
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        self.sessionDevice.addOutput(self.photoOutput)

        // Disable wide-gamut color
        self.sessionDevice.automaticallyConfiguresCaptureDeviceForWideColor = false
        
        // Start session
        self.sessionDevice.startRunning()
        
        // KeyObserver
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.sessionRuntimeError),
                                               name: .AVCaptureSessionRuntimeError,
                                               object: self.sessionDevice)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.sessionWasInterrupted),
                                               name: .AVCaptureSessionWasInterrupted,
                                               object: self.sessionDevice)
        
        // Delay
        let timeValue = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        self.sessionQueue.asyncAfter(deadline: timeValue, execute: { () -> Void in
            // Capture a still image
            self.takePicture(true)
        })
    }
    
    // Get second photo
    func getSecondPhoto() {
        
        // Set captureDevice
        guard let videoDevice = ReportPhoto.deviceWithPosition(AVCaptureDevice.Position.front) else {
            PreyLogger("Error with AVCaptureDevice")
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        
        // Set AVCaptureDeviceInput
        do {
            let frontDeviceInput = try AVCaptureDeviceInput(device:videoDevice)
            
            // Remove current device input
            self.sessionDevice.beginConfiguration()
            if let deviceInput = self.videoDeviceInput {
                self.sessionDevice.removeInput(deviceInput)
            }
            
            // Add session input
            guard self.sessionDevice.canAddInput(frontDeviceInput) else {
                PreyLogger("Error add session input")
                self.delegate?.photoReceived(self.photoArray)
                return
            }
            self.sessionDevice.addInput(frontDeviceInput)
            self.videoDeviceInput = frontDeviceInput
            
            // Set session to PresetLow
            if self.sessionDevice.canSetSessionPreset(AVCaptureSession.Preset.low) {
                self.sessionDevice.sessionPreset = AVCaptureSession.Preset.low
            }
            
            // Disable wide-gamut color
            self.sessionDevice.automaticallyConfiguresCaptureDeviceForWideColor = false
            
            // End session config
            self.sessionDevice.commitConfiguration()
            
            
            // Delay
            let timeValue = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            self.sessionQueue.asyncAfter(deadline: timeValue, execute: { () -> Void in
                // Capture a still image
                self.takePicture(false)
            })
            
        } catch let error {
            PreyLogger("AVCaptureDeviceInput error: \(error.localizedDescription)")
            self.delegate?.photoReceived(self.photoArray)
        }
    }
    
    // Capture a still image
    func takePicture(_ isFirstPhoto:Bool) {
        self.isFirstPhoto = isFirstPhoto
        // Set flash off
        if let deviceInput = self.videoDeviceInput {
            self.setFlashModeOff(deviceInput.device)
        }
        // Capture a still image
        guard let videoConnection = self.photoOutput.connection(with: AVMediaType.video) else {
            // Error: return to delegate
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        guard videoConnection.isEnabled else {
            // Error: return to delegate
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        guard videoConnection.isActive else {
            // Error: return to delegate
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        
        let photoSettings = AVCapturePhotoSettings()
        self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    
    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {

        guard error == nil else {
            PreyLogger("Error AVCapturePhotoOutput")
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            PreyLogger("Error CMSampleBuffer to NSData")
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        
        self.saveImagePhotoArray(imageData: imageData)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        guard error == nil else {
            PreyLogger("Error CMSampleBuffer")
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        
        // Change SampleBuffer to NSData
        guard let sampleBuffer = photoSampleBuffer else {
            PreyLogger("Error CMSampleBuffer")
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        guard let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: nil) else {
            PreyLogger("Error CMSampleBuffer to NSData")
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        self.saveImagePhotoArray(imageData: imageData)
    }
    
    // Save image to Photo Array with memory optimization
    func saveImagePhotoArray(imageData: Data) {
        // Create a downsampled image to reduce memory usage
        guard let image = downsampleImage(imageData, to: CGSize(width: 1024, height: 768)) else {
            PreyLogger("Error creating image from data")
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        
        if self.isFirstPhoto {
            self.photoArray.removeAllObjects()
            self.photoArray.setObject(image, forKey: "picture" as NSCopying)
        } else {
            self.photoArray.setObject(image, forKey: "screenshot" as NSCopying)
        }
        
        // Check if two camera available
        if self.isTwoCameraAvailable && self.isFirstPhoto {
            self.sessionQueue.async {
                self.getSecondPhoto()
            }
        } else {
            // Send Photo Array to Delegate
            self.delegate?.photoReceived(self.photoArray)
        }
    }
    
    // Downsamples an image from data to a specified size - much more memory efficient
    private func downsampleImage(_ imageData: Data, to targetSize: CGSize) -> UIImage? {
        // Create a source from data
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            return nil
        }
        
        // Calculate the max dimension
        let maxDimension = max(targetSize.width, targetSize.height)
        
        // Create thumbnail options specifying the downsampling
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        
        // Create the thumbnail
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return UIImage(data: imageData, scale: 1.0)
        }
        
        // Return UIImage from the downsampled CGImage
        return UIImage(cgImage: thumbnail)
    }
}



// ====
// MARK: ReportPhotoiOS8
// ====
class ReportPhotoiOS8: ReportPhoto {
    
    // MARK: Properties
    
    // Image Output
    @objc dynamic var stillImageOutput = AVCaptureStillImageOutput()
    
    // MARK: Init
    
    // Start Session
    override func startSession() {
        sessionQueue.async {
            self.getFirstPhoto()
        }
    }
    
    // Stop Session
    override func stopSession() {
        sessionQueue.async {
            
            // Remove current device input
            self.sessionDevice.beginConfiguration()
            
            // Remove session input
            if let deviceInput = self.videoDeviceInput {
                if !self.sessionDevice.canAddInput(deviceInput) {
                    self.sessionDevice.removeInput(deviceInput)
                }
            }
            
            // Remove session output
            if !self.sessionDevice.canAddOutput(self.stillImageOutput) {
                self.sessionDevice.removeOutput(self.stillImageOutput)
            }
            
            // Set session to PresetLow
            if self.sessionDevice.canSetSessionPreset(AVCaptureSession.Preset.low) {
                self.sessionDevice.sessionPreset = AVCaptureSession.Preset.low
            }
            
            // End session config
            self.sessionDevice.commitConfiguration()
            
            // Stop session
            self.sessionDevice.stopRunning()
        }
    }
    
    // MARK: Functions
    
    // Get first photo
    func getFirstPhoto() {
        // Check error with device
        guard let videoDevice = ReportPhoto.deviceWithPosition(AVCaptureDevice.Position.back) else {
            PreyLogger("Error with AVCaptureDevice")
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        
        // Set AVCaptureDeviceInput
        do {
            self.videoDeviceInput = try AVCaptureDeviceInput(device:videoDevice)
            
            // Check videoDeviceInput
            guard let videoDevInput = self.videoDeviceInput else {
                PreyLogger("Error videoDeviceInput")
                self.delegate?.photoReceived(self.photoArray)
                return
            }
            
            // Add session input
            guard self.sessionDevice.canAddInput(videoDevInput) else {
                PreyLogger("Error add session input")
                self.delegate?.photoReceived(self.photoArray)
                return
            }
            self.sessionDevice.addInput(videoDevInput)
            
        } catch let error {
            PreyLogger("AVCaptureDeviceInput error: \(error.localizedDescription)")
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        
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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.sessionRuntimeError),
                                               name: .AVCaptureSessionRuntimeError,
                                               object: self.sessionDevice)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.sessionWasInterrupted),
                                               name: .AVCaptureSessionWasInterrupted,
                                               object: self.sessionDevice)
        
        // Delay
        let timeValue = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        self.sessionQueue.asyncAfter(deadline: timeValue, execute: { () -> Void in
            // Capture a still image
            self.takePicture(true)
        })
    }
    
    // Get second photo
    func getSecondPhoto() {
        
        // Set captureDevice
        guard let videoDevice = ReportPhoto.deviceWithPosition(AVCaptureDevice.Position.front) else {
            PreyLogger("Error with AVCaptureDevice")
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        
        // Set AVCaptureDeviceInput
        do {
            let frontDeviceInput = try AVCaptureDeviceInput(device:videoDevice)
            
            // Remove current device input
            self.sessionDevice.beginConfiguration()
            if let deviceInput = self.videoDeviceInput {
                self.sessionDevice.removeInput(deviceInput)
            }
            
            // Add session input
            guard self.sessionDevice.canAddInput(frontDeviceInput) else {
                PreyLogger("Error add session input")
                self.delegate?.photoReceived(self.photoArray)
                return
            }
            self.sessionDevice.addInput(frontDeviceInput)
            self.videoDeviceInput = frontDeviceInput
            
            // Set session to PresetLow
            if self.sessionDevice.canSetSessionPreset(AVCaptureSession.Preset.low) {
                self.sessionDevice.sessionPreset = AVCaptureSession.Preset.low
            }
            
            // End session config
            self.sessionDevice.commitConfiguration()
            
            
            // Delay
            let timeValue = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            self.sessionQueue.asyncAfter(deadline: timeValue, execute: { () -> Void in
                // Capture a still image
                self.takePicture(false)
            })
            
        } catch let error {
            PreyLogger("AVCaptureDeviceInput error: \(error.localizedDescription)")
            self.delegate?.photoReceived(self.photoArray)
        }
    }
    
    // Capture a still image
    func takePicture(_ isFirstPhoto:Bool) {
        // Set flash off
        if let deviceInput = self.videoDeviceInput {
            self.setFlashModeOff(deviceInput.device)
        }
        
        // Capture a still image
        guard let videoConnection = self.stillImageOutput.connection(with: AVMediaType.video) else {
            // Error: return to delegate
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        guard videoConnection.isEnabled else {
            // Error: return to delegate
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        guard videoConnection.isActive else {
            // Error: return to delegate
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        // Check current state
        guard self.stillImageOutput.isCapturingStillImage == false else {
            // Error: return to delegate
            self.delegate?.photoReceived(self.photoArray)
            return
        }
        // Capture image
        self.stillImageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler:self.checkPhotoCapture(isFirstPhoto))
    }
    
    // Downsamples an image from data to a specified size - much more memory efficient
    private func downsampleImage(_ imageData: Data, to targetSize: CGSize) -> UIImage? {
        // Create a source from data
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            return nil
        }
        
        // Calculate the max dimension
        let maxDimension = max(targetSize.width, targetSize.height)
        
        // Create thumbnail options specifying the downsampling
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        
        // Create the thumbnail
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return UIImage(data: imageData, scale: 1.0)
        }
        
        // Return UIImage from the downsampled CGImage
        return UIImage(cgImage: thumbnail)
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
            guard let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer!) else {
                PreyLogger("Error CMSampleBuffer to NSData")
                self.delegate?.photoReceived(self.photoArray)
                return
            }
            
            // Use the same downsampling method as in iOS 10+
            guard let image = self.downsampleImage(imageData, to: CGSize(width: 1024, height: 768)) else {
                PreyLogger("Error creating downsampled image")
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
}
