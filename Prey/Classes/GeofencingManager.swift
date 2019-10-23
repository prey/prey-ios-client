//
//  GeofencingManager.swift
//  Prey
//
//  Created by Javier Cala Uribe on 9/06/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import CoreLocation

// Prey geofencing definitions
enum kGeofence: String {
    case IN         = "geofencing_in"
    case OUT        = "geofencing_out"
    case INFO       = "info"
    case NAME       = "name"
    case ZONEID     = "id"
}


class GeofencingManager:NSObject, CLLocationManagerDelegate {
    
    // MARK: Properties
    
    static let sharedInstance = GeofencingManager()
    override fileprivate init() {
        
        // Init location manager
        geoManager = CLLocationManager()

        // Init object
        super.init()
        
        // Delegate location manager
        geoManager.delegate = self
    }

    var geoManager: CLLocationManager

    // Start location aware
    func startLocationAwareManager(_ location: CLLocation) {
        // Add geofence zone on current location
        if let zoneId = PreyConfig.sharedInstance.userApiKey {
            let region:CLCircularRegion = CLCircularRegion(center: location.coordinate, radius: 100.0, identifier: zoneId)
            geoManager.startMonitoring(for: region)
        }
    }
    
    // Stop location aware
    func stopLocationAwareManager() {
        for item in geoManager.monitoredRegions {
            if item.identifier == PreyConfig.sharedInstance.userApiKey {
                geoManager.stopMonitoring(for: item as CLRegion)
            }
        }
    }
    
    // Add regions to Device
    func addCurrentRegionToDevice(_ manager: CLLocationManager, _ region:CLCircularRegion) {
        // Check if CLRegion is available
        guard CLLocationManager.isMonitoringAvailable(for: CLRegion.self) else {
            PreyLogger("CLRegion is not available")
            return
        }
        // Check regionID
        guard region.identifier == PreyConfig.sharedInstance.userApiKey else {
            return
        }
        // Check location
        guard let location = manager.location else {
            return
        }
        
        if location.horizontalAccuracy < 0 {
            return
        }
        
        if location.coordinate.longitude == 0 || location.coordinate.latitude == 0 {
            return
        }

        // Send new location aware
        let params:[String: Any] = [
            kLocation.lng.rawValue      : location.coordinate.longitude,
            kLocation.lat.rawValue      : location.coordinate.latitude,
            kLocation.alt.rawValue      : location.altitude,
            kLocation.accuracy.rawValue : location.horizontalAccuracy,
            kLocation.method.rawValue   : "native"]
        
        let locParam:[String: Any] = [kAction.location.rawValue : params]
        sendNotifyToPanel(locParam, toEndpoint:locationAwareEndpoint)

        // Set new region monitoring
        let zoneId      = PreyConfig.sharedInstance.userApiKey!        
        let region:CLCircularRegion = CLCircularRegion(center: location.coordinate, radius: 100.0, identifier: zoneId)
        geoManager.startMonitoring(for: region)
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        PreyLogger("GeofencingManager: Did start monitoring for region")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PreyLogger("GeofencingManager Error: \(error)")
    }

    // Enter Region
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        PreyLogger("GeofencingManager: Did enter region")
    
        if let regionIn:CLCircularRegion = region as? CLCircularRegion {
            let params = getParamteresToSend(regionIn, withZoneInfo:kGeofence.IN.rawValue)
            sendNotifyToPanel(params, toEndpoint:eventsDeviceEndpoint)
        }
    }
    
    // Exit Region
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        PreyLogger("GeofencingManager: Did exit region")
        
        if let regionIn:CLCircularRegion = region as? CLCircularRegion {
            // identifier == userApiKey : LocationAwareActive
            if regionIn.identifier == PreyConfig.sharedInstance.userApiKey {
                addCurrentRegionToDevice(manager, regionIn)
            } else {
                let params = getParamteresToSend(regionIn, withZoneInfo:kGeofence.OUT.rawValue)
                sendNotifyToPanel(params, toEndpoint:eventsDeviceEndpoint)
            }
        }
    }
    
    // Params to send
    func getParamteresToSend(_ region:CLCircularRegion, withZoneInfo zoneInfo:String) -> [String: Any] {
        
        let regionInfo:[String: Any] = [
            kGeofence.ZONEID.rawValue       : region.identifier,
            kLocation.lat.rawValue          : region.center.latitude,
            kLocation.lng.rawValue          : region.center.longitude,
            kLocation.accuracy.rawValue     : region.radius,
            kLocation.method.rawValue       : "native"]

        let params:[String: Any] = [
            kGeofence.INFO.rawValue         : regionInfo,
            kGeofence.NAME.rawValue         : zoneInfo]
        
        return params
    }
    
    // Send to panel
    func sendNotifyToPanel(_ params:[String: Any], toEndpoint:String) {
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey, PreyConfig.sharedInstance.isRegistered {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:toEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.dataSend, preyAction:nil, onCompletion:{(isSuccess: Bool) in PreyLogger("Request dataSend")}))
        } else {
            PreyLogger("Error send data auth")
        }
    }
}
