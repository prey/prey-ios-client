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

    let locManager = CLLocationManager()

    var delegate: LocationServiceDelegate?

    private var locationTimer: Timer?
    private let locationTimeout: TimeInterval = 30.0 // 30 seconds timeout

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

        // Start timeout timer to prevent infinite waiting
        locationTimer?.invalidate()
        locationTimer = Timer.scheduledTimer(withTimeInterval: locationTimeout, repeats: false) { [weak self] _ in
            guard let self = self, self.waitForRequest else { return }
            PreyLogger("ReportLocation: Timeout reached (\(self.locationTimeout)s), proceeding without location")
            self.delegate?.locationReceived([CLLocation]())
        }
    }

    // Stop Location
    func stopLocation() {
        locationTimer?.invalidate()
        locationTimer = nil
        locManager.stopUpdatingLocation()
        locManager.delegate = nil
    }
    
    // MARK: CLLocationManagerDelegate
    
    // Did Update Locations
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        PreyLogger("New location received on ReportLocation")

        guard waitForRequest else { return }

        // Ensure we have a recent, valid location fix
        guard let first = locations.first else { return }
        let locationTime = abs(first.timestamp.timeIntervalSinceNow)
        if locationTime > 5 { return }
        if first.horizontalAccuracy < 0 { return }

        if first.horizontalAccuracy <= 500 {
            // Cancel timeout timer since we got a valid location
            locationTimer?.invalidate()
            locationTimer = nil

            PreyLogger("ReportLocation: Got valid location with accuracy \(first.horizontalAccuracy)m")
            delegate?.locationReceived(locations)
        }
    }
    
    // Did fail with error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PreyLogger("Error getting location: \(error.localizedDescription)")

        // Cancel timeout timer since we're handling the error
        locationTimer?.invalidate()
        locationTimer = nil

        delegate?.locationReceived([CLLocation]())
    }
}
