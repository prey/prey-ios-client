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

// Protocol for location delegates to receive location updates
protocol LocationDelegate: AnyObject {
    func didReceiveLocationUpdate(_ location: CLLocation)
}

class DeviceAuth: NSObject, UIAlertViewDelegate, CLLocationManagerDelegate, LocationDelegate {

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
        
        // Use instance method to avoid main thread blocking
        if CLLocationManager.locationServicesEnabled() {
            let status = authLocation.authorizationStatus
            
            if status == .notDetermined {
                // Request WhenInUse first per iOS policy, upgrade later
                authLocation.requestWhenInUseAuthorization()
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
            authLocation.authorizationStatus == .notDetermined) {
            // Request WhenInUse first during setup
            authLocation.requestWhenInUseAuthorization()
        } else {
            callNextRequestAuth("btnLocation")
        }
    }

    // Prompt user to upgrade from WhenInUse -> Always after setup
    func promptUpgradeToAlwaysIfNeeded() {
        let status = authLocation.authorizationStatus
        guard CLLocationManager.locationServicesEnabled() else { return }
        switch status {
        case .authorizedAlways:
            return
        case .authorizedWhenInUse:
            // Show rationale dialog before asking for Always
            let alert = UIAlertController(
                title: "Enable Background Location".localized,
                message: "Prey needs 'Always' location to locate your device even when the app isn't open.".localized,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Not now".localized, style: .cancel))
            alert.addAction(UIAlertAction(title: "Enable".localized, style: .default, handler: { _ in
                self.authLocation.requestAlwaysAuthorization()
                // Fallback to Settings if it doesn't upgrade shortly
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    let s = self.authLocation.authorizationStatus
                    if s != .authorizedAlways {
                        self.displayMessage(
                            "Please set Location to 'Always' for Prey in Settings > Privacy > Location Services.".localized,
                            titleMessage: "Background Location Required".localized,
                            cancelBtn: "Later".localized
                        )
                    }
                }
            }))
            // Present
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                root.present(alert, animated: true)
            }
        case .denied, .restricted:
            // Direct user to Settings
            displayMessage(
                "Location permission is denied. Please enable 'Always' in Settings for full protection.".localized,
                titleMessage: "Location Permission Needed".localized,
                cancelBtn: "Later".localized
            )
        default:
            // Not determined: ask WhenInUse first
            authLocation.requestWhenInUseAuthorization()
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
            authLocation.authorizationStatus == .authorizedAlways) {
            locationAuth = true
        }
        return locationAuth
    }
       
    func checkBackgroundRefreshStatus() -> Bool {
        return UIApplication.shared.backgroundRefreshStatus == .available
    }

    // Request auth notification
    func requestAuthNotification(_ callNextView: Bool) {
        // Create notification actions for better user interaction
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION", 
            title: "View Details", 
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION", 
            title: "Dismiss", 
            options: [.destructive]
        )
        
        // Create the category with the actions
        let alertCategory = UNNotificationCategory(
            identifier: categoryNotifPreyAlert, 
            actions: [viewAction, dismissAction], 
            intentIdentifiers: [], 
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .providesAppNotificationSettings, .criticalAlert]) { (granted, error) in
            DispatchQueue.main.async {
                // Set notification categories with appropriate actions
                UNUserNotificationCenter.current().setNotificationCategories(Set([alertCategory]))
                
                if callNextView { 
                    self.callNextReactView() 
                }
                
                // Check permission granted
                guard granted else { 
                    PreyLogger("Notification permission not granted")
                    return 
                }
                
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    // Check notification settings
                    PreyLogger("Current notification settings: \(settings.authorizationStatus.rawValue)")
                    
                    guard settings.authorizationStatus == .authorized else { 
                        PreyLogger("Notification authorization not available")
                        return 
                    }
                    
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                        PreyLogger("Registered for remote notifications")
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
            PreyHTTPClient.sharedInstance.sendDataToPrey(username, password:"x", params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:statusDeviceEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.statusDevice, preyAction:nil, onCompletion:{(isSuccess: Bool) in PreyLogger("Request check status") }))
        }
        
        // Check if daily location update is needed
        Location.checkDailyLocationUpdate()
    }

    // MARK: CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        callNextRequestAuth("btnLocation")
    }
    
    
    // Track if background location is already configured to avoid redundant setup
    private static var isBackgroundLocationConfigured = false
    private static var lastConfigTime: Date?
    
    // Location delegates for consolidated location management
    private var locationDelegates: [LocationDelegate] = []

    // MARK: Location Delegate Management
    
    func isBackgroundLocationManagerActive() -> Bool {
        return DeviceAuth.isBackgroundLocationConfigured || LocationService.shared.isRunning()
    }
    
    func addLocationDelegate(_ delegate: LocationDelegate) {
        // Avoid duplicate delegates
        if !locationDelegates.contains(where: { $0 === delegate }) {
            locationDelegates.append(delegate)
            PreyLogger("Added location delegate")
        }
    }
    
    func removeLocationDelegate(_ delegate: LocationDelegate) {
        locationDelegates.removeAll { $0 === delegate }
        PreyLogger("Removed location delegate")
    }
    
    private func notifyLocationDelegates(_ location: CLLocation) {
        for delegate in locationDelegates {
            delegate.didReceiveLocationUpdate(location)
        }
    }

    // Bridge for centralized LocationService updates
    func didReceiveLocationUpdate(_ location: CLLocation) {
        notifyLocationDelegates(location)
    }

    // Add a method to ensure background location is properly configured
    func ensureBackgroundLocationIsConfigured() {
        // Don't reconfigure if we've done it recently (within 60 seconds)
        let shouldConfigure = !DeviceAuth.isBackgroundLocationConfigured || 
                              DeviceAuth.lastConfigTime == nil ||
                              Date().timeIntervalSince(DeviceAuth.lastConfigTime!) > 60
        
        if !shouldConfigure {
            // Avoid spamming logs
            return
        }
        
        PreyLogger("Ensuring background location is configured - Auth status: \(authLocation.authorizationStatus.rawValue)")
        
        if authLocation.authorizationStatus == .authorizedAlways {
            // Use centralized LocationService only
            LocationService.shared.addDelegate(self)
            LocationService.shared.startBackgroundTracking()
            DeviceAuth.isBackgroundLocationConfigured = true
            DeviceAuth.lastConfigTime = Date()
        } else {
            PreyLogger("Cannot configure background location - no always authorization")
            
            // Request authorization anyway, but don't spam
            if DeviceAuth.lastConfigTime == nil || Date().timeIntervalSince(DeviceAuth.lastConfigTime!) > 300 {
                let locationManager = CLLocationManager()
                locationManager.requestAlwaysAuthorization()
                DeviceAuth.lastConfigTime = Date()
            }
        }
    }
    
    // Bridge updates from LocationService (via separate delegate function)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { }
}
