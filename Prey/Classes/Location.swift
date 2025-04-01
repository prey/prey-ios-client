//
//  Location.swift
//  Prey
//
//  Created by Javier Cala Uribe on 5/05/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class Location : PreyAction, CLLocationManagerDelegate {
    
    // MARK: Properties
    
    let locManager   = CLLocationManager()
    
    var lastLocation : CLLocation!
    
    var isLocationAwareActive = false
    
    var index = 0
    
    // Location Push Token
    private var locationPushToken: Data?
    
    // Background task identifier
    private var locationBgTaskId: UIBackgroundTaskIdentifier = .invalid
    
    // MARK: Functions
    
    // Return init if location action don't exist
    class func initLocationAction(withTarget target:kAction, withCommand cmd:kCommand, withOptions opt:NSDictionary?) -> Location? {

        // Check if command is start_location_aware
        if cmd == kCommand.start_location_aware {
            return Location(withTarget:target, withCommand:cmd, withOptions:opt)
        }
        
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
    override func get() {
        startLocationManager()
        // Schedule get location
        
        Timer.scheduledTimer(timeInterval: 30.0, target:self, selector:#selector(stopLocationTimer(_:)), userInfo:nil, repeats:false)
        
        // Start monitoring location pushes
        startMonitoringLocationPushes()
        
        PreyLogger("Start location")
    }
    
    private func startMonitoringLocationPushes() {
        if #available(iOS 15.0, *) {
            locManager.startMonitoringLocationPushes { [weak self] (token, error) in
                if let error = error {
                    PreyLogger("Location Push Error: \(error.localizedDescription)")
                    return
                }
                
                PreyLogger("startMonitoringLocationPushes")
                
                if let token = token {
                    self?.locationPushToken = token
                    self?.sendLocationPushToken(token)
                }
            }
        }
    }
    
    private func sendLocationPushToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02x", $0) }.joined()
        
        let params: [String: Any] = [
            "location_push_token": tokenString
        ]
        
        PreyHTTPClient.sharedInstance.userRegisterToPrey(
            PreyConfig.sharedInstance.userApiKey ?? "",
            password: "x",
            params: params,
            messageId: nil,
            httpMethod: Method.POST.rawValue,
            endPoint: dataDeviceEndpoint,
            onCompletion: PreyHTTPResponse.checkResponse(RequestType.dataSend, preyAction: nil) { success in
                PreyLogger("Location Push Token Send: \(success)")
            })
    }
    
    // Start location aware
    @objc func start_location_aware() {
        startLocationManager()
        isLocationAwareActive = true
        PreyLogger("Start location aware")
    }
    
    // Stop Location Timer
    @objc func stopLocationTimer(_ timer:Timer)  {
        timer.invalidate()
        stopLocationManager()
    }
    
    // Start Location Manager
    func startLocationManager()  {
        locManager.requestAlwaysAuthorization()
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locManager.distanceFilter = kCLDistanceFilterNone
        locManager.pausesLocationUpdatesAutomatically = false
        locManager.allowsBackgroundLocationUpdates = true
        
        // Start significant location changes for background wake-ups
        locManager.startMonitoringSignificantLocationChanges()
        locManager.startUpdatingLocation()
        
        // Begin background task to ensure we have time to get location
        var bgTask = UIBackgroundTaskIdentifier.invalid
        bgTask = UIApplication.shared.beginBackgroundTask {
            if bgTask != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(bgTask)
                bgTask = UIBackgroundTaskIdentifier.invalid
                PreyLogger("Location background task ended due to expiration")
            }
        }
        
        // Store the background task ID as a property to end it properly later
        self.locationBgTaskId = bgTask
        PreyLogger("Location background task started with ID: \(bgTask.rawValue)")
        
        isActive = true
        index = 0
        
        PreyLogger("Location manager started with background updates enabled")
    }
    
    // Stop Location Manager
    func stopLocationManager()  {
        PreyLogger("Stop location")
        
        locManager.stopUpdatingLocation()
        locManager.stopMonitoringSignificantLocationChanges()
        locManager.delegate = nil
        
        // End background task if active
        if locationBgTaskId != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(locationBgTaskId)
            PreyLogger("Location background task ended with ID: \(locationBgTaskId.rawValue)")
            locationBgTaskId = UIBackgroundTaskIdentifier.invalid
        }
        
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
        
        let locParam:[String: Any] = [kAction.location.rawValue : params, kDataLocation.skip_toast.rawValue : (index > 0)]
        
        if self.isLocationAwareActive {
            GeofencingManager.sharedInstance.startLocationAwareManager(location)
            self.isLocationAwareActive = false
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
    
    // MARK: CLLocationManagerDelegate
    
    // Did Update Locations
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        PreyLogger("New location received on Location")
        
        guard let currentLocation = locations.last else {
            return
        }
        
        // Check if location is cached (more lenient in background)
        let locationTime = abs(currentLocation.timestamp.timeIntervalSinceNow as Double)
        let timeThreshold = UIApplication.shared.applicationState == .active ? 5.0 : 30.0
        
        guard locationTime < timeThreshold else {
            PreyLogger("Location too old: \(locationTime) seconds")
            return
        }
        
        if currentLocation.horizontalAccuracy < 0 {
            PreyLogger("Invalid accuracy")
            return
        }

        if currentLocation.coordinate.longitude == 0 || currentLocation.coordinate.latitude == 0 {
            PreyLogger("Invalid coordinates")
            return
        }
        
        // Send first location
        if lastLocation == nil {
            PreyLogger("Sending first location: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
            locationReceived(currentLocation)
            lastLocation = currentLocation
            return
        }
        
        // Compare accuracy or check if significant movement occurred
        let distance = currentLocation.distance(from: lastLocation)
        if currentLocation.horizontalAccuracy < lastLocation.horizontalAccuracy || distance > 100 {
            PreyLogger("Sending updated location: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude), distance: \(distance)m")
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
