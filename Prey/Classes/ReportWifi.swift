//
//  ReportWifi.swift
//  Prey
//
//  Created by Javier Cala Uribe on 26/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import SystemConfiguration.CaptiveNetwork
import NetworkExtension

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
                    networkInfo = unsafeInterfaceData! as NSDictionary
                }
            }
        }

        return networkInfo
    }
    
//    class func getNetworkInfo() -> NSDictionary? {
//
//        var networkInfo = NSDictionary()//[String: Any] = [:]
//
//        getNetworkInfoWifi { (wifiInfo) in
//
//            networkInfo = wifiInfo as NSDictionary
//
//        }
//
//        return networkInfo
//    }
    
    
//    class func getNetworkInfoWifi(compleationHandler: @escaping ([String: Any])->Void){
//
//       var currentWirelessInfo: [String: Any] = [:]
//
//        if #available(iOS 14.0, *) {
//
//            NEHotspotNetwork.fetchCurrent { network in
//
//                guard let network = network else {
//                    compleationHandler([:])
//                    return
//                }
//
//                let bssid = network.bssid
//                let ssid = network.ssid
//                currentWirelessInfo = ["BSSID ": bssid, "SSID": ssid, "SSIDDATA": "<54656e64 615f3443 38354430>"]
//                compleationHandler(currentWirelessInfo)
//            }
//        }
//        else {
//            #if !TARGET_IPHONE_SIMULATOR
//            guard let interfaceNames = CNCopySupportedInterfaces() as? [String] else {
//                compleationHandler([:])
//                return
//            }
//
//            guard let name = interfaceNames.first, let info = CNCopyCurrentNetworkInfo(name as CFString) as? [String: Any] else {
//                compleationHandler([:])
//                return
//            }
//
//            currentWirelessInfo = info
//
//            #else
//            currentWirelessInfo = ["BSSID ": "c8:3a:35:4c:85:d0", "SSID": "Tenda_4C85D0", "SSIDDATA": "<54656e64 615f3443 38354430>"]
//            #endif
//            compleationHandler(currentWirelessInfo)
//        }
//    }
    
}
