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
    // Ensure only one Location instance owns the location-aware delegate at a time
    private static weak var activeAwareOwner: Location?

    // Stop the global location-aware session if running
    static func stopLocationAwareIfRunning() {
        guard let owner = Location.activeAwareOwner else { return }
        owner.isLocationAwareActive = false
        owner.stopLocationManager()
        Location.activeAwareOwner = nil
        PreyLogger("LocationAware: stopped by server directive", level: .info)
    }
    private var awareLastSentAt: Date?
    private let awareMinInterval: TimeInterval = 60 // seconds between aware sends

    // Simple burst limiter for general data endpoint (reduce 403 on resume)
    private var lastGeneralSendAt: Date?
    private let generalMinInterval: TimeInterval = 10 // seconds between general sends
    
    var index = 0

    // Track if we reported any location during the current request session
    private var hasReportedThisSession = false
    
    // Mark when this action was created specifically for the daily location check
    // Used to stamp the last-successful daily send only on success
    var isDailyUpdateRun = false
    
    // MARK: Constants
    private static let cachedLocationMaxAge: TimeInterval = 300 // 5 minutes
    
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
            PreyDebugNotify("Location quality validation failed")
            return
        }

        if lastLocation == nil {
            PreyLogger("Sending first location: \(location.coordinate.latitude), \(location.coordinate.longitude)", level: .info)
            locationReceived(location)
            lastLocation = location
            return
        }

        var distance: CLLocationDistance = 0
        if let last = lastLocation {
            distance = location.distance(from: last)
        }
        // Send only if there was real movement (>= 10 m). Do not send for mere accuracy improvements.
        let currentFilter: CLLocationDistance = 10 // 10m
        if distance >= currentFilter {
            PreyLogger("Adaptive update: sending location (Δ=\(Int(distance))m)", level: .info)
            PreyDebugNotify("Location: adaptive send Δ=\(Int(distance))m")
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
        // Prevent multiple distinct Location instances from registering as delegates simultaneously
        if let owner = Location.activeAwareOwner, owner !== self {
            PreyLogger("LocationAware already running; ignoring duplicate request", level: .info)
            isLocationAwareActive = true
            return
        }
        Location.activeAwareOwner = self
        startLocationManager()
        isLocationAwareActive = true
        PreyLogger("Start location aware", level: .info)
        PreyDebugNotify("LocationAware: started")
    }
    
    // Removed on-demand timer/timeout; Location Push extension handles request-driven fixes
    
    // Start Location Manager with enhanced configuration
    func startLocationManager()  {
        PreyLogger("Starting location via LocationService (centralized)", level: .info)
        hasReportedThisSession = false
        // Use only centralized LocationService, remove duplicate delegate registration
        LocationService.shared.addDelegate(self)
        LocationService.shared.startForegroundHighAccuracyBurst()

        isActive = true
        index = 0
        PreyLogger("Location service burst started", level: .info)
    }
    
    // Stop Location Manager
    func stopLocationManager()  {
        PreyLogger("Stop location")
        // Remove from centralized service only
        LocationService.shared.removeDelegate(self)
        guard isActive else { return }
        // Let LocationService manage the actual CLLocationManager
        PreyLogger("Removed from LocationService delegates", level: .info)
        isActive = false
        if isLocationAwareActive && Location.activeAwareOwner === self {
            Location.activeAwareOwner = nil
        }
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
            // Throttle aware sends to avoid spamming
            let now = Date()
            if let last = awareLastSentAt, now.timeIntervalSince(last) < awareMinInterval {
                PreyLogger("Location aware active, but throttled (next in \(Int(awareMinInterval - now.timeIntervalSince(last)))s)", level: .info)
                PreyDebugNotify("LocationAware: throttled, next in \(Int(awareMinInterval - now.timeIntervalSince(last)))s")
            } else {
                PreyLogger("Location aware is active, sending to location aware endpoint", level: .info)
                awareLastSentAt = now
                PreyDebugNotify(String(format: "LocationAware: sending lat=%.5f lon=%.5f acc=%.1f", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy))
                self.sendDataWithCallback(locParam, toEndpoint: locationAwareEndpoint) { success in
                    if success && self.isDailyUpdateRun {
                        UserDefaults.standard.set(Date(), forKey: Location.dailyLocationCheckKey)
                    }
                }
            }
            // Keep manager running for continuous aware updates; do not stop here
            // stopLocationManager()
        } else {
            let now = Date()
            if let last = lastGeneralSendAt, now.timeIntervalSince(last) < generalMinInterval {
                let wait = Int(generalMinInterval - now.timeIntervalSince(last))
                PreyLogger("General location send throttled (next in \(wait)s)", level: .info)
                PreyDebugNotify("Location: throttled, next in \(wait)s")
            } else {
                PreyLogger("Sending location to data device endpoint", level: .info)
                PreyDebugNotify(String(format: "Location: sending lat=%.5f lon=%.5f acc=%.1f", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy))
                lastGeneralSendAt = now
                self.sendDataWithCallback(locParam, toEndpoint: dataDeviceEndpoint) { success in
                    if success && self.isDailyUpdateRun {
                        UserDefaults.standard.set(Date(), forKey: Location.dailyLocationCheckKey)
                    }
                }
                index = index + 1
            }
        }

        // For on-demand captures (not aware mode), stop listening after the first handled fix
        // to avoid multiple delegates lingering and causing duplicate sends/logs.
        if !isLocationAwareActive {
            stopLocationManager()
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
        
        // Send first location
        if lastLocation == nil {
            PreyLogger("Sending first location: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)", level: .info)
            locationReceived(currentLocation)
            lastLocation = currentLocation
            return
        }
        
        let distance = currentLocation.distance(from: lastLocation!)
        
        // Send only if there was real movement (>= 25 m). Do not send for mere accuracy improvements.
        if distance >= 25 {
            PreyLogger("Location update: sending (Δ=\(Int(distance))m)", level: .info)
            locationReceived(currentLocation)
        }
        lastLocation = currentLocation
    }
    
    // Simplified error handling: just log
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PreyLogger("Location error: \(error.localizedDescription)", level: .error)
    }
    
    // MARK: Enhanced Methods for Security App
    
    // Removed: using centralized LocationService configuration

    // Removed: using centralized LocationService without adaptive parameters
    
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
        // Foreground: 10s, Background: 300s (5 min) by default.
        // If in aware mode and in background, allow up to 15 minutes
        var maxAge: TimeInterval = isAppActive ? 10.0 : Location.cachedLocationMaxAge
        if !isAppActive && isLocationAwareActive { maxAge = max(maxAge, 900.0) }

        guard locationTime <= maxAge else {
            PreyLogger("Location too old: \(locationTime)s > \(maxAge)s (active=\(isAppActive))", level: .error)
            PreyDebugNotify("Location too old: \(Int(locationTime))s > \(Int(maxAge))s")
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
            PreyLogger("✅ Location authorization optimal - using centralized LocationService", level: .info)
        @unknown default:
            PreyLogger("Unknown authorization status: \(status)", level: .error)
        }
    }
}
