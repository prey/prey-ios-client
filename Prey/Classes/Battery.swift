//
//  Battery.swift
//  Prey
//
//  Created by Javier Cala Uribe on 11/7/18.
//  Copyright © 2018 Fork Ltd. All rights reserved.
//

import UIKit

// Prey battery definitions
enum kBattery: String {
    case STATUS      = "battery_status"
    case STATE       = "state"
    case LEVEL       = "percentage_remaining"
    case LOW         = "low_battery"
}

class Battery: NSObject {
    
    // MARK: Properties
    
    static let sharedInstance = Battery()
    
    override fileprivate init() {
        
        // Init object
        super.init()
        
        // Enable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    // Send battery status to panel
    func sendStatusToPanel() {
        
        // Event low_battery send one per hour
        let defaults        = UserDefaults.standard
        let currentTime     = CFAbsoluteTimeGetCurrent()

        if defaults.object(forKey: kBattery.STATUS.rawValue) == nil {
            defaults.set(currentTime, forKey:kBattery.STATUS.rawValue)
        }
        
        let nextTime : CFAbsoluteTime = defaults.double(forKey: kBattery.STATUS.rawValue) + 60*60*1
        guard currentTime > nextTime  else {
            return
        }
        defaults.set(currentTime, forKey:kBattery.STATUS.rawValue)
        
        // Check level battery less than 20%
        guard UIDevice.current.batteryLevel < 0.2 else {
            return
        }
        
        let params:[String: Any] = [
            kGeofence.INFO.rawValue         : "",
            kGeofence.NAME.rawValue         : kBattery.LOW.rawValue]        
        
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:eventsDeviceEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.dataSend, preyAction:nil, onCompletion:{(isSuccess: Bool) in PreyLogger("Request dataSend battery")}))
        } else {
            PreyLogger("Error send data battery")
        }
    }
    
    // Return header X-Prey-Status
    func getHeaderPreyStatus() -> [String: Any] {
        let info:[String: Any] = [
            kBattery.STATE.rawValue : (UIDevice.current.batteryState == .unplugged ) ? "discharging" : "charging",
            kBattery.LEVEL.rawValue : (UIDevice.current.batteryLevel >= 0) ? String(describing: UIDevice.current.batteryLevel*100.0) : "0.0"]
        
        return [kBattery.STATUS.rawValue : info]
    }
}


