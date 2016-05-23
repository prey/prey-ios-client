//
//  Report.swift
//  Prey
//
//  Created by Javier Cala Uribe on 18/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import CoreLocation

class Report: PreyAction, CLLocationManagerDelegate, LocationServiceDelegate {
 
    // MARK: Properties
    
    var interval:Double = 10
    
    var runReportTimer: NSTimer?
    
    var reportData:NSMutableDictionary?
    
    var reportLocation = ReportLocation()
    
    // MARK: Functions
    
    // Prey command
    func get() {
        
        // Set interval from jsonCommand
        interval = (self.options?.objectForKey("interval")?.doubleValue)!*60
        
        // Report Timer
        runReportTimer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(runReport(_:)), userInfo: nil, repeats: true)
        
        isActive = true
        PreyConfig.sharedInstance.isMissing = true
        runReport(runReportTimer!)
    }
    
    // Run report
    func runReport(timer:NSTimer) {
        
        if PreyConfig.sharedInstance.isMissing {
            reportLocation.delegate = self
            reportLocation.startLocation()
            //getPhoto()
        } else {
            stop()
        }
    }
    
    // Stop report
    func stop() {
     
        runReportTimer?.invalidate()
        isActive = false
        PreyConfig.sharedInstance.isMissing = false
        
        reportLocation.stopLocation()
    }
    
    // Send report
    func sendReport(param:NSMutableDictionary) {
        
        
        self.sendDataReport(param, toEndpoint: reportDataDeviceEndpoint)
    }
    
    // MARK: ReportLocation Delegate
    
    // Location received
    func locationReceived(location:[CLLocation]) {
        
        if let loc = location.first {
            
             let params:NSMutableDictionary = [
                "geo[lng]"    : loc.coordinate.longitude,
                "geo[lat]"    : loc.coordinate.latitude,
                "geo[alt]"    : loc.altitude,
                "geo[acc]"    : loc.horizontalAccuracy]
            
            //reportData.addEntriesFromDictionary(params)
            
            sendReport(params)
            
            stop()
        }
    }
}