//
//  ReportLocation.swift
//  Prey
//
//  Created by Javier Cala Uribe on 19/05/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationServiceDelegate {
    func locationReceived(_ location:[CLLocation])
}

class ReportLocation: NSObject, CLLocationManagerDelegate {

    // MARK: Properties

    var waitForRequest = false
    // If true, use a short high-accuracy burst (for missing reports)
    var highAccuracyBurst = false
    
    let locManager = CLLocationManager()

    var delegate: LocationServiceDelegate?
    
    // MARK: Functions
    
    // Start Location
    func startLocation() {
        locManager.delegate = self
        // Configure based on mode
        if highAccuracyBurst {
            locManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locManager.distanceFilter = kCLDistanceFilterNone
            locManager.pausesLocationUpdatesAutomatically = false
        } else {
            // One-shot, battery-friendly configuration
            locManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locManager.pausesLocationUpdatesAutomatically = true
        }
        
        if #available(iOS 9.0, *) {
            // Allow background one-shot updates when app is in background
            locManager.allowsBackgroundLocationUpdates = true
        }

        // Prefer a one-shot request; iOS will manage powering the GPS briefly
        if #available(iOS 9.0, *) {
            locManager.requestLocation()
        } else {
            // Fallback for very old iOS: start updates but we'll stop immediately after first fix
            locManager.startUpdatingLocation()
        }
    }
    
    // Stop Location
    func stopLocation() {
        locManager.stopUpdatingLocation()
        locManager.delegate = nil
    }
    
    // MARK: CLLocationManagerDelegate
    
    // Did Update Locations
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        PreyLogger("New location received on ReportLocation")
        
        if !waitForRequest {
            return
        }
        
        // Check if location is cached
        let locationTime = abs((locations.first?.timestamp.timeIntervalSinceNow)! as Double)
        if locationTime > 5 {
            return
        }
        
        guard let locate = locations.first else {
            return
        }
        
        if locate.horizontalAccuracy < 0 {
            return
        }
        
        let accuracyThreshold: CLLocationAccuracy = highAccuracyBurst ? 50 : 500
        if locate.horizontalAccuracy <= accuracyThreshold {
            self.delegate!.locationReceived(locations)
            // Stop updates immediately after delivering the fix
            stopLocation()
            waitForRequest = false
        }
    }
    
    // Did fail with error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PreyLogger("Error getting location: \(error.localizedDescription)")
        self.delegate!.locationReceived([CLLocation]())
        // Ensure manager is stopped on failure to save battery
        stopLocation()
        waitForRequest = false
    }
}
