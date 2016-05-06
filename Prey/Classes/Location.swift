//
//  Location.swift
//  Prey
//
//  Created by Javier Cala Uribe on 5/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import CoreLocation

class Location: PreyAction, CLLocationManagerDelegate {
    
    // MARK: Properties
    
    static let sharedInstance = Location()
    private override init() {
    }

    // MARK: Functions
    
    func get() {
        
        // TEST
        if #available(iOS 8.0, *) {
            locManager.requestAlwaysAuthorization()
        }
        
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.startUpdatingLocation()
    }
    
    let locManager = CLLocationManager()
    
    // MARK: CLLocationManagerDelegate
    
    // Did Update Locations
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        print("New location received \(locations.description)")
    }

}