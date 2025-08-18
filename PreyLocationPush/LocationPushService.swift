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

            // Decide whether to upload directly from the extension
            let shouldUpload = UserDefaults(suiteName: "group.com.prey.ios")?.bool(forKey: "PreyExtensionDirectUploadEnabled") ?? false

            let finish: () -> Void = { [weak self] in
                guard let self = self else { return }
                self.didFinish = true
                self.timeoutWorkItem?.cancel()
                manager.stopUpdatingLocation()
                manager.delegate = nil
                self.manager = nil
                self.completion?()
                self.completion = nil
            }

            if shouldUpload, let req = self.buildUploadRequest(for: loc) {
                self.performDirectUpload(request: req, completion: finish)
            } else {
                finish()
            }
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

// MARK: - Direct Upload Helpers

extension LocationPushService {
    private func buildUploadRequest(for loc: CLLocation) -> URLRequest? {
        guard let shared = UserDefaults(suiteName: "group.com.prey.ios") else { return nil }
        guard let apiKey = shared.string(forKey: "PreyUserApiKey"),
              let deviceKey = shared.string(forKey: "PreyDeviceKey") else { return nil }

        let base = shared.string(forKey: "PreyControlPanelBaseURL") ?? "https://panel.preyproject.com"
        let urlStr = "\(base)/devices/\(deviceKey)/location.json"
        guard let url = URL(string: urlStr) else { return nil }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        let body: [String: Any] = [
            "location": [
                "lat": loc.coordinate.latitude,
                "lng": loc.coordinate.longitude,
                "alt": loc.altitude,
                "accuracy": loc.horizontalAccuracy,
                "method": "location-push"
            ]
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Prey API accepts Basic auth with username=apiKey, password="x"
        let authString = "\(apiKey):x"
        if let authData = authString.data(using: .utf8) {
            let header = authData.base64EncodedString()
            req.setValue("Basic \(header)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    private func performDirectUpload(request: URLRequest, completion: @escaping () -> Void) {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        config.waitsForConnectivity = false
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        let session = URLSession(configuration: config)

        let task = session.dataTask(with: request) { _, _, _ in
            completion()
        }
        task.resume()
    }
}
