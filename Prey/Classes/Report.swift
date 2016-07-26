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
    
    var runReportTimer: NSTimer?
    
    var interval:Double = 10
    
    var reportData      = NSMutableDictionary()
    
    var reportImages    = NSMutableDictionary()
    
    var reportLocation  = ReportLocation()
    
    var reportPhoto     = ReportPhoto()
    
    // MARK: Functions
    
    // Prey command
    func get() {
        
        // Set interval from jsonCommand
        interval = (self.options?.objectForKey("interval")?.doubleValue)!*60
        
        // Report Timer
        runReportTimer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(runReport(_:)), userInfo: nil, repeats: true)
        
        isActive = true
        PreyConfig.sharedInstance.isMissing = true
        PreyConfig.sharedInstance.saveValues()
        runReport(runReportTimer!)
    }
    
    // Run report
    func runReport(timer:NSTimer) {
        
        if PreyConfig.sharedInstance.isMissing {
            
            // Reset report info
            reportImages.removeAllObjects()
            reportData.removeAllObjects()
            
            // Stop location
            reportLocation.stopLocation()

            // Get Location
            reportLocation.waitForRequest = true
            reportLocation.delegate = self
            reportLocation.startLocation()
            
            // Get Photo
            if UIApplication.sharedApplication().applicationState != UIApplicationState.Background {
                reportPhoto.waitForRequest = true
                reportPhoto.delegate = self
                reportPhoto.startSession()                
            }
            
            // Get Wifi Info
            addWifiInfo()
            
        } else {
            stop()
        }
    }
    
    // Stop report
    override func stop() {
     
        runReportTimer?.invalidate()
        isActive = false
        PreyConfig.sharedInstance.isMissing = false
        PreyConfig.sharedInstance.saveValues()
        
        reportLocation.stopLocation()
        reportPhoto.stopSession()
        
        PreyModule.sharedInstance.checkStatus(self)
    }
    
    // Send report
    func sendReport() {
        
        if !reportPhoto.waitForRequest && !reportLocation.waitForRequest {
            self.sendDataReport(reportData, images: reportImages, toEndpoint: reportDataDeviceEndpoint)
        }
    }
    
    // Add wifi info
    func addWifiInfo() {
        
        if let networkInfo = ReportWifi.getNetworkInfo() {
            
            let params:[String: AnyObject] = [
                "active_access_point[ssid]"          : networkInfo["SSID"]!,
                "active_access_point[mac_address]"   : networkInfo["BSSID"]!]
            
            // Save network info to reportData
            reportData.addEntriesFromDictionary(params)
        }
    }
    
    
    // MARK: ReportPhoto Delegate
    
    // Photos received
    func photoReceived(photos:NSMutableDictionary) {
        
        PreyLogger("get photos")
        
        // Set photos to reportImages
        reportImages = photos
        
        // Set location wait
        reportPhoto.waitForRequest = false

        // Stop camera session
        reportPhoto.stopSession()
        reportPhoto.removeObserverForImage()
        
        // Send report to panel
        sendReport()
    }
    
    // MARK: ReportLocation Delegate
    
    // Location received
    func locationReceived(location:[CLLocation]) {
        
        if let loc = location.first {

            let params:[String : AnyObject] = [
                kReportLocation.LONGITURE.rawValue    : loc.coordinate.longitude,
                kReportLocation.LATITUDE.rawValue     : loc.coordinate.latitude,
                kReportLocation.ALTITUDE.rawValue     : loc.altitude,
                kReportLocation.ACCURACY.rawValue     : loc.horizontalAccuracy]
            
            // Save location to reportData
            reportData.addEntriesFromDictionary(params)
            
            // Set location wait
            reportLocation.waitForRequest = false
            
            // Send report to panel
            sendReport()
        }
    }
}