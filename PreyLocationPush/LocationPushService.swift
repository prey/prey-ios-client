//
//  LocationPushService.swift
//  PreyLocationPush
//
//  Created by Carlos Yaconi on 18-08-25.
//  Copyright © 2025 Prey, Inc. All rights reserved.
//

import Foundation
import CoreLocation

class LocationPushService: NSObject, CLLocationPushServiceExtension, CLLocationManagerDelegate {

    private var completion: (() -> Void)?
    private var manager: CLLocationManager?
    private var didFinish = false
    private var timeoutWorkItem: DispatchWorkItem?

    func didReceiveLocationPushPayload(_ payload: [String : Any], completion: @escaping () -> Void) {
        self.completion = completion
        let mgr = CLLocationManager()
        manager = mgr
        mgr.delegate = self
        mgr.desiredAccuracy = kCLLocationAccuracyBest
        mgr.distanceFilter = kCLDistanceFilterNone
        mgr.pausesLocationUpdatesAutomatically = false

        if #available(iOS 9.0, *) {
            mgr.requestLocation()
        } else {
            mgr.startUpdatingLocation()
        }

        // Timeout safety to avoid running too long
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, !self.didFinish else { return }
            self.didFinish = true
            self.manager?.stopUpdatingLocation()
            self.manager?.delegate = nil
            self.manager = nil
            self.completion?()
            self.completion = nil
        }
        timeoutWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: work)
    }
    
    func serviceExtensionWillTerminate() {
        // Called just before the extension will be terminated by the system.
        guard !didFinish else { return }
        didFinish = true
        timeoutWorkItem?.cancel()
        manager?.stopUpdatingLocation()
        manager?.delegate = nil
        manager = nil
        completion?()
        completion = nil
    }

    // MARK: - CLLocationManagerDelegate methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !didFinish, let loc = locations.last else { return }

        // Accept first reasonable fix
        if loc.horizontalAccuracy > 0 && loc.horizontalAccuracy <= 1000 {
            // Persist to shared app group so the main app can pick it up
            if let userDefaults = UserDefaults(suiteName: "group.com.prey.ios") {
                let dict: [String: Any] = [
                    "lng": loc.coordinate.longitude,
                    "lat": loc.coordinate.latitude,
                    "alt": loc.altitude,
                    "accuracy": loc.horizontalAccuracy,
                    "method": "location-push",
                    "timestamp": Date().timeIntervalSince1970
                ]
                userDefaults.set(dict, forKey: "lastLocation")
                userDefaults.synchronize()
            }

            didFinish = true
            timeoutWorkItem?.cancel()
            manager.stopUpdatingLocation()
            manager.delegate = nil
            self.manager = nil
            completion?()
            completion = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard !didFinish else { return }
        didFinish = true
        timeoutWorkItem?.cancel()
        manager.stopUpdatingLocation()
        manager.delegate = nil
        self.manager = nil
        completion?()
        completion = nil
    }
}
