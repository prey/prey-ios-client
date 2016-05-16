//
//  Location.swift
//  Prey
//
//  Created by Javier Cala Uribe on 5/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import CoreLocation

class Location : PreyAction, CLLocationManagerDelegate {
    
    // MARK: Properties
    
    static let sharedInstance = Location()
    private override init() {
    }    
    
    let locManager = CLLocationManager()
    
    // MARK: Functions    
    
    // Prey command
    func get() {
        
        if #available(iOS 8.0, *) {
            locManager.requestAlwaysAuthorization()
        }
        
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.startUpdatingLocation()
    }
    
    // Location received
    func locationReceived(location:[CLLocation]) {
 
        if let loc = location.first {
            
            let params:[String: AnyObject] = [
                "lng"    : loc.coordinate.longitude,
                "lat"    : loc.coordinate.latitude,
                "alt"    : loc.altitude,
                "acc"    : loc.horizontalAccuracy,
                "method" : "native"]
            
            let locParam:[String: AnyObject] = [kAction.LOCATION.rawValue : params]

            self.sendData(locParam, toEndpoint: dataDeviceEndpoint)
        }
    }
    
    // MARK: CLLocationManagerDelegate
    
    // Did Update Locations
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("New location received: \(locations.description)")
        
        if locations.first?.horizontalAccuracy < 0 {
            return
        }

        if locations.first?.horizontalAccuracy <= 500 {
            locationReceived(locations)
            locManager.stopUpdatingLocation()
            locManager.delegate = nil
        }
    }
    
    // Did fail with error
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error getting location: \(error.description)")
    }
}