//
//  UIDeviceExt.swift
//  Prey
//
//  Created by Javier Cala Uribe on 2/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

// Extension for UIDevice
extension UIDevice {
    /*
    // Return Hardware Model
    var hwModel: String {
        return self.getSysInfoByName("hw.model")
    }
    */
    // Return CPU Model
    var cpuModel: String {
        
        var modelName: String
        var systemInfo      = utsname()
        uname(&systemInfo)
        let machineMirror   = Mirror(reflecting: systemInfo.machine)
        let identifier      = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
            
        case "iPhone3,1","iPhone3,2","iPhone3,3":
            modelName = "Apple A4"

        case "iPod5,1","iPad2,1","iPad2,2","iPad2,3","iPad2,4","iPad2,5","iPad2,6","iPad2,7","iPhone4,1":
            modelName = "Apple A5"

        case "iPad3,1","iPad3,2","iPad3,3":
            modelName = "Apple A5X"

        case "iPhone5,1","iPhone5,2","iPhone5,3","iPhone5,4":
            modelName = "Apple A6"
            
        case "iPad3,4","iPad3,5","iPad3,6":
            modelName = "Apple A6X"
            
        case "iPad4,1","iPad4,2","iPad4,3","iPad4,4","iPad4,5","iPad4,6","iPad4,7","iPad4,8","iPad4,9","iPhone6,1","iPhone6,2":
            modelName = "Apple A7"
            
        case "iPod7,1","iPad5,1","iPad5,2","iPhone7,2","iPhone7,1":
            modelName = "Apple A8"
            
        case "iPad5,3","iPad5,4":
            modelName = "Apple A8X"
            
        case "iPad6,11","iPad6,12","iPhone8,1","iPhone8,2","iPhone8,4":
            modelName = "Apple A9"
            
        case "iPad6,3","iPad6,4","iPad6,7","iPad6,8":
            modelName = "Apple A9X"
            
        case "iPhone9,1","iPhone9,3","iPhone9,2","iPhone9,4":
            modelName = "Apple A10"
            
        case "iPad7,1","iPad7,2","iPad7,3","iPad7,4":
            modelName = "Apple A10X"

        default:
            modelName = "Apple"
        }
        
        return modelName
    }
    /*
    // Return Cpu Speed
    var cpuSpeed: String {
        let results = self.getSysInfo(HW_CPU_FREQ)/1000000
        return String(results)
    }
    */
    // Return Cpu Speed
    var cpuSpeed: String {

        var cpuSpeedMhz: String
        
        switch cpuModel {
        case "Apple A4","Apple A5","Apple A5X":
            cpuSpeedMhz = "1000"
            
        case "Apple A6":
            cpuSpeedMhz = "1300"
            
        case "Apple A6X":
            cpuSpeedMhz = "1400"
            
        case "Apple A7":
            cpuSpeedMhz = "1300"
            
        case "Apple A8":
            cpuSpeedMhz = "1400"
            
        case "Apple A8X":
            cpuSpeedMhz = "1500"
            
        case "Apple A9":
            cpuSpeedMhz = "1850"
            
        case "Apple A9X":
            cpuSpeedMhz = "2200"
            
        case "Apple A10":
            cpuSpeedMhz = "2340"
            
        case "Apple A10X":
            cpuSpeedMhz = "2380"
            
        default:
            cpuSpeedMhz = "0"
        }
        
        return cpuSpeedMhz
    }
    /*
    // Return Cpu Cores
    var cpuCores: String {
        return String(self.getSysInfo(HW_NCPU))
    }
    */
    // Return Cpu Cores
    var cpuCores: String {
        
        var cores: String
        
        switch cpuModel {
        case "Apple A4":
            cores = "1"
            
        case "Apple A5","Apple A5X","Apple A6","Apple A6X","Apple A7","Apple A8","Apple A9","Apple A9X":
            cores = "2"
            
        case "Apple A8X":
            cores = "3"
            
        case "Apple A10":
            cores = "4"
            
        case "Apple A10X":
            cores = "6"
            
        default:
            cores = "0"
        }
        
        return cores
    }
    
    // Return device model
    var deviceModel: String {
        
        var modelName: String
        var systemInfo      = utsname()
        uname(&systemInfo)
        let machineMirror   = Mirror(reflecting: systemInfo.machine)
        let identifier      = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 modelName = "iPod Touch 5"
        case "iPod7,1":                                 modelName = "iPod Touch 6"
            
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     modelName = "iPhone 4"
        case "iPhone4,1":                               modelName = "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  modelName = "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  modelName = "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  modelName = "iPhone 5s"
        case "iPhone7,2":                               modelName = "iPhone 6"
        case "iPhone7,1":                               modelName = "iPhone 6 Plus"
        case "iPhone8,1":                               modelName = "iPhone 6s"
        case "iPhone8,2":                               modelName = "iPhone 6s Plus"
        case "iPhone8,4":                               modelName = "iPhone SE"
        case "iPhone9,1", "iPhone9,3":                  modelName = "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  modelName = "iPhone 7 Plus"
            
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":modelName = "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           modelName = "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           modelName = "iPad 4"
        case "iPad6,11","iPad6,12":                     modelName = "iPad 5"
        case "iPad4,1", "iPad4,2", "iPad4,3":           modelName = "iPad Air"
        case "iPad5,3", "iPad5,4":                      modelName = "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           modelName = "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           modelName = "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           modelName = "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      modelName = "iPad Mini 4"
        case "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8":modelName = "iPad Pro"
        case "iPad7,1", "iPad7,2", "iPad7,3", "iPad7,4":modelName = "iPad Pro 2"
        case "AppleTV5,3":                              modelName = "Apple TV"
        case "i386":                                    modelName = "iPhone Simulator"
        case "x86_64":                                  modelName = "iPad Simulator"
        default:                                        modelName = UIDevice.current.model
        }
        
        return modelName
    }
    
    /*
    // Return Ram Size
    var ramSize: String {
        let results = self.getSysInfo(HW_PHYSMEM)/1024/1024
        return String(results)
    }
    */
    
    // Return Ram Size
    var ramSize: String {
        
        var deviceRamSize: String
        var systemInfo      = utsname()
        uname(&systemInfo)
        let machineMirror   = Mirror(reflecting: systemInfo.machine)
        let identifier      = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        // MB: 512, 1024, 2048, 3072, 4096
        
        switch identifier {
            
        case "iPod5,1","iPad2,1","iPad2,2","iPad2,3","iPad2,4","iPad2,5","iPad2,6","iPad2,7","iPhone3,1","iPhone3,2","iPhone3,3","iPhone4,1":
            deviceRamSize = "512"

        case "iPod7,1","iPad3,1","iPad3,2","iPad3,3","iPad3,4","iPad3,5","iPad3,6","iPad4,1","iPad4,2","iPad4,3","iPad4,4","iPad4,5","iPad4,6",
             "iPad4,7","iPad4,8","iPad4,9","iPhone5,1","iPhone5,2","iPhone5,3","iPhone5,4","iPhone6,1","iPhone6,2","iPhone7,2","iPhone7,1":
            deviceRamSize = "1024"
        
        case "iPad5,3","iPad5,4","iPad5,1","iPad5,2","iPad6,3","iPad6,11","iPad6,12","iPad6,4","iPhone8,1","iPhone8,2","iPhone8,4","iPhone9,1",
             "iPhone9,3":
            deviceRamSize = "2048"
        
        case "iPhone9,2","iPhone9,4":
            deviceRamSize = "3072"
        
        case "iPad6,7","iPad6,8","iPad7,1","iPad7,2","iPad7,3","iPad7,4":
            deviceRamSize = "4096"
            
        default:
            deviceRamSize = "0"
        }
        
        return deviceRamSize
    }
    
    // MARK: sysctl utils
    
    func getSysInfo(_ typeSpecifier: Int32) -> Int {
        var size: size_t = MemoryLayout<Int>.size
        var results: Int = 0
        
        var mib: [Int32] = [CTL_HW, typeSpecifier]
        
        sysctl(&mib, 2, &results, &size, nil,0)
        
        return results
    }
    
    func getSysInfoByName(_ typeSpecifier: String) -> String {
        var size: size_t = 0
        
        sysctlbyname(typeSpecifier, nil, &size, nil, 0)
        
        var machine = [CChar](repeating: 0, count: Int(size))
        sysctlbyname(typeSpecifier, &machine, &size, nil, 0)
        
        return String(cString: machine)
    }
}
