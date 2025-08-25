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
    
    var lastLocation : CLLocation!
    
    var isLocationAwareActive = false
    
    var index = 0
    
    // Background task identifier
    private var locationBgTaskId: UIBackgroundTaskIdentifier = .invalid
    
    // Enhanced properties for improved tracking
    private var isEmergencyMode = false
    private var originalAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters
    private var originalDistanceFilter: CLLocationDistance = 100
    private var retryCount = 0
    private let maxRetryCount = 3
    private var lastValidationTime: Date?
    
    // Single background task management - removed dictionary to prevent multiple concurrent tasks
    
    // Location deduplication constants (not currently used but kept for potential future use)
    private static let locationDeduplicationThreshold: TimeInterval = 5.0 // 5 seconds
    private static let locationDistanceThreshold: CLLocationDistance = 10.0 // 10 meters

    // Track if we reported any location during the current request session
    private var hasReportedThisSession = false
    
    // One-shot timer to request a single location near timeout
    private var oneShotRequestTimer: Timer?

    // Mark when this action was created specifically for the daily location check
    // Used to stamp the last-successful daily send only on success
    var isDailyUpdateRun = false
    
    // MARK: Constants
    private static let cachedLocationMaxAge: TimeInterval = 300 // 5 minutes
    private static let locationTimeoutDuration: TimeInterval = 25.0 // seconds - standardized timeout  
    private static let backgroundTaskExtraTime: TimeInterval = 0.0 // seconds - removed extra delay
    private static let offlineQueueRetryDelay: TimeInterval = 1.0 // seconds
    private static let offlineQueueMaxSize: Int = 50
    private static let maxLocationAccuracy: CLLocationAccuracy = 200.0 // meters
    private static let significantMovementDistance: CLLocationDistance = 100.0 // meters
    private static let maxReasonableSpeedMps: Double = 100.0 // m/s (360 km/h)
    private static let teleportationDistanceThreshold: CLLocationDistance = 1000.0 // meters
    private static let teleportationTimeThreshold: TimeInterval = 60.0 // seconds
    private static let locationRetryDelay: TimeInterval = 2.0 // seconds
    private static let maxRetryDelay: TimeInterval = 60.0 // seconds
    
    // Daily location check constants
    private static let dailyLocationInterval: TimeInterval = 24 * 60 * 60 // 24 hours - parametrizable
    private static let dailyLocationCheckKey = "PreyLastDailyLocationCheck"
    
    
    
    // Offline location queue for failed transmissions
    private var offlineLocationQueue: [LocationData] = []
    private let offlineQueue = DispatchQueue(label: "location.offline", qos: .utility)
    
    // MARK: Functions
    
    // MARK: LocationDelegate Implementation
    func didReceiveLocationUpdate(_ location: CLLocation) {
        PreyLogger("Received location update from DeviceAuth: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        // Process the location using our existing logic
        locationReceived(location)
    }
    
    // MARK: Daily Location Check Implementation
    
    // Check if daily location update is needed (similar to DeviceAuth pattern)
    class func checkDailyLocationUpdate() {
        let now = Date()
        let lastCheckTime = UserDefaults.standard.object(forKey: Location.dailyLocationCheckKey) as? Date
        
        // If never checked or more than dailyLocationInterval has passed
        let shouldCheck = lastCheckTime == nil || now.timeIntervalSince(lastCheckTime!) >= Location.dailyLocationInterval
        
        if shouldCheck {
            PreyLogger("Daily location check needed - last check: \(String(describing: lastCheckTime))")
            
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
                PreyLogger("Adding daily location action")
                PreyModule.sharedInstance.actionArray.append(locationAction)
            }
            
            // Run the location action to get current location
            PreyModule.sharedInstance.runSingleAction(locationAction)
            
            PreyLogger("Daily location check initiated")
        } else {
            let timeUntilNext = Location.dailyLocationInterval - now.timeIntervalSince(lastCheckTime!)
            PreyLogger("Daily location check not needed - next check in: \(timeUntilNext/3600) hours")
        }
    }
    
    // Get configured daily location interval (allows for future server configuration)
    class func getDailyLocationInterval() -> TimeInterval {
        // Could be extended to read from server config or PreyConfig
        return dailyLocationInterval
    }
    
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
    
    // Send lastLocation - improved to get fresh location if cached is too old
    func sendLastLocation() {
        PreyLogger("sendLastLocation() called")
        
        // Check if we have a cached location and if it's still fresh
        if let cachedLocation = lastLocation {
            let locationAge = Date().timeIntervalSince(cachedLocation.timestamp)
            PreyLogger("Cached location age: \(locationAge) seconds (max allowed: \(Location.cachedLocationMaxAge))")
            
            if locationAge <= Location.cachedLocationMaxAge {
                PreyLogger("Using cached location (fresh enough)")
                // Send cached location to web panel
                locationReceived(cachedLocation)
                return
            } else {
                PreyLogger("Cached location is too old (\(locationAge)s), requesting fresh location")
            }
        } else {
            PreyLogger("No cached location available, requesting fresh location")
        }
        
        // Cached location is too old or doesn't exist - get fresh location
        // This will trigger the same flow as a regular location request
        PreyLogger("Calling get() to obtain fresh location for web request")
        get()
    }
    
    // Prey command
    override func get() {
        // Fix: Check app state on main thread to avoid Main Thread Checker warning
        var appStateString = "Unknown"
        if Thread.isMainThread {
            appStateString = UIApplication.shared.applicationState == .background ? "Background" : "Foreground"
        } else {
            DispatchQueue.main.sync {
                appStateString = UIApplication.shared.applicationState == .background ? "Background" : "Foreground"
            }
        }
        PreyLogger("Location.get() called - App State: \(appStateString)")
        
        // Make sure location services are enabled
        if CLLocationManager.locationServicesEnabled() == false {
            PreyLogger("⚠️ Location services are disabled system-wide")
            // Try to initialize anyway in case user enables later
        }
        
        // Check authorization status using instance method to avoid main thread blocking
        let authStatus = locManager.authorizationStatus
        if authStatus != .authorizedAlways {
            PreyLogger("⚠️ Location authorization status is not .authorizedAlways: \(authStatus)")
            // Request authorization just in case
            locManager.requestAlwaysAuthorization()
        }
        
        // Start the location manager
        startLocationManager()
        
        // Schedule get location with timeout
        Timer.scheduledTimer(timeInterval: Location.locationTimeoutDuration, target:self, selector:#selector(stopLocationTimer(_:)), userInfo:nil, repeats:false)

        // Schedule a one-shot location request a few seconds before timeout if no report yet
        let oneShotLead: TimeInterval = 3.0
        if Location.locationTimeoutDuration > oneShotLead {
            oneShotRequestTimer = Timer.scheduledTimer(withTimeInterval: Location.locationTimeoutDuration - oneShotLead, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                if !self.hasReportedThisSession {
                    PreyLogger("Attempting one-shot requestLocation() before timeout")
                    self.locManager.requestLocation()
                }
            }
        }

        
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
                
                // Only use cached location if it's recent
                if abs(date.timeIntervalSinceNow) < Location.cachedLocationMaxAge {
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
    
    // Start location aware
    @objc func start_location_aware() {
        startLocationManager()
        isLocationAwareActive = true
        PreyLogger("Start location aware")
    }
    
    // Stop Location Timer
    @objc func stopLocationTimer(_ timer:Timer)  {
        timer.invalidate()

        // Invalidate pending one-shot timer
        oneShotRequestTimer?.invalidate()
        oneShotRequestTimer = nil

        // If no location was reported during this session, try to send a fallback location
        if !hasReportedThisSession {
            var fallbackLocation: CLLocation?

            // Prefer the last in-memory fix
            fallbackLocation = lastLocation

            // If not available, use the manager's last known fix
            if fallbackLocation == nil {
                fallbackLocation = locManager.location
            }

            // If still nil, read from shared container cache (as last resort)
            if fallbackLocation == nil,
               let userDefaults = UserDefaults(suiteName: "group.com.prey.ios"),
               let cached = userDefaults.dictionary(forKey: "lastLocation"),
               let lat = cached["lat"] as? Double,
               let lng = cached["lng"] as? Double,
               let accuracy = cached["accuracy"] as? Double,
               let altitude = cached["alt"] as? Double,
               let timestamp = cached["timestamp"] as? TimeInterval {
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                let date = Date(timeIntervalSince1970: timestamp)
                fallbackLocation = CLLocation(
                    coordinate: coord,
                    altitude: altitude,
                    horizontalAccuracy: accuracy,
                    verticalAccuracy: 0,
                    timestamp: date
                )
            }

            if let fallback = fallbackLocation {
                PreyLogger("Timeout without fresh fix; sending fallback (age: \(abs(fallback.timestamp.timeIntervalSinceNow))s, acc: \(fallback.horizontalAccuracy)m)")
                locationReceived(fallback)
            } else {
                PreyLogger("Timeout reached and no fallback location available")
            }
        }

        stopLocationManager()
    }
    
    // Start Location Manager with enhanced configuration
    func startLocationManager()  {
        PreyLogger("Starting location manager with enhanced configuration")
        
        // Check if DeviceAuth already has a background location manager running
        if DeviceAuth.sharedInstance.isBackgroundLocationManagerActive() {
            PreyLogger("Using existing background location manager from DeviceAuth")
            // Register as delegate to receive location updates from DeviceAuth
            DeviceAuth.sharedInstance.addLocationDelegate(self)
            return
        }
        
        // End any existing background task first
        if locationBgTaskId != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(locationBgTaskId)
            locationBgTaskId = UIBackgroundTaskIdentifier.invalid
        }
        
        // Reset session state and configure manager
        hasReportedThisSession = false
        // Configure location manager with adaptive settings
        locManager.requestAlwaysAuthorization()
        locManager.delegate = self
        
        // Apply battery-aware configuration
        configureBatteryOptimizedSettings()
        
        // Configure for background operation
        locManager.allowsBackgroundLocationUpdates = true
        locManager.showsBackgroundLocationIndicator = true // Shows the blue bar when app uses location in background
        
        // Always enable significant location changes to support wake-ups for action checks
        locManager.startMonitoringSignificantLocationChanges()
        PreyLogger("Started monitoring significant location changes")
        
        // Start regular location updates
        locManager.startUpdatingLocation()
        
        // Begin background task to ensure we have time to get location
        locationBgTaskId = UIApplication.shared.beginBackgroundTask { [weak self] in
            guard let self = self else { return }
            
            PreyLogger("Location background task expiring - ID: \(self.locationBgTaskId.rawValue)")
            
            // Stop location updates to conserve battery
            self.locManager.stopUpdatingLocation()
            self.locManager.stopMonitoringSignificantLocationChanges()
            
            // End the background task properly
            if self.locationBgTaskId != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(self.locationBgTaskId)
                self.locationBgTaskId = UIBackgroundTaskIdentifier.invalid
                PreyLogger("Location background task ended properly")
            }
            
            // If we still need location, rely on significant location changes only
            if self.isActive {
                self.locManager.startMonitoringSignificantLocationChanges()
                PreyLogger("Switched to significant location changes only")
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
        
        // Remove ourselves as delegate from DeviceAuth if we were using their location manager
        DeviceAuth.sharedInstance.removeLocationDelegate(self)
        
        // Check if location manager is actually running to avoid unnecessary stops
        guard isActive else {
            PreyLogger("Location manager already stopped, skipping")
            return
        }
        
        locManager.stopUpdatingLocation()
        // Keep significant location changes active to preserve background wake-ups
        // This helps tracking while stationary with minimal battery impact
        PreyLogger("Keeping significant location changes monitoring active for background wake-ups")
        
        // End background task if active
        if locationBgTaskId != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(locationBgTaskId)
            PreyLogger("Location background task ended with ID: \(locationBgTaskId.rawValue)")
            locationBgTaskId = UIBackgroundTaskIdentifier.invalid
        }
        
        // Background task already ended above - no additional cleanup needed
        
        // Set delegate to nil to prevent callbacks
        locManager.delegate = nil
        
        isActive = false
        PreyModule.sharedInstance.checkStatus(self)
    }
    
    // Location received
    func locationReceived(_ location:CLLocation) {
        PreyLogger("Processing location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        hasReportedThisSession = true
        
        // Use the existing background task instead of creating a new one for each location
        // This prevents multiple concurrent background tasks
        if locationBgTaskId == .invalid {
            PreyLogger("Warning: locationReceived called but no active background task")
        }
 
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
            userDefaults.synchronize()
            PreyLogger("Saved location to shared container")
        }
        
        let locParam:[String: Any] = [kAction.location.rawValue : params, kDataLocation.skip_toast.rawValue : (index > 0)]
        
        // Use dispatch group to track when all API calls complete
        let dispatchGroup = DispatchGroup()
        
        if self.isLocationAwareActive {
            PreyLogger("Location aware is active, sending to location aware endpoint")
            self.isLocationAwareActive = false
            
            dispatchGroup.enter()
            self.sendDataWithCallback(locParam, toEndpoint: locationAwareEndpoint) { success in
                PreyLogger("Location aware endpoint request completed with success: \(success)")
                if success && self.isDailyUpdateRun {
                    UserDefaults.standard.set(Date(), forKey: Location.dailyLocationCheckKey)
                    UserDefaults.standard.synchronize()
                    PreyLogger("Stamped daily location check timestamp (aware)")
                }
                dispatchGroup.leave()
            }
            
            stopLocationManager()
        } else {
            PreyLogger("Sending location to data device endpoint")
            
            dispatchGroup.enter()
            self.sendDataWithCallback(locParam, toEndpoint: dataDeviceEndpoint) { success in
                PreyLogger("Data device endpoint location request completed with success: \(success)")
                if success && self.isDailyUpdateRun {
                    UserDefaults.standard.set(Date(), forKey: Location.dailyLocationCheckKey)
                    UserDefaults.standard.synchronize()
                    PreyLogger("Stamped daily location check timestamp")
                }
                dispatchGroup.leave()
            }
            
            index = index + 1
        }
        
        // Device name is handled separately via device_renamed events - no need to send with location
        
        // Device info is now handled by scheduled sync tasks to avoid excessive calls
        // No need to call infoDevice on every location update
        
        // When all requests complete, the main background task continues running
        // Individual location sends don't need separate background tasks
        dispatchGroup.notify(queue: .main) {
            PreyLogger("Location data sent successfully - main background task continues")
            // No need to end background task here - it's managed by the main location service
            
            // Reset retry count on successful transmission
            self.retryCount = 0
            
            // Process any queued offline locations
            // self.processOfflineLocationQueue()
        }
    }
    
    // Enhanced helper method to send data with offline queue support
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
                    if !success {
                        // Queue location data for offline retry
                        self.queueLocationForOfflineRetry(data, endpoint: endpoint)
                        PreyLogger("Location transmission failed - queued for offline retry")
                    }
                    completion(success)
                }
            )
        )
    }
    
    // Queue location data for offline retry
    private func queueLocationForOfflineRetry(_ data: [String: Any], endpoint: String) {
        let locationData = LocationData(data: data, endpoint: endpoint, timestamp: Date())
        
        offlineQueue.async {
            self.offlineLocationQueue.append(locationData)
            
            // Limit queue size to prevent memory issues
            if self.offlineLocationQueue.count > Location.offlineQueueMaxSize {
                self.offlineLocationQueue.removeFirst()
                PreyLogger("Offline location queue full - removed oldest entry")
            }
            
            PreyLogger("Queued location data for offline retry. Queue size: \(self.offlineLocationQueue.count)")
        }
    }
    
    // Process queued offline locations when connection is available
    private func processOfflineLocationQueue() {
        guard !offlineLocationQueue.isEmpty else { return }
        
        PreyLogger("Processing \(offlineLocationQueue.count) queued offline locations")
        
        offlineQueue.async {
            self.processOfflineQueueRecursively(locations: Array(self.offlineLocationQueue), index: 0)
        }
    }
    
    // Process offline queue recursively with proper async delays
    private func processOfflineQueueRecursively(locations: [LocationData], index: Int) {
        guard index < locations.count else { 
            PreyLogger("Finished processing offline location queue")
            return 
        }
        
        let locationData = locations[index]
        
        // Try to send each queued location
        DispatchQueue.main.async {
            self.sendDataWithCallback(locationData.data, toEndpoint: locationData.endpoint) { success in
                if success {
                    self.offlineQueue.async {
                        if let removeIndex = self.offlineLocationQueue.firstIndex(where: { $0.id == locationData.id }) {
                            self.offlineLocationQueue.remove(at: removeIndex)
                            PreyLogger("Successfully sent queued location data")
                        }
                    }
                }
                
                // Schedule next item with delay to avoid overwhelming the server
                DispatchQueue.main.asyncAfter(deadline: .now() + Location.offlineQueueRetryDelay) {
                    self.processOfflineQueueRecursively(locations: locations, index: index + 1)
                }
            }
        }
    }
    
    // MARK: CLLocationManagerDelegate
    
    // Did Update Locations
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        PreyLogger("New location received on Location")
        
        guard let currentLocation = locations.last else {
            return
        }
        
        // Enhanced location validation with anti-spoofing measures
        guard validateLocationQuality(currentLocation) else {
            PreyLogger("Location failed quality validation - discarding")
            return
        }
        
        // Additional security validation for anti-theft app
        guard validateLocationSecurity(currentLocation) else {
            PreyLogger("Location failed security validation - potential GPS spoofing detected")
            return
        }
        
        // Send first location
        if lastLocation == nil {
            PreyLogger("Sending first location: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
            locationReceived(currentLocation) // Automatic update
            lastLocation = currentLocation
            return
        }
        
        // Compare accuracy or check if significant movement occurred
        let distance = currentLocation.distance(from: lastLocation)
        if currentLocation.horizontalAccuracy < lastLocation.horizontalAccuracy || distance > Location.significantMovementDistance {
            PreyLogger("Sending updated location: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude), distance: \(distance)m")
            locationReceived(currentLocation) // Automatic update
        }

        // Save last location
        lastLocation = currentLocation
    }
    
    // Enhanced error handling with retry mechanisms
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PreyLogger("Location error: \(error.localizedDescription)")
        
        handleLocationError(error)
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
        
        PreyLogger("Configuring location for battery level: \(batteryLevel), low power mode: \(isLowPowerMode)")
        
        // Set an appropriate activity type for our use case (security/tracking)
        locManager.activityType = .other
        
        // Dynamic profiles
        if isEmergencyMode || isMissing || isAppActive {
            // High-accuracy burst (action window, missing, or foreground)
            locManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locManager.distanceFilter = 50
            locManager.pausesLocationUpdatesAutomatically = false
            PreyLogger("Dynamic profile: HIGH accuracy (window/missing/foreground)")
        } else if isLowPowerMode || batteryLevel >= 0 && batteryLevel < 0.2 {
            // Battery saver when idle in background
            locManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locManager.distanceFilter = 500
            locManager.pausesLocationUpdatesAutomatically = true
            PreyLogger("Dynamic profile: BATTERY SAVER (background + LPM/low battery)")
        } else {
            // Balanced background tracking
            locManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locManager.distanceFilter = 200
            locManager.pausesLocationUpdatesAutomatically = true
            PreyLogger("Dynamic profile: BALANCED (background)")
        }
        
        // Store original settings for restoration
        originalAccuracy = locManager.desiredAccuracy
        originalDistanceFilter = locManager.distanceFilter
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

        // Dynamic accuracy threshold: stricter en foreground
        let maxAllowedAccuracy: CLLocationAccuracy = isAppActive ? Location.maxLocationAccuracy : 500.0

        // Check basic validity
        guard location.horizontalAccuracy > 0 && location.horizontalAccuracy <= maxAllowedAccuracy else {
            PreyLogger("Location accuracy out of bounds (active=\(isAppActive)): \(location.horizontalAccuracy)m > \(maxAllowedAccuracy)m")
            return false
        }

        // Check for null island coordinates (0,0) and invalid coordinate ranges
        guard CLLocationCoordinate2DIsValid(location.coordinate) else {
            PreyLogger("Invalid coordinates detected")
            return false
        }

        if location.coordinate.longitude == 0 && location.coordinate.latitude == 0 {
            PreyLogger("Invalid null island coordinates (0,0) detected")
            return false
        }

        // Check location age with different thresholds based on app state
        let locationTime = abs(location.timestamp.timeIntervalSinceNow)

        // Accept older cached fixes in background to avoid dropping reports when the device is stationary
        // Foreground: 10s, Background: 300s (5 min), Emergency: 10s
        let maxAge: TimeInterval = isEmergencyMode ? 10.0 : (isAppActive ? 10.0 : Location.cachedLocationMaxAge)

        guard locationTime <= maxAge else {
            PreyLogger("Location too old: \(locationTime)s > \(maxAge)s (active=\(isAppActive))")
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
            PreyLogger("Invalid time interval between locations")
            return false
        }
        
        let speed = distance / timeInterval // meters per second
        
        if speed > Location.maxReasonableSpeedMps {
            PreyLogger("⚠️ SECURITY ALERT: Impossible speed detected: \(speed) m/s (\(speed * 3.6) km/h) - potential GPS spoofing")
            // For security app, we still want to log this but maybe with lower confidence
            return false
        }
        
        // Additional validation: check for teleportation (large distance, short time)
        if distance > Location.teleportationDistanceThreshold && timeInterval < Location.teleportationTimeThreshold {
            PreyLogger("⚠️ SECURITY ALERT: Potential teleportation detected: \(distance)m in \(timeInterval)s")
            return false
        }
        
        return true
    }
    
    // Enhanced error handling with retry logic
    private func handleLocationError(_ error: Error) {
        guard let clError = error as? CLError else {
            PreyLogger("Unknown location error: \(error)")
            return
        }
        
        switch clError.code {
        case .denied:
            PreyLogger("Location access denied - requesting permission")
            requestLocationPermissionIfNeeded()
            
        case .locationUnknown:
            PreyLogger("Location unknown - implementing retry strategy")
            retryWithReducedAccuracy()
            
        case .network:
            PreyLogger("Network error - scheduling location retry")
            scheduleLocationRetry()
            
        case .regionMonitoringDenied, .regionMonitoringFailure:
            PreyLogger("Region monitoring failed - falling back to standard location")
            fallbackToStandardLocation()
            
        default:
            PreyLogger("Location error code: \(clError.code.rawValue) - \(clError.localizedDescription)")
            if retryCount < maxRetryCount {
                scheduleLocationRetry()
            }
        }
    }
    
    // Request location permission if needed
    private func requestLocationPermissionIfNeeded() {
        // Use the instance's authorizationStatus to avoid main thread blocking
        let status = locManager.authorizationStatus
        PreyLogger("Current location authorization status: \(status.rawValue)")
        
        switch status {
        case .notDetermined:
            locManager.requestAlwaysAuthorization()
        case .denied, .restricted:
            PreyLogger("⚠️ Location access denied - security app functionality limited")
            // For security app, we might want to show user guidance
        case .authorizedWhenInUse:
            // For security app, we need "always" authorization
            PreyLogger("Requesting 'always' authorization for security app")
            locManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            PreyLogger("Location authorization optimal for security app")
        @unknown default:
            PreyLogger("Unknown authorization status: \(status)")
        }
    }
    
    // Retry location with reduced accuracy
    private func retryWithReducedAccuracy() {
        guard retryCount < maxRetryCount else {
            PreyLogger("Max retry attempts reached for location")
            return
        }
        
        retryCount += 1
        PreyLogger("Retrying location with reduced accuracy (attempt \(retryCount)/\(maxRetryCount))")
        
        // Temporarily reduce accuracy for retry
        let currentAccuracy = locManager.desiredAccuracy
        if currentAccuracy < kCLLocationAccuracyHundredMeters {
            locManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        } else if currentAccuracy < kCLLocationAccuracyKilometer {
            locManager.desiredAccuracy = kCLLocationAccuracyKilometer
        }
        
        // Restart location updates
        locManager.stopUpdatingLocation()
        DispatchQueue.main.asyncAfter(deadline: .now() + Location.locationRetryDelay) {
            self.locManager.startUpdatingLocation()
        }
    }
    
    // Schedule location retry for network/temporary errors
    private func scheduleLocationRetry() {
        guard retryCount < maxRetryCount else {
            PreyLogger("Max retry attempts reached for location")
            return
        }
        
        retryCount += 1
        let retryDelay = min(pow(2.0, Double(retryCount)), Location.maxRetryDelay) // Exponential backoff
        
        PreyLogger("Scheduling location retry in \(retryDelay) seconds (attempt \(retryCount)/\(maxRetryCount))")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
            if self.isActive {
                self.locManager.startUpdatingLocation()
            }
        }
    }
    
    // Fallback to standard location when region monitoring fails
    private func fallbackToStandardLocation() {
        PreyLogger("Falling back to standard location updates")
        locManager.stopMonitoringSignificantLocationChanges()
        locManager.startUpdatingLocation()
    }
    
    // Simplified background task management - use only the main locationBgTaskId
    private func cleanupBackgroundTask() {
        if locationBgTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(locationBgTaskId)
            locationBgTaskId = .invalid
            PreyLogger("Location background task ended")
        }
    }
    
    // Enable emergency mode for critical situations
    func enableEmergencyMode() {
        PreyLogger("🚨 Emergency mode enabled - switching to highest accuracy tracking")
        isEmergencyMode = true
        configureBatteryOptimizedSettings()
        
        // Restart location manager with emergency settings
        locManager.stopUpdatingLocation()
        locManager.startUpdatingLocation()
    }
    
    // Disable emergency mode
    func disableEmergencyMode() {
        PreyLogger("Emergency mode disabled - returning to battery-optimized settings")
        isEmergencyMode = false
        configureBatteryOptimizedSettings()
    }
    
    // Monitor authorization changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        PreyLogger("Location authorization changed to: \(status.rawValue)")
        
        switch status {
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        case .denied, .restricted:
            PreyLogger("⚠️ Location access denied - security app functionality compromised")
            // For security app, this is critical - might need to alert user
        case .authorizedWhenInUse:
            PreyLogger("Location authorized when in use - requesting 'always' for security app")
            manager.requestAlwaysAuthorization()
        case .authorizedAlways:
            PreyLogger("✅ Location authorization optimal - configuring for background operation")
            configureBatteryOptimizedSettings()
        @unknown default:
            PreyLogger("Unknown authorization status: \(status)")
        }
    }
}


// MARK: - LocationData Structure for Offline Queue

private struct LocationData {
    let id = UUID()
    let data: [String: Any]
    let endpoint: String
    let timestamp: Date
}
