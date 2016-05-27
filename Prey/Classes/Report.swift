//
//  Report.swift
//  Prey
//
//  Created by Javier Cala Uribe on 18/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class Report: PreyAction, CLLocationManagerDelegate, LocationServiceDelegate, PhotoServiceDelegate {
 
    // MARK: Properties
    
    var interval:Double = 10
    
    var runReportTimer: NSTimer?
    
    var reportData = NSMutableDictionary()
    
    var reportLocation = ReportLocation()
    
    var reportPhoto = ReportPhoto()
    
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
            // Get Location
            reportLocation.delegate = self
            reportLocation.startLocation()
            
            // Get Photo
            reportPhoto.delegate = self
            reportPhoto.startSession()            
            
            // Get Wifi Info
            addWifiInfo()
            
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
        reportPhoto.stopSession()
    }
    
    // Send report
    func sendReport(param:NSMutableDictionary) {
        
        
        self.sendDataReport(param, toEndpoint: reportDataDeviceEndpoint)
    }
    
    // Add wifi info
    func addWifiInfo() {
        
        if let networkInfo = ReportWifi.getNetworkInfo() {
            
            let params:[String: AnyObject] = [
                "ssid"          : networkInfo["SSID"]!,
                "mac_address"   : networkInfo["BSSID"]!]
            
            // Save network info to reportData
            reportData.addEntriesFromDictionary(["active_access_point" : params])
        }
    }
    // MARK: ReportPhoto Delegate
    
    // Photos received
    func photoReceived(photos:[UIImage]) {
        
        print("photo image: \(photos)")
    }
    
    // MARK: ReportLocation Delegate
    
    // Location received
    func locationReceived(location:[CLLocation]) {
        
        if let loc = location.first {

            let params:[String : AnyObject] = [
                kLocation.LONGITURE.rawValue    : loc.coordinate.longitude,
                kLocation.LATITUDE.rawValue     : loc.coordinate.latitude,
                kLocation.ALTITUDE.rawValue     : loc.altitude,
                kLocation.ACCURACY.rawValue     : loc.horizontalAccuracy]
            
            // Save location to reportData
            reportData.addEntriesFromDictionary([kAction.LOCATION.rawValue : params])
            
            // Send report to panel
            sendReport(reportData)
            
            stop()
        }
    }
}