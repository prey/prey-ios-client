//
//  Report.swift
//  Prey
//
//  Created by Javier Cala Uribe on 18/05/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class Report: PreyAction, CLLocationManagerDelegate, LocationServiceDelegate, PhotoServiceDelegate {
 
    // MARK: Properties
    
    var runReportTimer: Timer?
    
    var interval:Double = 10*60
    
    var excLocation = false

    var excPicture  = false
    
    var reportData      = NSMutableDictionary()
    
    var reportImages    = NSMutableDictionary()
    
    var reportLocation  = ReportLocation()
    
    var reportPhoto : ReportPhoto = {
        if #available(iOS 10.0, *) {
        return ReportPhotoiOS10()
        } else {
        return ReportPhotoiOS8()
        }
    }()
    
    // MARK: Functions
    
    // Prey command
    override func get() {
        
        // Set interval from jsonCommand
        if let reportInterval = options?.object(forKey: kOptions.interval.rawValue) {
            interval = (reportInterval as AnyObject).doubleValue * 60
        }

        // Set exclude option from jsonCommand
        if let excludeArray = options?.object(forKey: kOptions.exclude.rawValue) as? Array<String> {
            if excludeArray.contains(kExclude.location.rawValue) {
                excLocation = true
            }
            if excludeArray.contains(kExclude.picture.rawValue) {
                excPicture = true
            }
        }
        
        // Report Timer
        runReportTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(runReport(_:)), userInfo: nil, repeats: true)
        
        isActive = true
        PreyConfig.sharedInstance.reportOptions = options
        PreyConfig.sharedInstance.isMissing = true
        PreyConfig.sharedInstance.saveValues()
        runReport(runReportTimer!)
    }
    
    // Run report
    @objc func runReport(_ timer:Timer) {
        
        guard PreyConfig.sharedInstance.isMissing else {
            stopReport()
            return
        }
        
        // Reset report info
        reportImages.removeAllObjects()
        reportData.removeAllObjects()
        
        // Stop location
        reportLocation.stopLocation()
        
        // Get Location
        if !excLocation {
            reportLocation.waitForRequest = true
            reportLocation.delegate = self
            reportLocation.startLocation()
        }
        
        // Get Photo
        if !excPicture, UIApplication.shared.applicationState != .background {
            reportPhoto.waitForRequest = true
            reportPhoto.delegate = self
            reportPhoto.startSession()
        }
        
        // Get Wifi Info
        addWifiInfo()
        
        // Check exclude option
        if excPicture, excLocation {
            sendReport()
        }
    }
    
    // Stop action report
    override func stop() {
     
        for item in PreyModule.sharedInstance.actionArray {
            if ( item.target == kAction.report ) {
                (item as? Report)!.stopReport()
            }
        }
    }
    
    // Stop report
    func stopReport() {
        
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
            
            guard let ssidNetwork = networkInfo["SSID"] as? String else {
                PreyLogger("Error get wifi info: SSID")
                return
            }

            guard let bssidNetwork = networkInfo["BSSID"] as? String else {
                PreyLogger("Error get wifi info: BSSID")
                return
            }
            
            let params:[String: String] = [
                "active_access_point[ssid]"          : ssidNetwork,
                "active_access_point[mac_address]"   : bssidNetwork]
                
            // Save network info to reportData
            reportData.addEntries(from: params)
        }
    }
    
    
    // MARK: ReportPhoto Delegate
    
    // Photos received
    func photoReceived(_ photos:NSMutableDictionary) {
        
        PreyLogger("get photos")
        
        // Set photos to reportImages
        reportImages = photos
        
        // Set location wait
        reportPhoto.waitForRequest = false

        // Stop camera session
        reportPhoto.stopSession()
        reportPhoto.removeObserver()
        
        // Send report to panel
        sendReport()
    }
    
    // MARK: ReportLocation Delegate
    
    // Location received
    func locationReceived(_ location:[CLLocation]) {
        
        if let loc = location.first {

            let params:[String : Any] = [
                kReportLocation.LONGITURE.rawValue    : loc.coordinate.longitude,
                kReportLocation.LATITUDE.rawValue     : loc.coordinate.latitude,
                kReportLocation.ALTITUDE.rawValue     : loc.altitude,
                kReportLocation.METHOD.rawValue       : "native",
                kReportLocation.ACCURACY.rawValue     : loc.horizontalAccuracy]
            
            // Save location to reportData
            reportData.addEntries(from: params)
            
            // Set location wait
            reportLocation.waitForRequest = false
            
            // Send report to panel
            sendReport()
        }
    }
}
