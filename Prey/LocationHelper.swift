//
//  LocationHelper.swift
//  Prey
//
//  Created by Pato Jofre on 04-12-23.
//  Copyright © 2023 Prey, Inc. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class LocationHelper: NSObject, CLLocationManagerDelegate {
    
    // MARK: Singleton
    static let shared = LocationHelper()
    private let locationManager = CLLocationManager()
    
    // Configuration
    private let minimumAccuracy: CLLocationAccuracy = 100 // meters
    private let minimumDistance: CLLocationDistance = 25  // meters
    private let staleLocationThreshold: TimeInterval = 30 // seconds
    
    // State
    private var isLocationAwareActive = false
    private var index = 0
    var lastLocation: CLLocation?
    private var locationUpdateHandler: ((CLLocation) -> Void)?
    
    // MARK: Functions
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = minimumDistance
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.activityType = .otherNavigation
    }
    
    func startLocationManager(location: Location, completion: ((CLLocation) -> Void)? = nil)  {
        locationUpdateHandler = completion
        locationManager.requestAlwaysAuthorization()
        
        // Reset state
        index = 0
        lastLocation = nil
        isLocationAwareActive = false
        
        // Start updates based on battery state
        if UIDevice.current.batteryState == .charging {
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.startUpdatingLocation()
        } else {
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }
    
    func stopLocationManager(location: Location)  {
        PreyLogger("Stop location")
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        locationUpdateHandler = nil
        PreyModule.sharedInstance.checkStatus(location)
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        PreyLogger("New location received")
        
        guard let currentLocation = locations.last else { return }
        
        // Validate location
        guard isValidLocation(currentLocation) else { return }
        
        // Process location update
        processLocationUpdate(currentLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PreyLogger("Location error: \(error.localizedDescription)")
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                // Handle permission denied
                PreyLogger("Location permission denied")
                stopLocationManager(location: Location(withTarget: .location, withCommand: .stop, withOptions: nil))
            case .locationUnknown:
                // Temporary error - keep trying
                PreyLogger("Location temporarily unavailable")
            default:
                PreyLogger("Location error: \(clError.localizedDescription)")
            }
        }
    }
    
    private func isValidLocation(_ location: CLLocation) -> Bool {
        // Check if location is stale
        let locationAge = abs(location.timestamp.timeIntervalSinceNow)
        guard locationAge <= staleLocationThreshold else { return false }
        
        // Validate accuracy
        guard location.horizontalAccuracy >= 0 &&
              location.horizontalAccuracy <= minimumAccuracy else { return false }
        
        // Validate coordinates
        guard location.coordinate.latitude != 0 &&
              location.coordinate.longitude != 0 else { return false }
        
        return true
    }
    
    private func processLocationUpdate(_ location: CLLocation) {
        // First location update
        guard let previousLocation = lastLocation else {
            lastLocation = location
            locationReceived(location)
            return
        }
        
        // Check if we've moved far enough
        let distance = location.distance(from: previousLocation)
        guard distance >= minimumDistance else { return }
        
        // Check if accuracy improved
        if location.horizontalAccuracy <= previousLocation.horizontalAccuracy {
            lastLocation = location
            locationReceived(location)
        }
    }
    
    
    // Location received
    func locationReceived(_ location: CLLocation) {
        guard let locationKlass = Location(withTarget: .location, withCommand: .get, withOptions: nil) else {
            PreyLogger("Failed to create Location instance")
            return
        }
        
        let params:[String: Any] = [
            kLocation.lng.rawValue      : location.coordinate.longitude,
            kLocation.lat.rawValue      : location.coordinate.latitude,
            kLocation.alt.rawValue      : location.altitude,
            kLocation.accuracy.rawValue : location.horizontalAccuracy,
            kLocation.method.rawValue   : "native"]
        
        let locParam:[String: Any] = [
            kAction.location.rawValue : params,
            kDataLocation.skip_toast.rawValue : (index > 0)
        ]
        
        if isLocationAwareActive {
            GeofencingManager.sharedInstance.startLocationAwareManager(locationKlass)
            isLocationAwareActive = false
            locationKlass.sendData(locParam, toEndpoint: locationAwareEndpoint)
            stopLocationManager(location: locationKlass)
        } else {
            locationKlass.sendData(locParam, toEndpoint: dataDeviceEndpoint)
            index = index + 1
        }
        
        // Send device name and info
        let paramName:[String: Any] = ["name" : UIDevice.current.name]
        locationKlass.sendData(paramName, toEndpoint: dataDeviceEndpoint)
        
        PreyDevice.infoDevice({ [weak self] (isSuccess: Bool) in
            PreyLogger("infoDevice isSuccess: \(isSuccess)")
        })
        
        // Notify completion handler if set
        locationUpdateHandler?(location)
    }
    
    
    // MARK: - App State Handling
    
    func handleEnterForeground() {
        PreyLogger("Entering foreground")
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }

    func handleEnterBackground() {
        PreyLogger("Entering background")
        optimizeForBackground()
    }

    func handleAppKilled() {
        PreyLogger("App terminated")
        optimizeForBackground()
    }
    
    private func optimizeForBackground() {
        locationManager.stopUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.startMonitoringSignificantLocationChanges()
    }
}
