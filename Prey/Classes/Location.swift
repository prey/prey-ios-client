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
    
    let locManager   = CLLocationManager()
    
    var lastLocation : CLLocation!
    
    // MARK: Functions    
    
    // Return init if location action don't exist
    class func initLocationAction(withTarget target:kAction, withCommand cmd:kCommand, withOptions opt:NSDictionary?) -> Location? {

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
    func get() {
        
        if #available(iOS 8.0, *) {
            locManager.requestAlwaysAuthorization()
        }
        
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locManager.startUpdatingLocation()
        
        // Schedule get location
        Timer.scheduledTimer(timeInterval: 30.0, target:self, selector:#selector(stopLocationManager(_:)), userInfo:nil, repeats:false)
        
        isActive = true
        PreyLogger("Start location")
    }
    
    // Stop Location Manager
    func stopLocationManager(_ timer:Timer)  {
        PreyLogger("Stop location")

        timer.invalidate()
        locManager.stopUpdatingLocation()
        locManager.delegate = nil

        isActive = false
        PreyModule.sharedInstance.checkStatus(self)
    }
    
    // Location received
    func locationReceived(_ location:CLLocation) {
 
        let params:[String: Any] = [
            kLocation.lng.rawValue      : location.coordinate.longitude,
            kLocation.lat.rawValue      : location.coordinate.latitude,
            kLocation.alt.rawValue      : location.altitude,
            kLocation.accuracy.rawValue : location.horizontalAccuracy,
            kLocation.method.rawValue   : "native"]
        
        let locParam:[String: Any] = [kAction.location.rawValue : params]
        
        self.sendData(locParam, toEndpoint: dataDeviceEndpoint)
    }
    
    // MARK: CLLocationManagerDelegate
    
    // Did Update Locations
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        PreyLogger("New location received")
        
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
}
