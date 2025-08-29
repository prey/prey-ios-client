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

class Location : PreyAction, CLLocationManagerDelegate, LocationDelegate, @unchecked Sendable {
    
    // MARK: Properties
    
    let locManager   = CLLocationManager()
    
    var lastLocation: CLLocation?
    
    var isLocationAwareActive = false
    
    var index = 0
    
    // Location deduplication constants (not currently used but kept for potential future use)
    private static let locationDeduplicationThreshold: TimeInterval = 5.0 // 5 seconds
    private static let locationDistanceThreshold: CLLocationDistance = 10.0 // 10 meters

    // Track if we reported any location during the current request session
    private var hasReportedThisSession = false
    
    // Mark when this action was created specifically for the daily location check
    // Used to stamp the last-successful daily send only on success
    var isDailyUpdateRun = false
    
    // MARK: Constants
    private static let cachedLocationMaxAge: TimeInterval = 300 // 5 minutes
    private static let locationTimeoutDuration: TimeInterval = 25.0 // seconds - standardized timeout  
    private static let backgroundTaskExtraTime: TimeInterval = 0.0 // seconds - removed extra delay
    private static let maxReasonableSpeedMps: Double = 100.0 // m/s (360 km/h)
    private static let teleportationDistanceThreshold: CLLocationDistance = 1000.0 // meters
    private static let teleportationTimeThreshold: TimeInterval = 60.0 // seconds
    
    // Adaptive routing thresholds by speed
    private static let walkSpeedMax: Double = 2.0     // m/s  (~7.2 km/h)
    private static let runSpeedMax: Double = 5.0      // m/s  (~18 km/h)
    private static let driveSpeedMin: Double = 10.0   // m/s  (~36 km/h)
    
    private static let walkDistanceThreshold: CLLocationDistance = 5.0   // meters (very precise)
    private static let runDistanceThreshold: CLLocationDistance = 10.0   // meters
    private static let driveDistanceThreshold: CLLocationDistance = 50.0 // meters (vehículo ~60 km/h)
    
    // Daily location check constants
    private static let dailyLocationInterval: TimeInterval = 24 * 60 * 60 // 24 hours - parametrizable
    private static let dailyLocationCheckKey = "PreyLastDailyLocationCheck"
    

    
    // MARK: Functions
    
    // MARK: LocationDelegate Implementation
    func didReceiveLocationUpdate(_ location: CLLocation) {
        PreyLogger("Received location update from service: \(location.coordinate.latitude), \(location.coordinate.longitude)", level: .info)
        // Reuse the same pipeline as didUpdateLocations (quality/security and adaptive sending)
        // Quality and security validations
        guard validateLocationQuality(location) else {
            PreyLogger("Location failed quality validation - discarding", level: .error)
            return
        }
        guard validateLocationSecurity(location) else {
            PreyLogger("Location failed security validation - potential GPS spoofing detected", level: .error)
            return
        }

        if lastLocation == nil {
            PreyLogger("Sending first location: \(location.coordinate.latitude), \(location.coordinate.longitude)", level: .info)
            locationReceived(location)
            lastLocation = location
            return
        }

        var shouldSend = false
        var distance: CLLocationDistance = 0
        if let last = lastLocation {
            distance = location.distance(from: last)
        }
        // Since LocationService adapts distanceFilter internally, use conservative thresholds here
        let currentFilter: CLLocationDistance = 10 // default to 10m unless service imposes larger
        if distance >= currentFilter {
            shouldSend = true
        } else if let last = lastLocation, location.horizontalAccuracy < last.horizontalAccuracy {
            shouldSend = true
        }

        if shouldSend {
            PreyLogger("Adaptive update: sending location (Δ=\(Int(distance))m)", level: .info)
            locationReceived(location)
        }
        lastLocation = location
    }
    
    // MARK: Daily Location Check Implementation
    
    // Check if daily location update is needed (similar to DeviceAuth pattern)
    class func checkDailyLocationUpdate() {
        let now = Date()
        let lastCheckTime = UserDefaults.standard.object(forKey: Location.dailyLocationCheckKey) as? Date
        
        // If never checked or more than dailyLocationInterval has passed
        let shouldCheck = lastCheckTime == nil || now.timeIntervalSince(lastCheckTime!) >= Location.dailyLocationInterval
        
        if shouldCheck {
            PreyLogger("Daily location check needed - last check: \(String(describing: lastCheckTime))", level: .info)
            
            // Check if we have valid API key (following DeviceAuth pattern)
            guard let _ = PreyConfig.sharedInstance.userApiKey else {
                PreyLogger("Cannot perform daily location check - no API key")
                return
            }
            
            // Create a location action to ensure location is sent
            let locationAction = Location(withTarget: kAction.location, withCommand: kCommand.get, withOptions: nil)
            locationAction.isDailyUpdateRun = true
            
            // Check if there's already a location action in the array
            var hasLocationAction = false
            for action in PreyModule.sharedInstance.actionArray {
                if action.target == kAction.location {
                    hasLocationAction = true
                    break
                }
            }
            
            if !hasLocationAction {
                PreyLogger("Adding daily location action", level: .info)
                PreyModule.sharedInstance.actionArray.append(locationAction)
            }
            
            // Run the location action to get current location
            PreyModule.sharedInstance.runSingleAction(locationAction)
            
            PreyLogger("Daily location check initiated", level: .info)
        } else {
            let timeUntilNext = Location.dailyLocationInterval - now.timeIntervalSince(lastCheckTime!)
            PreyLogger("Daily location check not needed - next check in: \(timeUntilNext/3600) hours", level: .info)
        }
    }
    
    // Get configured daily location interval (allows for future server configuration)
    class func getDailyLocationInterval() -> TimeInterval {
        // Could be extended to read from server config or PreyConfig
        return dailyLocationInterval
    }
    
    // Factory: allow creating actions for classic on-demand (.get) and aware mode
    class func initLocationAction(withTarget target:kAction, withCommand cmd:kCommand, withOptions opt:NSDictionary?) -> Location? {
        if cmd == kCommand.start_location_aware || cmd == kCommand.get {
            return Location(withTarget: target, withCommand: cmd, withOptions: opt)
        }
        return nil
    }
    
    // Send last known location (always sends something): live, cached, or fallback
    func sendLastLocation() {
        // 1) Try to use LocationService's last location if available (regardless of age)
        if let live = LocationService.shared.getLastLocation() {
            PreyLogger("On-demand: using manager's location (without validating age)", level: .info)
            locationReceived(live)
            return
        }
        // 2) Try shared cache (App Group), no age limit
        if let cached = buildLocationFromSharedCache() {
            PreyLogger("On-demand: using cached App Group location (no age limit)", level: .info)
            self.lastLocation = cached
            locationReceived(cached)
            return
        }
        // 3) Hard fallback: send payload with default values to respond to panel
        PreyLogger("On-demand: no location available; sending fallback", level: .info)
        let params: [String: Any] = [
            kLocation.lng.rawValue: 0.0,
            kLocation.lat.rawValue: 0.0,
            kLocation.alt.rawValue: 0.0,
            kLocation.accuracy.rawValue: -1.0,
            kLocation.method.rawValue: "unknown"
        ]
        let locParam: [String: Any] = [
            kAction.location.rawValue: params,
            kDataLocation.skip_toast.rawValue: (index > 0),
            // informational reason for backend/debug
            kData.reason.rawValue: "no_last_known_location"
        ]
        self.sendDataWithCallback(locParam, toEndpoint: dataDeviceEndpoint) { _ in }
        index = index + 1
    }
    
    // Prey command
    override func get() {
        // Classic on-demand: ALWAYS respond with the best available location
        PreyLogger("Location.get(): classic on-demand enabled; always responding with last known", level: .info)
        // Kick off a quick capture in background for future requests
        startLocationManager()
        // Immediately send the best we have right now
        sendLastLocation()
    }

    // Build CLLocation from shared cache (without validating age)
    private func buildLocationFromSharedCache() -> CLLocation? {
        guard let userDefaults = UserDefaults(suiteName: "group.com.prey.ios"),
              let cached = userDefaults.dictionary(forKey: "lastLocation"),
              let lat = cached["lat"] as? Double,
              let lng = cached["lng"] as? Double,
              let accuracy = cached["accuracy"] as? Double,
              let altitude = cached["alt"] as? Double,
              let timestamp = cached["timestamp"] as? TimeInterval
        else {
            return nil
        }
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        let date = Date(timeIntervalSince1970: timestamp)
        return CLLocation(
            coordinate: coord,
            altitude: altitude,
            horizontalAccuracy: accuracy,
            verticalAccuracy: 0,
            timestamp: date
        )
    }
    
    // Start location aware
    @objc func start_location_aware() {
        startLocationManager()
        isLocationAwareActive = true
        PreyLogger("Start location aware", level: .info)
    }
    
    // Removed on-demand timer/timeout; Location Push extension handles request-driven fixes
    
    // Start Location Manager with enhanced configuration
    func startLocationManager()  {
        PreyLogger("Starting location via LocationService (centralized)", level: .info)
        hasReportedThisSession = false
        // Subscribe to centralized service and request a foreground high-accuracy burst
        DeviceAuth.sharedInstance.addLocationDelegate(self)
        LocationService.shared.addDelegate(self)
        LocationService.shared.startForegroundHighAccuracyBurst()

        isActive = true
        index = 0
        PreyLogger("Location service burst started", level: .info)
    }
    
    // Stop Location Manager
    func stopLocationManager()  {
        PreyLogger("Stop location")
        DeviceAuth.sharedInstance.removeLocationDelegate(self)
        guard isActive else { return }
        locManager.stopUpdatingLocation()
        // Keep significant changes monitoring running only if desired; otherwise stop
        // For simplicity, keep it running for background wake-ups
        PreyLogger("Significant location changes monitoring remains active", level: .info)
        locManager.delegate = nil
        isActive = false
        PreyModule.sharedInstance.checkStatus(self)
    }
    
    // Location received
    func locationReceived(_ location:CLLocation) {
        PreyLogger("Processing location: \(location.coordinate.latitude), \(location.coordinate.longitude)", level: .info)
        hasReportedThisSession = true
        
        // Create location params - always send fresh location data
        let params:[String: Any] = [
            kLocation.lng.rawValue      : location.coordinate.longitude,
            kLocation.lat.rawValue      : location.coordinate.latitude,
            kLocation.alt.rawValue      : location.altitude,
            kLocation.accuracy.rawValue : location.horizontalAccuracy,
            kLocation.method.rawValue   : "native"
        ]
        
        // Save location to shared container
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
            PreyLogger("Saved location to shared container")
        }
        
        let locParam:[String: Any] = [kAction.location.rawValue : params, kDataLocation.skip_toast.rawValue : (index > 0)]
        
        if self.isLocationAwareActive {
            PreyLogger("Location aware is active, sending to location aware endpoint", level: .info)
            self.isLocationAwareActive = false
            self.sendDataWithCallback(locParam, toEndpoint: locationAwareEndpoint) { success in
                if success && self.isDailyUpdateRun {
                    UserDefaults.standard.set(Date(), forKey: Location.dailyLocationCheckKey)
                }
            }
            stopLocationManager()
        } else {
            PreyLogger("Sending location to data device endpoint", level: .info)
            self.sendDataWithCallback(locParam, toEndpoint: dataDeviceEndpoint) { success in
                if success && self.isDailyUpdateRun {
                    UserDefaults.standard.set(Date(), forKey: Location.dailyLocationCheckKey)
                }
            }
            index = index + 1
        }
    }
    
    // Send data to server with simple callback
    private func sendDataWithCallback(_ data: [String: Any], toEndpoint endpoint: String, completion: @escaping (Bool) -> Void) {
        guard let username = PreyConfig.sharedInstance.userApiKey else {
            PreyLogger("Cannot send data - no API key")
            completion(false)
            return
        }
        
        PreyHTTPClient.sharedInstance.sendDataToPrey(
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
        PreyLogger("New location received on Location", level: .info)
        
        guard let currentLocation = locations.last else {
            return
        }
        
        // Enhanced location validation with anti-spoofing measures
        guard validateLocationQuality(currentLocation) else {
            PreyLogger("Location failed quality validation - discarding", level: .error)
            return
        }
        
        // Additional security validation for anti-theft app
        guard validateLocationSecurity(currentLocation) else {
            PreyLogger("Location failed security validation - potential GPS spoofing detected", level: .error)
            return
        }
        
        // Send first location
        if lastLocation == nil {
            PreyLogger("Sending first location: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)", level: .info)
            locationReceived(currentLocation) // Automatic update
            lastLocation = currentLocation
            updateTrackingParameters(for: currentLocation)
            return
        }
        
        // Adaptive routing: send if distance exceeds dynamic threshold or accuracy improved
        var shouldSend = false
        var distance: CLLocationDistance = 0
        if let last = lastLocation {
            distance = currentLocation.distance(from: last)
        }
        // Update manager parameters based on current speed
        updateTrackingParameters(for: currentLocation)

        // Determine current threshold from manager's distanceFilter
        let threshold = max(locManager.distanceFilter, 0)
        if distance >= threshold {
            shouldSend = true
        } else if let last = lastLocation, currentLocation.horizontalAccuracy < last.horizontalAccuracy {
            shouldSend = true
        }

        if shouldSend {
            PreyLogger("Adaptive update: sending location (Δ=\(Int(distance))m ≥ \(Int(threshold))m)", level: .info)
            locationReceived(currentLocation)
        }
        // Save last location
        lastLocation = currentLocation
    }
    
    // Simplified error handling: just log
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PreyLogger("Location error: \(error.localizedDescription)", level: .error)
    }
    
    // MARK: Enhanced Methods for Security App
    
    // Configure battery-optimized location settings
    private func configureBatteryOptimizedSettings() {
        // Ensure battery monitoring is enabled to get a valid level
        if !UIDevice.current.isBatteryMonitoringEnabled {
            UIDevice.current.isBatteryMonitoringEnabled = true
        }
        let batteryLevel = UIDevice.current.batteryLevel
        let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        // Detect app state and missing/emergency status to pick a dynamic profile
        var isAppActive = false
        if Thread.isMainThread {
            isAppActive = UIApplication.shared.applicationState == .active
        } else {
            DispatchQueue.main.sync {
                isAppActive = UIApplication.shared.applicationState == .active
            }
        }
        let isMissing = PreyConfig.sharedInstance.isMissing
        
        PreyLogger("Configuring location for battery level: \(batteryLevel), low power mode: \(isLowPowerMode)", level: .info)
        
        // Default profile; refined dynamically per speed/mode
        locManager.activityType = .other
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.distanceFilter = 10
        locManager.pausesLocationUpdatesAutomatically = false
        PreyLogger("Default profile: BEST accuracy, distanceFilter=10m", level: .info)
    }

    // Dynamically adapt accuracy and distance filter based on inferred speed
    private func updateTrackingParameters(for currentLocation: CLLocation) {
        let speed = inferredSpeed(from: currentLocation)
        let desiredAcc: CLLocationAccuracy
        let distFilter: CLLocationDistance
        if speed < Location.walkSpeedMax { // walking
            desiredAcc = kCLLocationAccuracyBest
            distFilter = Location.walkDistanceThreshold
        } else if speed < Location.runSpeedMax { // running
            desiredAcc = kCLLocationAccuracyBest
            distFilter = Location.runDistanceThreshold
        } else { // driving or faster
            desiredAcc = kCLLocationAccuracyNearestTenMeters
            distFilter = Location.driveDistanceThreshold
        }

        if locManager.desiredAccuracy != desiredAcc {
            locManager.desiredAccuracy = desiredAcc
        }
        if locManager.distanceFilter != distFilter {
            locManager.distanceFilter = distFilter
        }
        PreyLogger("Adaptive profile: speed=\(String(format: "%.1f", speed)) m/s, acc=\(desiredAcc)m, filter=\(Int(distFilter))m", level: .info)
    }

    // Use location.speed if valid; otherwise infer from lastLocation timestamps
    private func inferredSpeed(from current: CLLocation) -> Double {
        if current.speed >= 0 { return current.speed }
        guard let last = lastLocation else { return 0 }
        let dt = current.timestamp.timeIntervalSince(last.timestamp)
        guard dt > 0 else { return 0 }
        return current.distance(from: last) / dt
    }
    
    // Enhanced location quality validation
    private func validateLocationQuality(_ location: CLLocation) -> Bool {
        // Fix: Get app state on main thread to avoid Main Thread Checker warning
        var isAppActive = false
        if Thread.isMainThread {
            isAppActive = UIApplication.shared.applicationState == .active
        } else {
            DispatchQueue.main.sync {
                isAppActive = UIApplication.shared.applicationState == .active
            }
        }

        // Check for null island coordinates (0,0) and invalid coordinate ranges
        guard CLLocationCoordinate2DIsValid(location.coordinate) else {
            PreyLogger("Invalid coordinates detected", level: .error)
            return false
        }

        if location.coordinate.longitude == 0 && location.coordinate.latitude == 0 {
            PreyLogger("Invalid null island coordinates (0,0) detected", level: .error)
            return false
        }

        // Check location age with different thresholds based on app state
        let locationTime = abs(location.timestamp.timeIntervalSinceNow)

        // Accept older cached fixes in background to avoid dropping reports when the device is stationary
        // Foreground: 10s, Background: 300s (5 min), Emergency: 10s
        let maxAge: TimeInterval = isAppActive ? 10.0 : Location.cachedLocationMaxAge

        guard locationTime <= maxAge else {
            PreyLogger("Location too old: \(locationTime)s > \(maxAge)s (active=\(isAppActive))", level: .error)
            return false
        }

        return true
    }
    
    // Anti-spoofing security validation for security app
    private func validateLocationSecurity(_ location: CLLocation) -> Bool {
        guard let lastLoc = lastLocation else {
            // First location, accept it
            return true
        }
        
        // Calculate movement speed to detect impossible movements (GPS spoofing)
        let distance = location.distance(from: lastLoc)
        let timeInterval = location.timestamp.timeIntervalSince(lastLoc.timestamp)
        
        guard timeInterval > 0 else {
            PreyLogger("Invalid time interval between locations", level: .error)
            return false
        }
        
        let speed = distance / timeInterval // meters per second
        
        if speed > Location.maxReasonableSpeedMps {
            PreyLogger("⚠️ SECURITY ALERT: Impossible speed detected: \(speed) m/s (\(speed * 3.6) km/h) - potential GPS spoofing", level: .error)
            // For security app, we still want to log this but maybe with lower confidence
            return false
        }
        
        // Additional validation: check for teleportation (large distance, short time)
        if distance > Location.teleportationDistanceThreshold && timeInterval < Location.teleportationTimeThreshold {
            PreyLogger("⚠️ SECURITY ALERT: Potential teleportation detected: \(distance)m in \(timeInterval)s", level: .error)
            return false
        }
        
        return true
    }
    
    // Removed retry/queue/emergency helpers: extension + aware mode cover our needs
    
    // Monitor authorization changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        PreyLogger("Location authorization changed to: \(status.rawValue)", level: .info)
        
        switch status {
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        case .denied, .restricted:
            PreyLogger("⚠️ Location access denied - security app functionality compromised", level: .error)
            // For security app, this is critical - might need to alert user
        case .authorizedWhenInUse:
            PreyLogger("Location authorized when in use - requesting 'always' for security app", level: .info)
            manager.requestAlwaysAuthorization()
        case .authorizedAlways:
            PreyLogger("✅ Location authorization optimal - configuring for background operation", level: .info)
            configureBatteryOptimizedSettings()
        @unknown default:
            PreyLogger("Unknown authorization status: \(status)", level: .error)
        }
    }
}
