//
//  DeviceAuth.swift
//  Prey
//
//  Created by Javier Cala Uribe on 26/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import CoreLocation
import AVFoundation

class DeviceAuth: NSObject, UIAlertViewDelegate {

    // MARK: Singleton
    
    static let sharedInstance = DeviceAuth()
    override fileprivate init() {
    }

    // MARK: Methods
    
    // Check all device auth
    func checkAllDeviceAuthorization() -> Bool{
        if checkNotify() && checkLocation() && checkCamera() {
            return true
        }
        return false
    }
    
    // Check notification
    func checkNotify() -> Bool {
        
        var notifyAuth = false
        
        if let notificationSettings = UIApplication.shared.currentUserNotificationSettings {
            notifyAuth = notificationSettings.types.rawValue > 0
        }

        if !notifyAuth {
            displayMessage("You need to grant Prey access to show alert notifications in order to remotely mark it as missing.".localized,
                           titleMessage:"Alert notification disabled".localized)
        }
        
        return notifyAuth
    }
    
    // Check location
    func checkLocation() -> Bool {
        
        var locationAuth = false
        
        if (CLLocationManager.locationServicesEnabled() &&
            CLLocationManager.authorizationStatus() != .notDetermined &&
            CLLocationManager.authorizationStatus() != .denied &&
            CLLocationManager.authorizationStatus() != .restricted) {
            locationAuth = true
        }
        
        if !locationAuth {
            displayMessage("Location services are disabled for Prey. Reports will not be sent.".localized,
                           titleMessage:"Enable Location".localized)
        }
        
        return locationAuth
    }
    
    // Check camera
    func checkCamera() -> Bool {
        
        var cameraAuth = false
        
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized {
            cameraAuth = true
        } else {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:{(granted: Bool) in
                cameraAuth = granted
            })
        }
        
        if !cameraAuth {
            displayMessage("Camera is disabled for Prey. Reports will not be sent.".localized,
                           titleMessage:"Enable Camera".localized)
        }
        
        return cameraAuth
    }
    
    // Display message
    func displayMessage(_ alertMessage:String, titleMessage:String) {
        
        let acceptBtn    = "Go to Settings".localized
        let cancelBtn    = "Cancel".localized
        
        let anAlert      = UIAlertView()
        anAlert.title    = titleMessage
        anAlert.message  = alertMessage
        anAlert.delegate = self
        anAlert.addButton(withTitle: acceptBtn)
        anAlert.addButton(withTitle: cancelBtn)
        
        anAlert.show()
    }

    // MARK: UIAlertViewDelegate
    
    // AlertView
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        
        guard buttonIndex == 0 else {
            return
        }
        
        if let url = URL(string:UIApplication.openSettingsURLString) {
            UIApplication.shared.openURL(url)
        }
    }
}
