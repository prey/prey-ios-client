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

    // Adaptive thresholds
    private let walkSpeedMax: Double = 2.0     // m/s (~7.2 km/h)
    private let runSpeedMax: Double = 5.0      // m/s (~18 km/h)
    private let driveSpeedMin: Double = 10.0   // m/s (~36 km/h)

    private let walkDistanceThreshold: CLLocationDistance = 5.0
    private let runDistanceThreshold: CLLocationDistance = 10.0
    private let driveDistanceThreshold: CLLocationDistance = 50.0

    private var isStarted = false
    func isRunning() -> Bool { isStarted }

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
        manager.allowsBackgroundLocationUpdates = true
        manager.startMonitoringSignificantLocationChanges()
        manager.startUpdatingLocation()
    }

    // Temporary high-accuracy foreground burst
    func startForegroundHighAccuracyBurst() {
        configureIfNeeded()
        manager.allowsBackgroundLocationUpdates = true
        // Boost settings immediately; adaptive will refine on updates
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.startUpdatingLocation()
    }

    func requestOneShot(_ completion: @escaping (CLLocation?) -> Void) {
        configureIfNeeded()
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
        manager.activityType = .other
        manager.pausesLocationUpdatesAutomatically = false
        // Default; adaptive will refine
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
    }

    private func updateAdaptiveParameters(for current: CLLocation) {
        let speed = inferredSpeed(from: current)
        let desiredAcc: CLLocationAccuracy
        let dist: CLLocationDistance
        if speed < walkSpeedMax {
            desiredAcc = kCLLocationAccuracyBest
            dist = walkDistanceThreshold
            manager.activityType = .fitness
        } else if speed < runSpeedMax {
            desiredAcc = kCLLocationAccuracyBest
            dist = runDistanceThreshold
            manager.activityType = .other
        } else {
            desiredAcc = kCLLocationAccuracyNearestTenMeters
            dist = driveDistanceThreshold
            manager.activityType = .automotiveNavigation
        }
        if manager.desiredAccuracy != desiredAcc { manager.desiredAccuracy = desiredAcc }
        if manager.distanceFilter != dist { manager.distanceFilter = dist }
        PreyLogger("LocationService adaptive: speed=\(String(format: "%.1f", speed)) m/s, acc=\(desiredAcc)m, filter=\(Int(dist))m", level: .info)
    }

    private func inferredSpeed(from current: CLLocation) -> Double {
        if current.speed >= 0 { return current.speed }
        guard let last = lastLocation else { return 0 }
        let dt = current.timestamp.timeIntervalSince(last.timestamp)
        guard dt > 0 else { return 0 }
        return current.distance(from: last) / dt
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

    // MARK: CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { oneShotCompletion?(nil); oneShotCompletion = nil; return }
        // Basic validation
        guard CLLocationCoordinate2DIsValid(loc.coordinate),
              !(loc.coordinate.latitude == 0 && loc.coordinate.longitude == 0) else { return }
        lastLocation = loc
        updateAdaptiveParameters(for: loc)
        persistToAppGroup(loc)
        // Deliver to observers
        for d in delegates { d.didReceiveLocationUpdate(loc) }
        // Fulfill one-shot if pending
        if let c = oneShotCompletion { oneShotCompletion = nil; c(loc) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PreyLogger("LocationService error: \(error.localizedDescription)", level: .error)
        if let c = oneShotCompletion { oneShotCompletion = nil; c(nil) }
    }
}
