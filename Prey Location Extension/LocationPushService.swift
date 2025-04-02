//
//  LocationPushService.swift
//  Prey Location Extension
//
//  Created by Pato Jofre on 25/03/2025.
//  Copyright © 2025 Prey, Inc. All rights reserved.
//

import CoreLocation
import Prey
import UserNotifications

class LocationPushService: NSObject, CLLocationPushServiceExtension, CLLocationManagerDelegate {

    var completion: (() -> Void)?
    var locationManager: CLLocationManager?
    let userDefaults = UserDefaults(suiteName: "group.com.prey.ios")
    
    func didReceiveLocationPushPayload(_ payload: [String : Any], completion: @escaping () -> Void) {
        PreyLogger("Location push service received payload: \(payload)")
        self.completion = completion
        
        // Configure location manager
        self.locationManager = CLLocationManager()
        self.locationManager!.delegate = self
        self.locationManager!.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager!.distanceFilter = kCLDistanceFilterNone
        self.locationManager!.requestLocation()
        
        // Store payload in shared container if needed
        if let pushInfo = payload["push-info"] as? [String: Any] {
            userDefaults?.set(pushInfo, forKey: "lastLocationPush")
            userDefaults?.synchronize()
            
            // If this is a missing device alert, schedule a local notification
            if let isMissing = pushInfo["missing"] as? Bool, isMissing == true {
                scheduleLocalNotification("Location requested for missing device")
            }
        }
    }
    
    func serviceExtensionWillTerminate() {
        // Called just before the extension will be terminated by the system.
        PreyLogger("Location push service will terminate")
        self.completion?()
    }

    // Schedule a local notification
    private func scheduleLocalNotification(_ message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Prey"
        content.body = message
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: "com.prey.location.update",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                PreyLogger("Error scheduling notification: \(error)")
            }
        }
    }

    // MARK: - CLLocationManagerDelegate methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Process the location(s) as appropriate
        guard let location = locations.last else {
            PreyLogger("No location found in update")
            self.completion?()
            return
        }

        PreyLogger("Location push service location update: \(location)")
        
        // Save location to shared container
        let locationDict: [String: Any] = [
            "lng": location.coordinate.longitude,
            "lat": location.coordinate.latitude,
            "alt": location.altitude,
            "accuracy": location.horizontalAccuracy,
            "method": "native",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        userDefaults?.set(locationDict, forKey: "lastLocation")
        userDefaults?.synchronize()
        
        // Send location to Prey server
        let params = locationDict
        PreyHTTPClient.sharedInstance.sendLocation(params)
        
        // When finished, always call completion()
        self.completion?()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PreyLogger("Location Push Service Error: \(error.localizedDescription)")
        
        // Store error in shared container
        userDefaults?.set(error.localizedDescription, forKey: "lastLocationError")
        userDefaults?.synchronize()
        
        self.completion?()
    }
}