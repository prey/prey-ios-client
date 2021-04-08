//
//  ReportLocation.swift
//  Prey
//
//  Created by Javier Cala Uribe on 19/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationServiceDelegate {
    func locationReceived(_ location:[CLLocation])
}

class ReportLocation: NSObject, CLLocationManagerDelegate {

    // MARK: Properties

    var waitForRequest = false
    
    let locManager = CLLocationManager()

    var delegate: LocationServiceDelegate?
    
    // MARK: Functions
    
    // Start Location
    func startLocation() {
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locManager.startUpdatingLocation()
        locManager.pausesLocationUpdatesAutomatically = false
        
        if #available(iOS 9.0, *) {
            locManager.allowsBackgroundLocationUpdates = true
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
        
        if locate.horizontalAccuracy <= 500 {
            self.delegate!.locationReceived(locations)
        }
    }
    
    // Did fail with error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PreyLogger("Error getting location: \(error.localizedDescription)")
        self.delegate!.locationReceived([CLLocation]())
    }
}
