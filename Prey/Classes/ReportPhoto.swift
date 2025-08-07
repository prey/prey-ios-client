//
//  ReportPhoto.swift
//  Prey
//
//  Created by Javier Cala Uribe on 26/05/16.
//  Modified by Patricio Jofré on 04/08/2025.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

protocol PhotoServiceDelegate {
    func photoReceived(_ photos: NSMutableDictionary)
}

class ReportPhoto: NSObject, AVCapturePhotoCaptureDelegate {
    
    // MARK: Properties
    
    // Delegate
    var delegate: PhotoServiceDelegate?
    
    // Photo storage
    var photoArray = NSMutableDictionary()
    
    // Session components
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "photo.capture.session")
    private let photoOutput = AVCapturePhotoOutput()
    
    // Current device input
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    // Photo capture tracking
    private var isFirstPhoto = true
    var waitForRequest = false
    
    // MARK: Computed Properties
    
    // Check device authorization
    var isDeviceAuthorized: Bool {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        return authStatus == .authorized
    }
    
    // Check if multiple cameras are available
    var isTwoCameraAvailable: Bool {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .unspecified
        )
        return discoverySession.devices.count > 1
    }
    
    // MARK: Init
    
    override init() {
        super.init()
        configureSession()
    }
    
    // MARK: Public Methods
    
    func startSession() {
        sessionQueue.async {
            self.captureSession.startRunning()
            self.takeFirstPhoto()
        }
    }
    
    func stopSession() {
        sessionQueue.async {
            self.captureSession.stopRunning()
        }
    }
    
    func removeObserver() {
        // Observer removal handled automatically in modern implementation
    }
    
    // MARK: Private Methods
    
    private func configureSession() {
        captureSession.beginConfiguration()
        
        // Set session preset
        if captureSession.canSetSessionPreset(.photo) {
            captureSession.sessionPreset = .photo
        }
        
        // Add photo output
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        captureSession.commitConfiguration()
    }
    
    private func takeFirstPhoto() {
        isFirstPhoto = true
        photoArray.removeAllObjects()
        
        guard let backCamera = getCamera(for: .back) else {
            PreyLogger("Error: Back camera not available")
            delegate?.photoReceived(photoArray)
            return
        }
        
        capturePhotoWith(device: backCamera)
    }
    
    private func takeSecondPhoto() {
        isFirstPhoto = false
        
        guard let frontCamera = getCamera(for: .front) else {
            PreyLogger("Error: Front camera not available")
            delegate?.photoReceived(photoArray)
            return
        }
        
        capturePhotoWith(device: frontCamera)
    }
    
    private func getCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: position
        )
        return discoverySession.devices.first
    }
    
    private func capturePhotoWith(device: AVCaptureDevice) {
        do {
            // Remove existing input
            if let currentInput = videoDeviceInput {
                captureSession.removeInput(currentInput)
            }
            
            // Create new input
            let newInput = try AVCaptureDeviceInput(device: device)
            
            captureSession.beginConfiguration()
            
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
                videoDeviceInput = newInput
            } else {
                PreyLogger("Error: Cannot add device input")
                captureSession.commitConfiguration()
                delegate?.photoReceived(photoArray)
                return
            }
            
            captureSession.commitConfiguration()
            
            // Configure photo settings
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.flashMode = .off
            
            // Capture photo
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
            
        } catch {
            PreyLogger("Error creating device input: \(error.localizedDescription)")
            delegate?.photoReceived(photoArray)
        }
    }
    
    private func downsampleImage(_ imageData: Data, to targetSize: CGSize) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            return nil
        }
        
        let maxDimension = max(targetSize.width, targetSize.height)
        
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return UIImage(data: imageData)
        }
        
        return UIImage(cgImage: thumbnail)
    }
    
    // MARK: AVCapturePhotoCaptureDelegate
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            PreyLogger("Error capturing photo: \(error!.localizedDescription)")
            delegate?.photoReceived(photoArray)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            PreyLogger("Error getting photo data")
            delegate?.photoReceived(photoArray)
            return
        }
        
        // Downsample image for memory efficiency
        guard let image = downsampleImage(imageData, to: CGSize(width: 1024, height: 768)) else {
            PreyLogger("Error creating downsampled image")
            delegate?.photoReceived(photoArray)
            return
        }
        
        // Store photo
        let key = isFirstPhoto ? "picture" : "screenshot"
        photoArray.setObject(image, forKey: key as NSCopying)
        
        // Check if we need to take second photo
        if isFirstPhoto && isTwoCameraAvailable {
            sessionQueue.async {
                self.takeSecondPhoto()
            }
        } else {
            // All photos captured, return results
            delegate?.photoReceived(photoArray)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // Photo capture started - could add UI feedback here if needed
    }
}