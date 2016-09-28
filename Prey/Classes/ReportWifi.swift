//
//  ReportWifi.swift
//  Prey
//
//  Created by Javier Cala Uribe on 26/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import SystemConfiguration.CaptiveNetwork

class ReportWifi {
    
    // MARK: Functions
    
    // Get Network Info
    class func getNetworkInfo() -> NSDictionary? {
        
        var networkInfo = NSDictionary()

        if let interfaces:CFArray = CNCopySupportedInterfaces() {

            for i in 0..<CFArrayGetCount(interfaces) {
                
                let interfaceName: UnsafeRawPointer = CFArrayGetValueAtIndex(interfaces, i)
                let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
                let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString)
                if unsafeInterfaceData != nil {
                    networkInfo = unsafeInterfaceData! as NSDictionary!
                }
            }
        }
        
        return networkInfo
    }
}
