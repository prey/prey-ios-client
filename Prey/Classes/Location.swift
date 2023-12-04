//
//  Location.swift
//  Prey
//
//  Created by Javier Cala Uribe on 5/05/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import CoreLocation


class Location : PreyAction, CLLocationManagerDelegate {
    
    // MARK: Properties
    
    let locManager = LocationHelper()
    
    
    // MARK: Functions
    
    // Return init if location action don't exist
    class func initLocationAction(withTarget target:kAction, withCommand cmd:kCommand, withOptions opt:NSDictionary?) -> Location? {

        // Check if command is start_location_aware
        if cmd == kCommand.start_location_aware {
            return Location(withTarget:target, withCommand:cmd, withOptions:opt)
        }
        
        // look for enqueued location command
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
    
    
    // Prey command
    override func get() {
        LocationHelper.startLocationManager(location: self)
        // Schedule get location
        Timer.scheduledTimer(timeInterval: 30.0, target:self, selector:#selector(stopLocationTimer(_:)), userInfo:nil, repeats:false)
        PreyLogger("Start location")
    }
    
    // Send lastLocation
    func sendLastLocation() {

        if LocationHelper.lastLocation != nil {
            // Send location to web panel
            LocationHelper.locationReceived(locationKlass: self, LocationHelper.lastLocation)
        }
    }
    
    // Stop Location Timer
    @objc func stopLocationTimer(_ timer:Timer)  {
        timer.invalidate()
        LocationHelper.stopLocationManager(location: <#T##Location#>)
    }
    
}
