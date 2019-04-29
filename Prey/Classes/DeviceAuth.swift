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
import UserNotifications

class DeviceAuth: NSObject, UIAlertViewDelegate {

    // MARK: Singleton
    
    static let sharedInstance = DeviceAuth()
    override fileprivate init() {
    }

    // MARK: Methods
    
    // Check all device auth
    func checkAllDeviceAuthorization(completionHandler:@escaping (_ granted: Bool) -> Void){
        // Check UNUserNotificationCenter async
        checkNotify { granted in
            DispatchQueue.main.async {
                if granted && self.checkLocation() && self.checkCamera() {
                    completionHandler(true)
                } else {
                    completionHandler(false)
                }
            }
        }
    }
    
    // Check notification
    func checkNotify(completionHandler:@escaping (_ granted: Bool) -> Void) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                // Check notification settings
                if settings.authorizationStatus == .authorized {
                    completionHandler(true)
                } else {
                    DispatchQueue.main.async {
                        self.displayMessage("You need to grant Prey access to show alert notifications in order to remotely mark it as missing.".localized,
                                       titleMessage:"Alert notification disabled".localized)
                        completionHandler(false)
                    }
                }
            }
        } else {
            // For iOS 8 and 9
            if let notificationSettings = UIApplication.shared.currentUserNotificationSettings {
                if notificationSettings.types.rawValue > 0 {
                    completionHandler(true)
                } else {
                    DispatchQueue.main.async {
                        self.displayMessage("You need to grant Prey access to show alert notifications in order to remotely mark it as missing.".localized,
                                            titleMessage:"Alert notification disabled".localized)
                        completionHandler(false)
                    }
                }
            } else {completionHandler(true)}
        }
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
