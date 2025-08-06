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
        
        // Use instance method to avoid main thread blocking
        if CLLocationManager.locationServicesEnabled() {
            let status = authLocation.authorizationStatus
            
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
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:statusDeviceEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.statusDevice, preyAction:nil, onCompletion:{(isSuccess: Bool) in PreyLogger("Request check status") }))
        }
    }

    // MARK: CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        callNextRequestAuth("btnLocation")
    }
    
    // Persistent location manager so it doesn't get deallocated
    private static var backgroundLocationManager: CLLocationManager?
    
    // Track if background location is already configured to avoid redundant setup
    private static var isBackgroundLocationConfigured = false
    private static var lastConfigTime: Date?
    
    // Track timestamps for throttling operations
    private static var lastLocationSentTime: Date?
    private static var lastActionCheckTime: Date?
    
    // Location delegates for consolidated location management
    private var locationDelegates: [LocationDelegate] = []
    
    // MARK: Location Delegate Management
    
    func isBackgroundLocationManagerActive() -> Bool {
        return DeviceAuth.backgroundLocationManager != nil && DeviceAuth.isBackgroundLocationConfigured
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
        
        PreyLogger("Ensuring background location is configured - Auth status: \(CLLocationManager.authorizationStatus().rawValue)")
        
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            // Use persistent static location manager that won't be deallocated
            if DeviceAuth.backgroundLocationManager == nil {
                DeviceAuth.backgroundLocationManager = CLLocationManager()
                PreyLogger("Created new persistent background location manager")
            }
            
            // Configure the location manager
            let manager = DeviceAuth.backgroundLocationManager!
            manager.delegate = self
            manager.pausesLocationUpdatesAutomatically = true // Allow system to pause updates
            manager.allowsBackgroundLocationUpdates = true
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters // Reduce power usage
            manager.distanceFilter = 100 // Only update when device moves more than 100 meters
            
            // Always start significant location changes to allow wake-ups for actions
            // But only if not already monitoring
            if !DeviceAuth.isBackgroundLocationConfigured {
                manager.startMonitoringSignificantLocationChanges()
                PreyLogger("Started monitoring significant location changes for background wake-ups")
            }
            
            // Create a background task to ensure we have time to register, but only if not already configured
            if !DeviceAuth.isBackgroundLocationConfigured {
                var bgTask = UIBackgroundTaskIdentifier.invalid
                bgTask = UIApplication.shared.beginBackgroundTask {
                    if bgTask != UIBackgroundTaskIdentifier.invalid {
                        UIApplication.shared.endBackgroundTask(bgTask)
                        bgTask = UIBackgroundTaskIdentifier.invalid
                        PreyLogger("Background location config task expired")
                    }
                }
                
                // Start regular updates too if not already started
                manager.startUpdatingLocation()
                
                PreyLogger("Background location configuration started with task ID: \(bgTask.rawValue)")
                
                // Add a location action to the module to ensure we're tracking location
                // Only do this if we're not already configured
                let locationAction = Location(withTarget: kAction.location, withCommand: kCommand.get, withOptions: nil)
                
                // Only add if not already in the array
                var hasLocationAction = false
                for action in PreyModule.sharedInstance.actionArray {
                    if action.target == kAction.location {
                        hasLocationAction = true
                        break
                    }
                }
                
                if !hasLocationAction {
                    PreyLogger("Adding location action from background location config")
                    PreyModule.sharedInstance.actionArray.append(locationAction)
                    // Run only the location action, not all actions
                    PreyModule.sharedInstance.runSingleAction(locationAction)
                }
                
                // Keep background task running for a moment to register properly
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    if bgTask != UIBackgroundTaskIdentifier.invalid {
                        UIApplication.shared.endBackgroundTask(bgTask)
                        bgTask = UIBackgroundTaskIdentifier.invalid
                        PreyLogger("Background location configured and registered")
                    }
                }
            }
            
            // Mark as configured and update timestamp
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
    
    // Handle location updates from background manager
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, manager == DeviceAuth.backgroundLocationManager else { return }
        
        // Throttle location updates to once per 2 hours (7200 seconds) for normal devices
        // This will prevent excessive location sending while still allowing the device to wake up
        let minTimeBetweenLocationUpdates: TimeInterval = 7200 // 2 hours
        
        let now = Date()
        
        // If the device is missing, use a shorter throttle time (30 minutes)
        let minTimeBetweenUpdates = PreyConfig.sharedInstance.isMissing ? 1800.0 : minTimeBetweenLocationUpdates
        
        let shouldSendLocation = DeviceAuth.lastLocationSentTime == nil || 
                               now.timeIntervalSince(DeviceAuth.lastLocationSentTime!) > minTimeBetweenUpdates
        
        // Log which throttling time is being used
        if PreyConfig.sharedInstance.isMissing {
            PreyLogger("Device is missing - using shorter location throttle time (30 minutes)")
        }
        
        // Skip location sending if throttled but still check for actions
        if !shouldSendLocation  {
            PreyLogger("Skipping location processing - throttled")
            // Don't return, still proceed with checking actions
        }
        
        PreyLogger("Background location manager received location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // Notify any registered location delegates
        notifyLocationDelegates(location)
        
        // Create a background task to ensure we have time to process
        var bgTask = UIBackgroundTaskIdentifier.invalid
        bgTask = UIApplication.shared.beginBackgroundTask {
            if bgTask != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(bgTask)
                bgTask = UIBackgroundTaskIdentifier.invalid
                PreyLogger("Background location processing task expired")
            }
        }
        
        PreyLogger("Started background location processing task: \(bgTask.rawValue)")
        
        // Always save to shared container, even when throttled
        if let userDefaults = UserDefaults(suiteName: "group.com.prey.ios") {
            let locationDict: [String: Any] = [
                "lng": location.coordinate.longitude,
                "lat": location.coordinate.latitude,
                "alt": location.altitude,
                "accuracy": location.horizontalAccuracy,
                "method": "native",
                "timestamp": Date().timeIntervalSince1970
            ]
            
            userDefaults.set(locationDict, forKey: "lastLocation")
            userDefaults.synchronize()
            PreyLogger("Saved background location to shared container")
        }
        
        // Use a dispatch group to track completion of all operations
        let operationGroup = DispatchGroup()
        
        // Only trigger location action if not throttled
        if shouldSendLocation {
            // Trigger location action if available
            var locationActionFound = false
            for action in PreyModule.sharedInstance.actionArray {
                if let locationAction = action as? Location {
                    locationActionFound = true
                    locationAction.locationReceived(location)
                    PreyLogger("Using existing location action")
                    break
                }
            }
            
            // If no location action exists, create one
            if !locationActionFound {
                let locationAction = Location(withTarget: kAction.location, withCommand: kCommand.get, withOptions: nil)
                PreyModule.sharedInstance.actionArray.append(locationAction)
                locationAction.locationReceived(location)
                PreyLogger("Created and executed new location action for background location")
            }
            
            // Update timestamp
            DeviceAuth.lastLocationSentTime = now
        } else {
            PreyLogger("Skipping location sending - throttled to once per hour (last sent: \(String(describing: DeviceAuth.lastLocationSentTime)))")
        }
        
        // Fetch actions from server with throttling
        if let username = PreyConfig.sharedInstance.userApiKey {
            operationGroup.enter()
            PreyLogger("Fetching actions from server in background location update")
            
            PreyHTTPClient.sharedInstance.userRegisterToPrey(
                username,
                password: "x",
                params: nil,
                messageId: nil,
                httpMethod: Method.GET.rawValue,
                endPoint: actionsDeviceEndpoint,
                onCompletion: PreyHTTPResponse.checkResponse(
                    RequestType.actionDevice,
                    preyAction: nil,
                    onCompletion: { isSuccess in
                        PreyLogger("Background fetch actions complete: \(isSuccess)")
                        // Update the action check timestamp
                        DeviceAuth.lastActionCheckTime = Date()
                        operationGroup.leave()
                    }
                )
            )
            
            // Only check device status when we check actions
            operationGroup.enter()
            PreyModule.sharedInstance.requestStatusDevice(context: "DeviceAuth-backgroundLocation") { isSuccess in
                PreyLogger("Background check status complete: \(isSuccess)")
                operationGroup.leave()
            }
        } else {
            operationGroup.enter()
            operationGroup.leave()
        }
        
        // When all operations complete, end the background task
        operationGroup.notify(queue: .main) {
            // Give a short delay to ensure all processing completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if bgTask != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(bgTask)
                    bgTask = UIBackgroundTaskIdentifier.invalid
                    PreyLogger("Background location processing task completed")
                }
            }
        }
    }
}
