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

class LocationHelper {
    
    
    // MARK: Singleton
    
    static let sharedInstance   = CLLocationManager()
    
    static var isLocationAwareActive = false
    
    static var index = 0
    
    static var lastLocation : CLLocation!
    
    // MARK: Functions
    
    // Start Location Manager
    static func startLocationManager(location: Location)  {
        sharedInstance.requestAlwaysAuthorization()
        sharedInstance.allowsBackgroundLocationUpdates = true
        sharedInstance.pausesLocationUpdatesAutomatically = false
        sharedInstance.activityType = .other
        sharedInstance.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        // sharedInstance.distanceFilter = 25
        sharedInstance.startUpdatingLocation()
        
        // TODO: verify isActive behavior
        // isActive = true
        index = 0
    }
    
    // Stop Location Manager
    static func stopLocationManager(location: Location)  {
        PreyLogger("Stop location")
        
        sharedInstance.stopUpdatingLocation()
        sharedInstance.delegate = nil
        
        // TODO: verify isActive behavior
        // isActive = false
        PreyModule.sharedInstance.checkStatus(location)
    }
    
    // MARK: CLLocationManagerDelegate
    
    // Did Update Locations
    static func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        PreyLogger("New location received on Location")
        
        guard let currentLocation = locations.first else {
            return
        }
        
        // Check if location is cached
        let locationTime = abs(currentLocation.timestamp.timeIntervalSinceNow as Double)
        guard locationTime < 5 else {
            return
        }
        
        if currentLocation.horizontalAccuracy < 0 {
            return
        }

        if currentLocation.coordinate.longitude == 0 || currentLocation.coordinate.latitude == 0 {
            return
        }
        
        // Send first location
        if lastLocation == nil {
            // Send location to web panel
            locationReceived(currentLocation)
            lastLocation = currentLocation
            return
        }
        
        // Compare accuracy
        if currentLocation.horizontalAccuracy < lastLocation.horizontalAccuracy {
            // Send location to web panel
            locationReceived(currentLocation)
        }

        // Save last location
        lastLocation = currentLocation
    }
    
    // Did fail with error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PreyLogger("Error getting location: \(error.localizedDescription)")
    }
    
    
    // Location received
    static func locationReceived(_ location:CLLocation) {
 
        let params:[String: Any] = [
            kLocation.lng.rawValue      : location.coordinate.longitude,
            kLocation.lat.rawValue      : location.coordinate.latitude,
            kLocation.alt.rawValue      : location.altitude,
            kLocation.accuracy.rawValue : location.horizontalAccuracy,
            kLocation.method.rawValue   : "native"]
        
        let locParam:[String: Any] = [kAction.location.rawValue : params, kDataLocation.skip_toast.rawValue : (index > 0)]
        
        if isLocationAwareActive {
            GeofencingManager.sharedInstance.startLocationAwareManager(location)
            isLocationAwareActive = false
            // self es un tipo PreyAction. TODO: pass PreyAction as argument
            self.sendData(locParam, toEndpoint: locationAwareEndpoint)
            stopLocationManager()
        } else {
            self.sendData(locParam, toEndpoint: dataDeviceEndpoint)
            index = index + 1
        }
        let paramName:[String: Any] = [ "name" : UIDevice.current.name]
        self.sendData(paramName, toEndpoint: dataDeviceEndpoint)
        PreyDevice.infoDevice({(isSuccess: Bool) in
            PreyLogger("infoDevice isSuccess: \(isSuccess)")
        })
    }
    
    
    static func handleEnterForeground() {
        sharedInstance.desiredAccuracy = kCLLocationAccuracyBest
        sharedInstance.startUpdatingLocation()
    }

    static func handleEnterBackground() {
        sharedInstance.stopUpdatingLocation()
        sharedInstance.startMonitoringSignificantLocationChanges()
    }

    static func handleAppKilled() {
        sharedInstance.stopUpdatingLocation()
        sharedInstance.startMonitoringSignificantLocationChanges()
    }
}
