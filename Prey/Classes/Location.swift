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

class Location : PreyAction, CLLocationManagerDelegate, LocationDelegate {
    
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
    
    // Background task manager for better task handling
    private var backgroundTasks: [String: UIBackgroundTaskIdentifier] = [:]
    
    // Location deduplication to prevent processing same location multiple times
    private static var lastProcessedLocation: CLLocation?
    private static var lastProcessedLocationTime: Date?
    private static let locationDeduplicationThreshold: TimeInterval = 5.0 // 5 seconds
    private static let locationDistanceThreshold: CLLocationDistance = 10.0 // 10 meters
    
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
        
        // Remove ourselves as delegate from DeviceAuth if we were using their location manager
        DeviceAuth.sharedInstance.removeLocationDelegate(self)
        
        // Check if location manager is actually running to avoid unnecessary stops
        guard isActive else {
            PreyLogger("Location manager already stopped, skipping")
            return
        }
        
        locManager.stopUpdatingLocation()
        
        // Only stop significant location changes if we're not in location aware mode
        if !isLocationAwareActive {
            locManager.stopMonitoringSignificantLocationChanges()
            PreyLogger("Stopped monitoring significant location changes")
        }
        
        // End background task if active
        if locationBgTaskId != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(locationBgTaskId)
            PreyLogger("Location background task ended with ID: \(locationBgTaskId.rawValue)")
            locationBgTaskId = UIBackgroundTaskIdentifier.invalid
        }
        
        // End all managed background tasks
        for (name, taskId) in backgroundTasks {
            if taskId != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(taskId)
                PreyLogger("Ended background task: \(name)")
            }
        }
        backgroundTasks.removeAll()
        
        // Set delegate to nil to prevent callbacks
        locManager.delegate = nil
        
        isActive = false
        PreyModule.sharedInstance.checkStatus(self)
    }
    
    // Location received
    func locationReceived(_ location:CLLocation) {
        PreyLogger("Processing location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // Check for duplicate location processing
        let now = Date()
        if let lastLocation = Location.lastProcessedLocation,
           let lastTime = Location.lastProcessedLocationTime {
            
            let timeDifference = now.timeIntervalSince(lastTime)
            let distance = location.distance(from: lastLocation)
            
            // Skip if same location processed recently
            if timeDifference < Location.locationDeduplicationThreshold && 
               distance < Location.locationDistanceThreshold {
                PreyLogger("Skipping duplicate location processing - distance: \(distance)m, time: \(timeDifference)s")
                return
            }
        }
        
        // Update last processed location tracking
        Location.lastProcessedLocation = location
        Location.lastProcessedLocationTime = now
        
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
        
        // Device info is now handled by scheduled sync tasks to avoid excessive calls
        // No need to call infoDevice on every location update
        
        // When all requests complete, end the background task
        dispatchGroup.notify(queue: .main) {
            // Give a little extra time for any pending network operations
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if bgTask != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(bgTask)
                    bgTask = UIBackgroundTaskIdentifier.invalid
                    PreyLogger("Location sending background task completed - all requests finished")
                }
                
                // Reset retry count on successful transmission
                self.retryCount = 0
                
                // Process any queued offline locations
                // self.processOfflineLocationQueue()
            }
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
            if self.offlineLocationQueue.count > 50 {
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
            for locationData in self.offlineLocationQueue {
                // Try to send each queued location
                DispatchQueue.main.async {
                    self.sendDataWithCallback(locationData.data, toEndpoint: locationData.endpoint) { success in
                        if success {
                            self.offlineQueue.async {
                                if let index = self.offlineLocationQueue.firstIndex(where: { $0.id == locationData.id }) {
                                    self.offlineLocationQueue.remove(at: index)
                                    PreyLogger("Successfully sent queued location data")
                                }
                            }
                        }
                    }
                }
                
                // Small delay between retries to avoid overwhelming the server
                Thread.sleep(forTimeInterval: 1.0)
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
    
    // Enhanced error handling with retry mechanisms
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PreyLogger("Location error: \(error.localizedDescription)")
        
        handleLocationError(error)
    }
    
    // MARK: Enhanced Methods for Security App
    
    // Configure battery-optimized location settings
    private func configureBatteryOptimizedSettings() {
        let batteryLevel = UIDevice.current.batteryLevel
        let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        PreyLogger("Configuring location for battery level: \(batteryLevel), low power mode: \(isLowPowerMode)")
        
        if isEmergencyMode {
            // Emergency mode: highest accuracy regardless of battery
            locManager.desiredAccuracy = kCLLocationAccuracyBest
            locManager.distanceFilter = 10
            locManager.pausesLocationUpdatesAutomatically = false
            PreyLogger("Emergency mode: using highest accuracy settings")
        } else if isLowPowerMode || batteryLevel < 0.2 {
            // Low power mode: reduce accuracy to preserve battery
            locManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locManager.distanceFilter = 500
            locManager.pausesLocationUpdatesAutomatically = true
            PreyLogger("Low power mode: using battery-saving settings")
        } else if batteryLevel < 0.5 {
            // Medium battery: balanced settings
            locManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locManager.distanceFilter = 200
            locManager.pausesLocationUpdatesAutomatically = true
            PreyLogger("Medium battery: using balanced settings")
        } else {
            // Normal battery: security-optimized settings
            locManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locManager.distanceFilter = 50
            locManager.pausesLocationUpdatesAutomatically = false
            PreyLogger("Normal battery: using security-optimized settings")
        }
        
        // Store original settings for restoration
        originalAccuracy = locManager.desiredAccuracy
        originalDistanceFilter = locManager.distanceFilter
    }
    
    // Enhanced location quality validation
    private func validateLocationQuality(_ location: CLLocation) -> Bool {
        // Check basic validity
        guard location.horizontalAccuracy > 0 && location.horizontalAccuracy < 200 else {
            PreyLogger("Location accuracy out of bounds: \(location.horizontalAccuracy)")
            return false
        }
        
        // Check for null island coordinates (0,0)
        guard location.coordinate.longitude != 0 || location.coordinate.latitude != 0 else {
            PreyLogger("Invalid null coordinates detected")
            return false
        }
        
        // Check location age with different thresholds based on app state
        let locationTime = abs(location.timestamp.timeIntervalSinceNow)
        
        // Fix: Get app state on main thread to avoid Main Thread Checker warning
        var isAppActive = false
        if Thread.isMainThread {
            isAppActive = UIApplication.shared.applicationState == .active
        } else {
            DispatchQueue.main.sync {
                isAppActive = UIApplication.shared.applicationState == .active
            }
        }
        
        let maxAge: TimeInterval = isEmergencyMode ? 10.0 : (isAppActive ? 5.0 : 30.0)
        
        guard locationTime < maxAge else {
            PreyLogger("Location too old: \(locationTime) seconds, max allowed: \(maxAge)")
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
        let maxReasonableSpeed: Double = 100 // 100 m/s = 360 km/h
        
        if speed > maxReasonableSpeed {
            PreyLogger("⚠️ SECURITY ALERT: Impossible speed detected: \(speed) m/s (\(speed * 3.6) km/h) - potential GPS spoofing")
            // For security app, we still want to log this but maybe with lower confidence
            return false
        }
        
        // Additional validation: check for teleportation (large distance, short time)
        if distance > 1000 && timeInterval < 60 {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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
        let retryDelay = min(pow(2.0, Double(retryCount)), 60.0) // Exponential backoff, max 60s
        
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
    
    // Enhanced background task management
    private func beginBackgroundTask(name: String, expirationHandler: @escaping () -> Void) {
        let taskId = UIApplication.shared.beginBackgroundTask(withName: name) {
            PreyLogger("Background task '\(name)' expired")
            self.endBackgroundTask(name: name)
            expirationHandler()
        }
        
        if taskId != .invalid {
            backgroundTasks[name] = taskId
            PreyLogger("Started background task '\(name)' with ID: \(taskId.rawValue)")
        }
    }
    
    private func endBackgroundTask(name: String) {
        guard let taskId = backgroundTasks[name], taskId != .invalid else { return }
        
        UIApplication.shared.endBackgroundTask(taskId)
        backgroundTasks[name] = nil
        PreyLogger("Ended background task '\(name)' with ID: \(taskId.rawValue)")
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
