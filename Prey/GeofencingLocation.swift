//
//  GeofencingLocation.swift
//  Prey
//
//  Created by Orlando Aliaga on 14/11/2022.
//  Copyright © 2022 Prey, Inc. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationGeoServiceDelegate {
    func locationReceived(_ location:[CLLocation],_ zones:[NSNumber])
}

class GeofencingLocation: NSObject, CLLocationManagerDelegate {

    // MARK: Properties

    var waitForRequest = false
    
    let locManager = CLLocationManager()

    var delegate: LocationGeoServiceDelegate?
    
    var zonesId = [NSNumber]()
    // MARK: Functions
    
    // Start Location
    func startLocation( zones:[NSNumber]) {
        zonesId=zones
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
        PreyLogger("New location received on GeofencingLocation")
        
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
            self.delegate!.locationReceived(locations, zonesId)
            stopLocation()
        }
    }
    
    // Did fail with error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PreyLogger("Error getting location: \(error.localizedDescription)")
    }
}
