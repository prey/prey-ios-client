import Foundation
import CoreLocation
import UIKit

// Centralized location service owning a single CLLocationManager
// Delivers updates to registered LocationDelegate observers
class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()
    private override init() { super.init() }

    private let manager = CLLocationManager()
    private var delegates: [LocationDelegate] = []
    private(set) var lastLocation: CLLocation?

    // Optimized configuration for a security/tracking app
    private let optimalDistanceFilter: CLLocationDistance = 10.0 // More precise for security tracking

    private var isStarted = false
    func isRunning() -> Bool { isStarted }

    // Anti-inactivity watchdog (background only)
    private var watchdogTimer: DispatchSourceTimer?
    private var lastNudgeAt: Date?
    private var lastRestartAt: Date?
    private var restartWindowStart: Date?
    private var restartsInWindow: Int = 0
    private let inactivityThreshold: TimeInterval = 180 // 3 min without updates
    private let postNudgeWait: TimeInterval = 120       // wait 2 min after nudge before restarting
    private let restartCooldown: TimeInterval = 600     // 10 min between restarts
    private let restartWindow: TimeInterval = 3600      // 1 hour window
    private let maxRestartsPerHour: Int = 3

    // MARK: Public API
    func addDelegate(_ delegate: LocationDelegate) {
        if !delegates.contains(where: { $0 === delegate }) { delegates.append(delegate) }
    }

    func removeDelegate(_ delegate: LocationDelegate) {
        delegates.removeAll { $0 === delegate }
    }

    func getLastLocation() -> CLLocation? { lastLocation }

    func startBackgroundTracking() {
        configureIfNeeded()
        configureBatteryOptimizedSettings()
        manager.allowsBackgroundLocationUpdates = true
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            manager.startMonitoringSignificantLocationChanges()
        }
        // Add low-cost motion triggers to improve wake-ups for moderate moves (~100–300m)
        manager.startMonitoringVisits()
        manager.startUpdatingLocation()
        startWatchdogIfNeeded()
    }

    // Temporary high-accuracy foreground burst
    func startForegroundHighAccuracyBurst() {
        configureIfNeeded()
        configureBatteryOptimizedSettings()
        manager.allowsBackgroundLocationUpdates = true
        // Use single optimized configuration
        manager.startUpdatingLocation()
        // No watchdog needed in foreground; it will activate when returning to background
    }

    func requestOneShot(_ completion: @escaping (CLLocation?) -> Void) {
        configureIfNeeded()
        
        // Verify permissions before proceeding
        if !ensurePermissions() {
            completion(nil)
            return
        }
        
        // Use existing last if very recent
        if let last = lastLocation, abs(last.timestamp.timeIntervalSinceNow) < 10 {
            completion(last); return
        }
        // Use a one-shot requestLocation
        oneShotCompletion = completion
        manager.requestLocation()
    }

    // MARK: Internal
    private var oneShotCompletion: ((CLLocation?) -> Void)?

    private func configureIfNeeded() {
        guard !isStarted else { return }
        isStarted = true
        DispatchQueue.main.async {
            self.manager.requestAlwaysAuthorization()
        }
        manager.delegate = self
        // Optimized configuration for a security/tracking app
        manager.activityType = .other // More versatile than otherNavigation
        manager.pausesLocationUpdatesAutomatically = false // Never pause for security
        manager.desiredAccuracy = kCLLocationAccuracyBest // Maximum available accuracy
        manager.distanceFilter = optimalDistanceFilter // 10m to balance accuracy/battery
        
        // Ensure significant changes is always active as a fallback
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            manager.startMonitoringSignificantLocationChanges()
        }
    }

    // Removed adaptive parameters - using single optimized configuration

    private func configureBatteryOptimizedSettings() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        if batteryLevel < 0.10 || isLowPowerMode { // Only with critically low battery
            // For a security app, keep functionality even with low battery
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            manager.distanceFilter = 20 // Increase threshold to save battery
            PreyLogger("LocationService: Critical battery mode - reduced accuracy to preserve tracking", level: .info)
        } else {
            // Normal configuration with maximum accuracy
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = optimalDistanceFilter
        }
    }
    
    private func ensurePermissions() -> Bool {
        let status = manager.authorizationStatus
        if status != .authorizedAlways && status != .authorizedWhenInUse {
            PreyLogger("Location permission lost: \(status.rawValue)", level: .error)
            return false
        }
        return true
    }

    // MARK: Anti-inactivity Watchdog
    private func startWatchdogIfNeeded() {
        if watchdogTimer != nil { return }
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        timer.schedule(deadline: .now() + 60, repeating: 60, leeway: .seconds(10))
        timer.setEventHandler { [weak self] in
            self?.watchdogTick()
        }
        watchdogTimer = timer
        timer.resume()
    }

    private func watchdogTick() {
        // Background only
        var isBG = false
        DispatchQueue.main.sync { isBG = UIApplication.shared.applicationState == .background }
        if !isBG { return }

        // Battery/power-saving conditions
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        if batteryLevel >= 0 && batteryLevel < 0.20 { return }
        if lowPower { return }

        // If there was a recent update, nothing to do
        let now = Date()
        if let last = lastLocation, now.timeIntervalSince(last.timestamp) < inactivityThreshold { return }

        // Attempt 1: nudge with requestLocation if not done recently
        if let nudgeAt = lastNudgeAt {
            // Wait the post-nudge window before restarting if still no data
            if now.timeIntervalSince(nudgeAt) < postNudgeWait { return }
        } else {
            // Send nudge
            DispatchQueue.main.async { [weak self] in
                self?.manager.requestLocation()
            }
            lastNudgeAt = now
            PreyLogger("LocationService: Watchdog nudge (requestLocation)", level: .info)
            return
        }

        // Attempt 2: controlled manager restart with cooldown and per-hour limit
        if let lastR = lastRestartAt, now.timeIntervalSince(lastR) < restartCooldown { return }
        if let windowStart = restartWindowStart {
            if now.timeIntervalSince(windowStart) >= restartWindow {
                restartWindowStart = now; restartsInWindow = 0
            }
        } else { restartWindowStart = now }
        guard restartsInWindow < maxRestartsPerHour else { return }

        restartsInWindow += 1
        lastRestartAt = now
        lastNudgeAt = nil // reset cycle
        PreyLogger("LocationService: Watchdog restart (\(restartsInWindow)/\(maxRestartsPerHour) in window)", level: .info)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.manager.stopUpdatingLocation()
            // brief pause and restart
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.configureBatteryOptimizedSettings()
                self.manager.startUpdatingLocation()
            }
        }
    }

    private func persistToAppGroup(_ location: CLLocation) {
        if let userDefaults = UserDefaults(suiteName: "group.com.prey.ios") {
            let dict: [String: Any] = [
                "lng": location.coordinate.longitude,
                "lat": location.coordinate.latitude,
                "alt": location.altitude,
                "accuracy": location.horizontalAccuracy,
                "method": "native",
                "timestamp": Date().timeIntervalSince1970
            ]
            userDefaults.set(dict, forKey: "lastLocation")
        }
    }

    // MARK: - Dynamic Geofence (backstop)
    private var monitoredRegion: CLCircularRegion?
    private let geofenceRadius: CLLocationDistance = 200 // meters
    private let geofenceRetargetDistance: CLLocationDistance = 150 // meters to retarget center

    private func updateDynamicGeofence(around location: CLLocation) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }

        let newCenter = location.coordinate
        if let region = monitoredRegion {
            let currentCenter = region.center
            let currentLoc = CLLocation(latitude: currentCenter.latitude, longitude: currentCenter.longitude)
            if location.distance(from: currentLoc) < geofenceRetargetDistance { return }
            // Retarget region when we have moved enough
            manager.stopMonitoring(for: region)
        }

        let identifier = "com.prey.dynamic.geofence"
        let region = CLCircularRegion(center: newCenter, radius: geofenceRadius, identifier: identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        manager.startMonitoring(for: region)
        monitoredRegion = region
        PreyLogger("LocationService: Updated dynamic geofence center=(\(newCenter.latitude), \(newCenter.longitude)) r=\(Int(geofenceRadius))m", level: .info)
        // Ask for current state to possibly trigger an immediate event
        manager.requestState(for: region)
    }

    // MARK: CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { oneShotCompletion?(nil); oneShotCompletion = nil; return }
        // Basic validation
        guard CLLocationCoordinate2DIsValid(loc.coordinate),
              !(loc.coordinate.latitude == 0 && loc.coordinate.longitude == 0) else { 
            PreyLogger("LocationService: Invalid coordinates received", level: .error)
            return 
        }
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        PreyLogger("LocationService: lat=\(loc.coordinate.latitude) lon=\(loc.coordinate.longitude) speed=\(loc.speed) acc=\(loc.horizontalAccuracy) battery=\(batteryLevel)", level: .info)
        
        lastLocation = loc
        persistToAppGroup(loc)
        // Maintain a rolling geofence to catch moderate moves even when suspended
        updateDynamicGeofence(around: loc)
        // Deliver to observers
        PreyDebugNotify("LocationService: delivering to \(delegates.count) delegate(s)")

        if delegates.isEmpty {
            PreyLogger("LocationService: no delegates registered to consume updates", level: .info)
        }
        
        for d in delegates { d.didReceiveLocationUpdate(loc) }
        // Broadcast to app-level observers (e.g., PreyModule)
        NotificationCenter.default.post(name: .preyLocationUpdated, object: nil, userInfo: [
            "lat": loc.coordinate.latitude,
            "lon": loc.coordinate.longitude,
            "acc": loc.horizontalAccuracy,
            "ts": loc.timestamp.timeIntervalSince1970
        ])
        // Fulfill one-shot if pending
        if let c = oneShotCompletion { oneShotCompletion = nil; c(loc) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let nsError = error as NSError
        // Handle transient "location unknown" quietly (expected while acquiring a fix)
        if nsError.domain == kCLErrorDomain as String && nsError.code == CLError.locationUnknown.rawValue {
            PreyLogger("LocationService: Location unknown (no fix yet); will keep trying", level: .debug)
            if let c = oneShotCompletion { oneShotCompletion = nil; c(nil) }
            return
        }
        // Permission problem - notify with empty location
        if nsError.domain == kCLErrorDomain as String && nsError.code == CLError.denied.rawValue {
            PreyLogger("LocationService: Permission denied, notifying delegates", level: .error)
            for d in delegates { d.didReceiveLocationUpdate(CLLocation()) }
            if let c = oneShotCompletion { oneShotCompletion = nil; c(nil) }
            return
        }
        // Other errors: log once and fulfill any pending one-shot
        PreyLogger("LocationService error: \(error.localizedDescription) domain=\(nsError.domain) code=\(nsError.code)", level: .error)
        if let c = oneShotCompletion { oneShotCompletion = nil; c(nil) }
    }

    // Visit monitoring callbacks (low-power motion signals)
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        PreyLogger("LocationService: didVisit at lat=\(visit.coordinate.latitude) lon=\(visit.coordinate.longitude)", level: .info)
        // Nudge a fresh fix so pipeline can process/send
        DispatchQueue.main.async { [weak self] in
            self?.manager.requestLocation()
        }
    }

    // Region monitoring callbacks
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard region.identifier == monitoredRegion?.identifier else { return }
        PreyLogger("LocationService: didEnterRegion (dynamic geofence)", level: .info)
        DispatchQueue.main.async { [weak self] in
            self?.manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard region.identifier == monitoredRegion?.identifier else { return }
        PreyLogger("LocationService: didExitRegion (dynamic geofence)", level: .info)
        DispatchQueue.main.async { [weak self] in
            self?.manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard region.identifier == monitoredRegion?.identifier else { return }
        PreyLogger("LocationService: region state=\(state.rawValue) for dynamic geofence", level: .debug)
    }
}
