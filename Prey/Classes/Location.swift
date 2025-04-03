//
//  Location.swift
//  Prey
//
//  Created by Javier Cala Uribe on 5/05/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class Location : PreyAction, CLLocationManagerDelegate {
    
    // MARK: Properties
    
    let locManager   = CLLocationManager()
    
    var lastLocation : CLLocation!
    
    var isLocationAwareActive = false
    
    var index = 0
    
    // Location Push Token
    private var locationPushToken: Data?
    
    // Background task identifier
    private var locationBgTaskId: UIBackgroundTaskIdentifier = .invalid
    
    // MARK: Functions
    
    // Return init if location action don't exist
    class func initLocationAction(withTarget target:kAction, withCommand cmd:kCommand, withOptions opt:NSDictionary?) -> Location? {

        // Check if command is start_location_aware
        if cmd == kCommand.start_location_aware {
            return Location(withTarget:target, withCommand:cmd, withOptions:opt)
        }
        
        var existAction = false
        
        for item in PreyModule.sharedInstance.actionArray {
            // Check if action is Location
            if ( item.target == kAction.location ) {
                existAction = true
                // Send lastLocation to panel web
                (item as! Location).sendLastLocation()
                break
            }
        }
        
        return existAction ? nil : Location(withTarget:target, withCommand:cmd, withOptions:opt)
    }
    
    // Send lastLocation 
    func sendLastLocation() {

        if lastLocation != nil {
            // Send location to web panel
            locationReceived(lastLocation)
        }
    }
    
    // Prey command
    override func get() {
        PreyLogger("Location.get() called - App State: \(UIApplication.shared.applicationState == .background ? "Background" : "Foreground")")
        
        // Make sure location services are enabled
        if CLLocationManager.locationServicesEnabled() == false {
            PreyLogger("⚠️ Location services are disabled system-wide")
            // Try to initialize anyway in case user enables later
        }
        
        // Check authorization status
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus != .authorizedAlways {
            PreyLogger("⚠️ Location authorization status is not .authorizedAlways: \(authStatus)")
            // Request authorization just in case
            locManager.requestAlwaysAuthorization()
        }
        
        // Start the location manager
        startLocationManager()
        
        // Schedule get location with timeout - 30 seconds
        Timer.scheduledTimer(timeInterval: 30.0, target:self, selector:#selector(stopLocationTimer(_:)), userInfo:nil, repeats:false)
        
        // Start monitoring location pushes for iOS 15+
        startMonitoringLocationPushes()
        
        // Check for cached location in shared container
        if let userDefaults = UserDefaults(suiteName: "group.com.prey.ios"),
           let cachedLocation = userDefaults.dictionary(forKey: "lastLocation") {
            
            PreyLogger("Found cached location in shared container: \(cachedLocation)")
            
            // Convert cached data to a CLLocation if possible
            if let lat = cachedLocation["lat"] as? Double,
               let lng = cachedLocation["lng"] as? Double,
               let accuracy = cachedLocation["accuracy"] as? Double,
               let altitude = cachedLocation["alt"] as? Double,
               let timestamp = cachedLocation["timestamp"] as? TimeInterval {
                
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                let date = Date(timeIntervalSince1970: timestamp)
                
                // Only use cached location if it's recent (within last 5 minutes)
                if abs(date.timeIntervalSinceNow) < 300 {
                    let location = CLLocation(
                        coordinate: coordinate,
                        altitude: altitude,
                        horizontalAccuracy: accuracy,
                        verticalAccuracy: 0,
                        timestamp: date
                    )
                    
                    PreyLogger("Using cached location from shared container")
                    self.lastLocation = location
                    self.locationReceived(location)
                } else {
                    PreyLogger("Cached location is too old: \(abs(date.timeIntervalSinceNow)) seconds")
                }
            }
        }
        
        PreyLogger("Location started successfully")
    }
    
    private func startMonitoringLocationPushes() {
        if #available(iOS 15.0, *) {
            locManager.startMonitoringLocationPushes { [weak self] (token, error) in
                if let error = error {
                    PreyLogger("Location Push Error: \(error.localizedDescription)")
                    return
                }
                
                PreyLogger("startMonitoringLocationPushes")
                
                if let token = token {
                    self?.locationPushToken = token
                    self?.sendLocationPushToken(token)
                }
            }
        }
    }
    
    private func sendLocationPushToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02x", $0) }.joined()
        
        let params: [String: Any] = [
            "location_push_token": tokenString
        ]
        
        PreyHTTPClient.sharedInstance.userRegisterToPrey(
            PreyConfig.sharedInstance.userApiKey ?? "",
            password: "x",
            params: params,
            messageId: nil,
            httpMethod: Method.POST.rawValue,
            endPoint: dataDeviceEndpoint,
            onCompletion: PreyHTTPResponse.checkResponse(RequestType.dataSend, preyAction: nil) { success in
                PreyLogger("Location Push Token Send: \(success)")
            })
    }
    
    // Start location aware
    @objc func start_location_aware() {
        startLocationManager()
        isLocationAwareActive = true
        PreyLogger("Start location aware")
    }
    
    // Stop Location Timer
    @objc func stopLocationTimer(_ timer:Timer)  {
        timer.invalidate()
        stopLocationManager()
    }
    
    // Start Location Manager
    func startLocationManager()  {
        PreyLogger("Starting location manager")
        
        // End any existing background task first
        if locationBgTaskId != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(locationBgTaskId)
            locationBgTaskId = UIBackgroundTaskIdentifier.invalid
            PreyLogger("Ended previous location background task")
        }
        
        // Configure location manager for maximum reliability
        locManager.requestAlwaysAuthorization()
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locManager.distanceFilter = kCLDistanceFilterNone
        locManager.pausesLocationUpdatesAutomatically = false
        locManager.allowsBackgroundLocationUpdates = true
        locManager.showsBackgroundLocationIndicator = true // Shows the blue bar when app uses location in background
        
        // Start significant location changes for background wake-ups
        locManager.startMonitoringSignificantLocationChanges()
        locManager.startUpdatingLocation()
        
        // Begin background task to ensure we have time to get location
        locationBgTaskId = UIApplication.shared.beginBackgroundTask { [weak self] in
            guard let self = self else { return }
            
            PreyLogger("Location background task expiring - ID: \(self.locationBgTaskId.rawValue)")
            
            // Try to create a new background task before the current one expires
            let newBgTask = UIApplication.shared.beginBackgroundTask { [weak self] in
                guard let self = self else { return }
                if self.locationBgTaskId != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(self.locationBgTaskId)
                    self.locationBgTaskId = UIBackgroundTaskIdentifier.invalid
                    PreyLogger("Location background task finally ended")
                }
            }
            
            if newBgTask != UIBackgroundTaskIdentifier.invalid {
                // End the old task and keep the new one
                UIApplication.shared.endBackgroundTask(self.locationBgTaskId)
                self.locationBgTaskId = newBgTask
                PreyLogger("Location background task renewed with ID: \(newBgTask.rawValue)")
            } else {
                // Just end the old task if we couldn't create a new one
                UIApplication.shared.endBackgroundTask(self.locationBgTaskId)
                self.locationBgTaskId = UIBackgroundTaskIdentifier.invalid
                PreyLogger("Location background task ended - couldn't renew")
            }
        }
        
        PreyLogger("Location background task started with ID: \(locationBgTaskId.rawValue)")
        
        isActive = true
        index = 0
        
        PreyLogger("Location manager started with background updates enabled")
    }
    
    // Stop Location Manager
    func stopLocationManager()  {
        PreyLogger("Stop location")
        
        locManager.stopUpdatingLocation()
        locManager.stopMonitoringSignificantLocationChanges()
        locManager.delegate = nil
        
        // End background task if active
        if locationBgTaskId != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(locationBgTaskId)
            PreyLogger("Location background task ended with ID: \(locationBgTaskId.rawValue)")
            locationBgTaskId = UIBackgroundTaskIdentifier.invalid
        }
        
        isActive = false
        PreyModule.sharedInstance.checkStatus(self)
    }
    
    // Location received
    func locationReceived(_ location:CLLocation) {
        PreyLogger("Processing location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // Create a background task to ensure we have time to send the location
        var bgTask = UIBackgroundTaskIdentifier.invalid
        bgTask = UIApplication.shared.beginBackgroundTask {
            if bgTask != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(bgTask)
                bgTask = UIBackgroundTaskIdentifier.invalid
                PreyLogger("Location sending background task expired")
            }
        }
        
        PreyLogger("Started location sending background task: \(bgTask.rawValue)")
 
        // Save location to shared container if available
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
            PreyLogger("Saved location to shared container")
        }
        
        let params:[String: Any] = [
            kLocation.lng.rawValue      : location.coordinate.longitude,
            kLocation.lat.rawValue      : location.coordinate.latitude,
            kLocation.alt.rawValue      : location.altitude,
            kLocation.accuracy.rawValue : location.horizontalAccuracy,
            kLocation.method.rawValue   : "native"]
        
        let locParam:[String: Any] = [kAction.location.rawValue : params, kDataLocation.skip_toast.rawValue : (index > 0)]
        
        // Use dispatch group to track when all API calls complete
        let dispatchGroup = DispatchGroup()
        
        if self.isLocationAwareActive {
            PreyLogger("Location aware is active, sending to location aware endpoint")
            GeofencingManager.sharedInstance.startLocationAwareManager(location)
            self.isLocationAwareActive = false
            
            dispatchGroup.enter()
            self.sendDataWithCallback(locParam, toEndpoint: locationAwareEndpoint) { success in
                PreyLogger("Location aware endpoint request completed with success: \(success)")
                dispatchGroup.leave()
            }
            
            stopLocationManager()
        } else {
            PreyLogger("Sending location to data device endpoint")
            
            dispatchGroup.enter()
            self.sendDataWithCallback(locParam, toEndpoint: dataDeviceEndpoint) { success in
                PreyLogger("Data device endpoint location request completed with success: \(success)")
                dispatchGroup.leave()
            }
            
            index = index + 1
        }
        
        // Send device name
        let paramName:[String: Any] = [ "name" : UIDevice.current.name]
        
        dispatchGroup.enter()
        self.sendDataWithCallback(paramName, toEndpoint: dataDeviceEndpoint) { success in
            PreyLogger("Device name request completed with success: \(success)")
            dispatchGroup.leave()
        }
        
        // Get device info
        dispatchGroup.enter()
        PreyDevice.infoDevice { isSuccess in
            PreyLogger("infoDevice isSuccess: \(isSuccess)")
            dispatchGroup.leave()
        }
        
        // When all requests complete, end the background task
        dispatchGroup.notify(queue: .main) {
            // Give a little extra time for any pending network operations
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if bgTask != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(bgTask)
                    bgTask = UIBackgroundTaskIdentifier.invalid
                    PreyLogger("Location sending background task completed - all requests finished")
                }
            }
        }
    }
    
    // Helper method to send data with callback
    private func sendDataWithCallback(_ data: [String: Any], toEndpoint endpoint: String, completion: @escaping (Bool) -> Void) {
        guard let username = PreyConfig.sharedInstance.userApiKey else {
            PreyLogger("Cannot send data - no API key")
            completion(false)
            return
        }
        
        PreyHTTPClient.sharedInstance.userRegisterToPrey(
            username,
            password: "x",
            params: data,
            messageId: self.messageId,
            httpMethod: Method.POST.rawValue,
            endPoint: endpoint,
            onCompletion: PreyHTTPResponse.checkResponse(
                RequestType.dataSend,
                preyAction: self,
                onCompletion: { success in
                    completion(success)
                }
            )
        )
    }
    
    // MARK: CLLocationManagerDelegate
    
    // Did Update Locations
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        PreyLogger("New location received on Location")
        
        guard let currentLocation = locations.last else {
            return
        }
        
        // Check if location is cached (more lenient in background)
        let locationTime = abs(currentLocation.timestamp.timeIntervalSinceNow as Double)
        let timeThreshold = UIApplication.shared.applicationState == .active ? 5.0 : 30.0
        
        guard locationTime < timeThreshold else {
            PreyLogger("Location too old: \(locationTime) seconds")
            return
        }
        
        if currentLocation.horizontalAccuracy < 0 {
            PreyLogger("Invalid accuracy")
            return
        }

        if currentLocation.coordinate.longitude == 0 || currentLocation.coordinate.latitude == 0 {
            PreyLogger("Invalid coordinates")
            return
        }
        
        // Send first location
        if lastLocation == nil {
            PreyLogger("Sending first location: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
            locationReceived(currentLocation)
            lastLocation = currentLocation
            return
        }
        
        // Compare accuracy or check if significant movement occurred
        let distance = currentLocation.distance(from: lastLocation)
        if currentLocation.horizontalAccuracy < lastLocation.horizontalAccuracy || distance > 100 {
            PreyLogger("Sending updated location: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude), distance: \(distance)m")
            locationReceived(currentLocation)
        }

        // Save last location
        lastLocation = currentLocation
    }
    
    // Did fail with error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PreyLogger("Error getting location: \(error.localizedDescription)")
    }
}
