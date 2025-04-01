//
//  DeviceAuth.swift
//  Prey
//
//  Created by Javier Cala Uribe on 26/05/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import CoreLocation
import AVFoundation
import UserNotifications
import Photos
import UIKit

class DeviceAuth: NSObject, UIAlertViewDelegate, CLLocationManagerDelegate {

    // MARK: Singleton
    
    static let sharedInstance = DeviceAuth()
    override fileprivate init() {
    }

    // Location Service Auth
    let authLocation = CLLocationManager()
    
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
    }
    
    // Check location
    func checkLocation() -> Bool {
        var locationAuth = false
        
        if CLLocationManager.locationServicesEnabled() {
            let status = CLLocationManager.authorizationStatus()
            
            if status == .notDetermined {
                authLocation.requestAlwaysAuthorization()
            }
            
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                locationAuth = true
            }
        }
        
        if !locationAuth {
            displayMessage("To fully protect your device Prey must have access to its location at all times. In Settings, go to Location and select Always.".localized,
                           titleMessage: "Enable Location".localized,
                           cancelBtn: "Later".localized
            )
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
    func displayMessage(_ alertMessage:String, titleMessage:String, cancelBtn:String = "Cancel".localized) {
        let alertController = UIAlertController(
            title: titleMessage,
            message: alertMessage,
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(
            title: "Go to Settings".localized,
            style: .default,
            handler: { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        ))
        
        alertController.addAction(UIAlertAction(
            title: cancelBtn,
            style: .cancel
        ))
        
        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alertController, animated: true)
        }
    }

    // Call next request auth item
    func callNextRequestAuth(_ idBtn: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            PreyLogger("error with sharedApplication")
            return
        }
        
        let navigationController = window.rootViewController as! UINavigationController
        if let homeWebVC = navigationController.topViewController as? HomeWebVC {
            homeWebVC.evaluateJS(homeWebVC.webView, code: "var btn = document.getElementById('\(idBtn)'); btn.click();")
        }
    }
    
    // Request auth location
    func requestAuthLocation() {
        authLocation.delegate = self
        if (CLLocationManager.locationServicesEnabled() &&
            CLLocationManager.authorizationStatus() == .notDetermined) {
            authLocation.requestAlwaysAuthorization()
        } else {
            callNextRequestAuth("btnLocation")
        }
    }

    // Request auth photos
    func requestAuthPhotos() {
        PHPhotoLibrary.requestAuthorization({ authorization -> Void in
            DispatchQueue.main.async {self.callNextRequestAuth("btnPhotos")}
        })
    }

    // Request auth camera
    func requestAuthCamera() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:{(granted: Bool) in
            DispatchQueue.main.async {self.callNextRequestAuth("btnCamera")}
        })
    }
    
    func checkLocationBackground() -> Bool {
        var locationAuth = false
        if (CLLocationManager.locationServicesEnabled() &&
            CLLocationManager.authorizationStatus() == .authorizedAlways) {
            locationAuth = true
        }
        return locationAuth
    }
       
    func checkBackgroundRefreshStatus() -> Bool {
        return UIApplication.shared.backgroundRefreshStatus == .available
    }

    // Request auth notification
    func requestAuthNotification(_ callNextView: Bool) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            DispatchQueue.main.async {
                let alertCategory = UNNotificationCategory(identifier: categoryNotifPreyAlert, actions: [], intentIdentifiers: [], options: [])
                UNUserNotificationCenter.current().setNotificationCategories(Set([alertCategory]))
                if callNextView { self.callNextReactView() }
                // Check permission granted
                guard granted else { return }
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    // Check notification settings
                    guard settings.authorizationStatus == .authorized else { return }
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        }
    }
    
    // Call next ReactView
    func callNextReactView() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            PreyLogger("error with sharedApplication")
            return
        }
        
        let navigationController = window.rootViewController as! UINavigationController
        if let homeWebVC = navigationController.topViewController as? HomeWebVC {
            homeWebVC.loadViewOnWebView("activation")
        }
        // Check location aware action on device status
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:statusDeviceEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.statusDevice, preyAction:nil, onCompletion:{(isSuccess: Bool) in PreyLogger("Request check status") }))
        }
    }

    // MARK: CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        callNextRequestAuth("btnLocation")
    }
    
    // Add a method to ensure background location is properly configured
    func ensureBackgroundLocationIsConfigured() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            // Configure location manager for background updates
            let manager = CLLocationManager()
            manager.pausesLocationUpdatesAutomatically = false
            manager.allowsBackgroundLocationUpdates = true
            manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            
            // Start significant location changes to ensure system registers our background capability
            manager.startMonitoringSignificantLocationChanges()
            
            // Start regular updates too
            manager.startUpdatingLocation()
            
            // Keep it running for a moment to register properly
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                manager.stopUpdatingLocation()
                manager.stopMonitoringSignificantLocationChanges()
                PreyLogger("Background location configured and registered")
            }
            
            PreyLogger("Background location configuration started")
        } else {
            PreyLogger("Cannot configure background location - no always authorization")
        }
    }
}
