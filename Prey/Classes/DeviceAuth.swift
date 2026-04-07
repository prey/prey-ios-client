//
//  DeviceAuth.swift
//  Prey
//
//  Created by Javier Cala Uribe on 26/05/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import AVFoundation
import CoreLocation
import Foundation
import Photos
import UIKit
import UserNotifications

/// Protocol for location delegates to receive location updates
protocol LocationDelegate: AnyObject {
    func didReceiveLocationUpdate(_ location: CLLocation)
}

class DeviceAuth: NSObject, UIAlertViewDelegate, CLLocationManagerDelegate, LocationDelegate {
    // MARK: Singleton

    static let sharedInstance = DeviceAuth()
    override fileprivate init() {}

    /// Location Service Auth
    let authLocation = CLLocationManager()

    // MARK: Methods

    /// Check all device auth
    func checkAllDeviceAuthorization(completionHandler: @escaping (_ granted: Bool) -> Void) {
        DispatchQueue.main.async {
            let granted = self.checkLocation() && self.checkCamera()
            completionHandler(granted)
        }
    }

    /// Check location
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
                           cancelBtn: "Later".localized)
        }

        return locationAuth
    }

    /// Check camera
    func checkCamera() -> Bool {
        var cameraAuth = false

        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized {
            cameraAuth = true
        } else {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) in
                cameraAuth = granted
            })
        }

        if !cameraAuth {
            displayMessage("Camera is disabled for Prey. Reports will not be sent.".localized,
                           titleMessage: "Enable Camera".localized)
        }

        return cameraAuth
    }

    /// Display message
    func displayMessage(_ alertMessage: String, titleMessage: String, cancelBtn: String = "Cancel".localized) {
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
           let rootViewController = windowScene.windows.first?.rootViewController
        {
            rootViewController.present(alertController, animated: true)
        }
    }

    /// Notify React that a native permission request completed
    func notifyPermissionResult(_ permission: String, granted: Bool) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first
        else {
            PreyLogger("error with sharedApplication")
            return
        }

        let navigationController = window.rootViewController as! UINavigationController
        if let homeWebVC = navigationController.topViewController as? HomeWebVC {
            let js = "window.dispatchEvent(new CustomEvent('preyPermissionResult', {detail: {permission: '\(permission)', granted: \(granted)}}));"
            homeWebVC.evaluateJS(homeWebVC.webView, code: js)
        }
    }

    /// Request auth location
    func requestAuthLocation() {
        authLocation.delegate = self
        let status = authLocation.authorizationStatus
        PreyLogger("requestAuthLocation status: \(status.rawValue)")

        switch status {
        case .notDetermined:
            authLocation.requestWhenInUseAuthorization()
        case .denied, .restricted:
            displayMessage(
                "Location permission was denied. Please enable it in Settings to protect your device.".localized,
                titleMessage: "Location Permission Needed".localized,
                cancelBtn: "Later".localized
            )
            notifyPermissionResult("location", granted: false)
        default:
            notifyPermissionResult("location", granted: true)
        }
    }

    /// Prompt user to upgrade from WhenInUse -> Always after setup
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
               let root = scene.windows.first?.rootViewController
            {
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

    func checkLocationBackground() -> Bool {
        var locationAuth = false
        if CLLocationManager.locationServicesEnabled() &&
            authLocation.authorizationStatus == .authorizedAlways
        {
            locationAuth = true
        }
        return locationAuth
    }

    func checkBackgroundRefreshStatus() -> Bool {
        return UIApplication.shared.backgroundRefreshStatus == .available
    }

    // MARK: CLLocationManagerDelegate

    func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let granted = status == .authorizedAlways || status == .authorizedWhenInUse
        notifyPermissionResult("location", granted: granted)
    }

    // Track if background location is already configured to avoid redundant setup
    private static var isBackgroundLocationConfigured = false
    private static var lastConfigTime: Date?

    /// Location delegates for consolidated location management
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

    /// Bridge for centralized LocationService updates
    func didReceiveLocationUpdate(_ location: CLLocation) {
        notifyLocationDelegates(location)
    }

    /// Add a method to ensure background location is properly configured
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

    /// Bridge updates from LocationService (via separate delegate function)
    func locationManager(_: CLLocationManager, didUpdateLocations _: [CLLocation]) {}
}
