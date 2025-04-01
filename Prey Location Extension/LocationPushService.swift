//
//  LocationPushService.swift
//  Prey Location Extension
//
//  Created by Pato Jofre on 25/03/2025.
//  Copyright © 2025 Prey, Inc. All rights reserved.
//

import CoreLocation
import Prey

class LocationPushService: NSObject, CLLocationPushServiceExtension, CLLocationManagerDelegate {

    var completion: (() -> Void)?
    var locationManager: CLLocationManager?

    func didReceiveLocationPushPayload(_ payload: [String : Any], completion: @escaping () -> Void) {
        self.completion = completion
        self.locationManager = CLLocationManager()
        self.locationManager!.delegate = self
        self.locationManager!.requestLocation()
    }
    
    func serviceExtensionWillTerminate() {
        // Called just before the extension will be terminated by the system.
        self.completion?()
    }

    // MARK: - CLLocationManagerDelegate methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Process the location(s) as appropriate
        guard let location = locations.last else {
                   return
               }

        // If sharing the locations to another user, end-to-end encrypt them to protect privacy
        
        print("location: \(String(describing: location))")
        
        // Send location to Prey server
               let params:[String: Any] = [
                   "lng": location.coordinate.longitude,
                   "lat": location.coordinate.latitude,
                   "alt": location.altitude,
                   "accuracy": location.horizontalAccuracy,
                   "method": "native"
               ]
               
               PreyHTTPClient.sharedInstance.sendLocation(params)
        
        // When finished, always call completion()
        self.completion?()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PreyLogger("Location Push Service Error: \(error.localizedDescription)")
        self.completion?()
    }

}
