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

        
        switch deviceModel.rawValue {
       
        case "iPhone 4":
            modelName = "Apple A4"
            
        case "iPhone 4S", "iPad 2", "iPad Mini", "iPod 5":
            modelName = "Apple A5"
            
        case "iPad 3":
            modelName = "Apple A5X"
            
        case "iPhone 5", "iPhone 5C":
            modelName = "Apple A6"
            
        case "iPad 4":
            modelName = "Apple A6X"
            
        case "iPad Air ", "iPad Mini 2", "iPad Mini 3", "iPhone 5S":
            modelName = "Apple A7"
            
        case "iPod 6", "iPad Mini 4", "iPhone 6 Plus", "iPhone 6":
            modelName = "Apple A8"
            
        case "iPad Air 2":
            modelName = "Apple A8X"
            
        case "iPad 5", "iPad 6", "iPhone 6S", "iPhone 6S Plus", "iPhone SE":
            modelName = "Apple A9"
            
        case "iPad Pro 9.7\"", "iPad Pro 12.9\"":
            modelName = "Apple A9X"
            
        case "iPod 7", "iPad 7", "iPhone 7", "iPhone 7 Plus":
            modelName = "Apple A10"
            
        case "iPad Pro 2 12.9\"", "iPad Pro 10.5\"":
            modelName = "Apple A10X"
            
        case "iPhone 8", "iPhone 8 Plus", "iPhone X":
            modelName = "Apple A11"
            
        case "iPad Mini 5", "iPad Air 3", "iPhone XR", "iPhone XS", "iPhone XS Max":
            modelName = "Apple A12"
            
        case "iPad Pro 11\"", "iPad Pro 3 12.9\"":
            modelName = "Apple A12X"
            
        case "iPad Pro 11\" 2nd gen", "iPad Pro 4 12.9\"":
            modelName = "Apple A12Z"
            
        case "iPhone 11", "iPhone 11 Pro", "iPhone 11 Pro Max", "iPhone SE 2nd gen":
            modelName = "Apple A13"
        
        case "iPhone 12", "iPhone 12 Mini", "iPhone 12 Pro", "iPhone 12 Pro Max":
            modelName = "Apple A14"
           
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

        case "Apple A11":
            cpuSpeedMhz = "2390"

        case "Apple A12":
            cpuSpeedMhz = "2490"

        case "Apple A12X","Apple A12Z":
            cpuSpeedMhz = "2490"

        case "Apple A13":
                cpuSpeedMhz = "2660"
           
        case "Apple A14":
                cpuSpeedMhz = "2750"

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
           
        case "Apple A10X","Apple A11","Apple A12","Apple A13", "Apple A14":
            cores = "6"

        case "Apple A12X","Apple A12Z":
            cores = "8"
           
        default:
            cores = "0"
        }
       
        return cores
    }
   
    var deviceModel: Model {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }

        let modelMap : [String: Model] = [

            //Simulator
            "i386"      : .simulator,
            "x86_64"    : .simulator,

            //iPod
            "iPod1,1"   : .iPod1,
            "iPod2,1"   : .iPod2,
            "iPod3,1"   : .iPod3,
            "iPod4,1"   : .iPod4,
            "iPod5,1"   : .iPod5,
            "iPod7,1"   : .iPod6,
            "iPod9,1"   : .iPod7,

            //iPad
            "iPad2,1"   : .iPad2,
            "iPad2,2"   : .iPad2,
            "iPad2,3"   : .iPad2,
            "iPad2,4"   : .iPad2,
            "iPad3,1"   : .iPad3,
            "iPad3,2"   : .iPad3,
            "iPad3,3"   : .iPad3,
            "iPad3,4"   : .iPad4,
            "iPad3,5"   : .iPad4,
            "iPad3,6"   : .iPad4,
            "iPad6,11"  : .iPad5, //iPad 2017
            "iPad6,12"  : .iPad5,
            "iPad7,5"   : .iPad6, //iPad 2018
            "iPad7,6"   : .iPad6,
            "iPad7,11"  : .iPad7, //iPad 2019
            "iPad7,12"  : .iPad7,
            "iPad11,6"  : .iPad8, //iPad 2020
            "iPad11,7"  : .iPad8,

            //iPad Mini
            "iPad2,5"   : .iPadMini,
            "iPad2,6"   : .iPadMini,
            "iPad2,7"   : .iPadMini,
            "iPad4,4"   : .iPadMini2,
            "iPad4,5"   : .iPadMini2,
            "iPad4,6"   : .iPadMini2,
            "iPad4,7"   : .iPadMini3,
            "iPad4,8"   : .iPadMini3,
            "iPad4,9"   : .iPadMini3,
            "iPad5,1"   : .iPadMini4,
            "iPad5,2"   : .iPadMini4,
            "iPad11,1"  : .iPadMini5,
            "iPad11,2"  : .iPadMini5,

            //iPad Pro
            "iPad6,3"   : .iPadPro9_7,
            "iPad6,4"   : .iPadPro9_7,
            "iPad7,3"   : .iPadPro10_5,
            "iPad7,4"   : .iPadPro10_5,
            "iPad6,7"   : .iPadPro12_9,
            "iPad6,8"   : .iPadPro12_9,
            "iPad7,1"   : .iPadPro2_12_9,
            "iPad7,2"   : .iPadPro2_12_9,
            "iPad8,1"   : .iPadPro11,
            "iPad8,2"   : .iPadPro11,
            "iPad8,3"   : .iPadPro11,
            "iPad8,4"   : .iPadPro11,
            "iPad8,9"   : .iPadPro2_11,
            "iPad8,10"  : .iPadPro2_11,
            "iPad8,5"   : .iPadPro3_12_9,
            "iPad8,6"   : .iPadPro3_12_9,
            "iPad8,7"   : .iPadPro3_12_9,
            "iPad8,8"   : .iPadPro3_12_9,
            "iPad8,11"  : .iPadPro4_12_9,
            "iPad8,12"  : .iPadPro4_12_9,

            //iPad Air
            "iPad4,1"   : .iPadAir,
            "iPad4,2"   : .iPadAir,
            "iPad4,3"   : .iPadAir,
            "iPad5,3"   : .iPadAir2,
            "iPad5,4"   : .iPadAir2,
            "iPad11,3"  : .iPadAir3,
            "iPad11,4"  : .iPadAir3,
            "iPad13,1"  : .iPadAir4,
            "iPad13,2"  : .iPadAir4,
           

            //iPhone
            "iPhone3,1" : .iPhone4,
            "iPhone3,2" : .iPhone4,
            "iPhone3,3" : .iPhone4,
            "iPhone4,1" : .iPhone4S,
            "iPhone5,1" : .iPhone5,
            "iPhone5,2" : .iPhone5,
            "iPhone5,3" : .iPhone5C,
            "iPhone5,4" : .iPhone5C,
            "iPhone6,1" : .iPhone5S,
            "iPhone6,2" : .iPhone5S,
            "iPhone7,1" : .iPhone6Plus,
            "iPhone7,2" : .iPhone6,
            "iPhone8,1" : .iPhone6S,
            "iPhone8,2" : .iPhone6SPlus,
            "iPhone8,4" : .iPhoneSE,
            "iPhone9,1" : .iPhone7,
            "iPhone9,3" : .iPhone7,
            "iPhone9,2" : .iPhone7Plus,
            "iPhone9,4" : .iPhone7Plus,
            "iPhone10,1" : .iPhone8,
            "iPhone10,4" : .iPhone8,
            "iPhone10,2" : .iPhone8Plus,
            "iPhone10,5" : .iPhone8Plus,
            "iPhone10,3" : .iPhoneX,
            "iPhone10,6" : .iPhoneX,
            "iPhone11,2" : .iPhoneXS,
            "iPhone11,4" : .iPhoneXSMax,
            "iPhone11,6" : .iPhoneXSMax,
            "iPhone11,8" : .iPhoneXR,
            "iPhone12,1" : .iPhone11,
            "iPhone12,3" : .iPhone11Pro,
            "iPhone12,5" : .iPhone11ProMax,
            "iPhone12,8" : .iPhoneSE2,
            "iPhone13,1" : .iPhone12Mini,
            "iPhone13,2" : .iPhone12,
            "iPhone13,3" : .iPhone12Pro,
            "iPhone13,4" : .iPhone12ProMax,
           
            // Apple Watch
            "Watch1,1" : .AppleWatch1,
            "Watch1,2" : .AppleWatch1,
            "Watch2,6" : .AppleWatchS1,
            "Watch2,7" : .AppleWatchS1,
            "Watch2,3" : .AppleWatchS2,
            "Watch2,4" : .AppleWatchS2,
            "Watch3,1" : .AppleWatchS3,
            "Watch3,2" : .AppleWatchS3,
            "Watch3,3" : .AppleWatchS3,
            "Watch3,4" : .AppleWatchS3,
            "Watch4,1" : .AppleWatchS4,
            "Watch4,2" : .AppleWatchS4,
            "Watch4,3" : .AppleWatchS4,
            "Watch4,4" : .AppleWatchS4,
            "Watch5,1" : .AppleWatchS5,
            "Watch5,2" : .AppleWatchS5,
            "Watch5,3" : .AppleWatchS5,
            "Watch5,4" : .AppleWatchS5,
            "Watch5,9" : .AppleWatchSE,
            "Watch5,10" : .AppleWatchSE,
            "Watch5,11" : .AppleWatchSE,
            "Watch5,12" : .AppleWatchSE,
            "Watch6,1" : .AppleWatchS6,
            "Watch6,2" : .AppleWatchS6,
            "Watch6,3" : .AppleWatchS6,
            "Watch6,4" : .AppleWatchS6,

            //Apple TV
            "AppleTV1,1" : .AppleTV1,
            "AppleTV2,1" : .AppleTV2,
            "AppleTV3,1" : .AppleTV3,
            "AppleTV3,2" : .AppleTV3,
            "AppleTV5,3" : .AppleTV4,
            "AppleTV6,2" : .AppleTV_4K
        ]

        if let model = modelMap[String.init(validatingUTF8: modelCode!)!] {
            if model == .simulator {
                if let simModelCode = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
                    if let simModel = modelMap[String.init(validatingUTF8: simModelCode)!] {
                        return simModel
                    }
                }
            }
            return model
        }
        return Model.unrecognized
      }
   
   
   
    public enum Model : String {

    //Simulator
    case simulator     = "simulator/sandbox",

    //iPod
    iPod1              = "iPod 1",
    iPod2              = "iPod 2",
    iPod3              = "iPod 3",
    iPod4              = "iPod 4",
    iPod5              = "iPod 5",
    iPod6              = "iPod 6",
    iPod7              = "iPod 7",

    //iPad
    iPad2              = "iPad 2",
    iPad3              = "iPad 3",
    iPad4              = "iPad 4",
    iPadAir            = "iPad Air ",
    iPadAir2           = "iPad Air 2",
    iPadAir3           = "iPad Air 3",
    iPadAir4           = "iPad Air 4",
    iPad5              = "iPad 5", //iPad 2017
    iPad6              = "iPad 6", //iPad 2018
    iPad7              = "iPad 7", //iPad 2019
    iPad8              = "iPad 8", //iPad 2020

    //iPad Mini
    iPadMini           = "iPad Mini",
    iPadMini2          = "iPad Mini 2",
    iPadMini3          = "iPad Mini 3",
    iPadMini4          = "iPad Mini 4",
    iPadMini5          = "iPad Mini 5",

    //iPad Pro
    iPadPro9_7         = "iPad Pro 9.7\"",
    iPadPro10_5        = "iPad Pro 10.5\"",
    iPadPro11          = "iPad Pro 11\"",
    iPadPro2_11        = "iPad Pro 11\" 2nd gen",
    iPadPro12_9        = "iPad Pro 12.9\"",
    iPadPro2_12_9      = "iPad Pro 2 12.9\"",
    iPadPro3_12_9      = "iPad Pro 3 12.9\"",
    iPadPro4_12_9      = "iPad Pro 4 12.9\"",

    //iPhone
    iPhone4            = "iPhone 4",
    iPhone4S           = "iPhone 4S",
    iPhone5            = "iPhone 5",
    iPhone5S           = "iPhone 5S",
    iPhone5C           = "iPhone 5C",
    iPhone6            = "iPhone 6",
    iPhone6Plus        = "iPhone 6 Plus",
    iPhone6S           = "iPhone 6S",
    iPhone6SPlus       = "iPhone 6S Plus",
    iPhoneSE           = "iPhone SE",
    iPhone7            = "iPhone 7",
    iPhone7Plus        = "iPhone 7 Plus",
    iPhone8            = "iPhone 8",
    iPhone8Plus        = "iPhone 8 Plus",
    iPhoneX            = "iPhone X",
    iPhoneXS           = "iPhone XS",
    iPhoneXSMax        = "iPhone XS Max",
    iPhoneXR           = "iPhone XR",
    iPhone11           = "iPhone 11",
    iPhone11Pro        = "iPhone 11 Pro",
    iPhone11ProMax     = "iPhone 11 Pro Max",
    iPhoneSE2          = "iPhone SE 2nd gen",
    iPhone12Mini       = "iPhone 12 Mini",
    iPhone12           = "iPhone 12",
    iPhone12Pro        = "iPhone 12 Pro",
    iPhone12ProMax     = "iPhone 12 Pro Max",

    // Apple Watch
    AppleWatch1         = "Apple Watch 1gen",
    AppleWatchS1        = "Apple Watch Series 1",
    AppleWatchS2        = "Apple Watch Series 2",
    AppleWatchS3        = "Apple Watch Series 3",
    AppleWatchS4        = "Apple Watch Series 4",
    AppleWatchS5        = "Apple Watch Series 5",
    AppleWatchSE        = "Apple Watch Special Edition",
    AppleWatchS6        = "Apple Watch Series 6",

    //Apple TV
    AppleTV1           = "Apple TV 1gen",
    AppleTV2           = "Apple TV 2gen",
    AppleTV3           = "Apple TV 3gen",
    AppleTV4           = "Apple TV 4gen",
    AppleTV_4K         = "Apple TV 4K",

    unrecognized       = "?unrecognized?"
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
        
        // MB: 512, 1024, 2048, 3072, 4096, 6144
       
        switch deviceModel.rawValue {
           
        case "iPod 5", "iPad 2", "iPad Mini", "iPhone 4", "iPhone 4S":
            deviceRamSize = "512"
            
        case "iPod 6", "iPad 3", "iPad Air ", "iPad Mini 2", "iPad Mini 3", "iPhone 5", "iPhone 5C", "iPhone 5S", "iPhone 6", "iPhone 6 Plus":
            deviceRamSize = "1024"
            
        case "iPod 7", "iPad Air 2", "iPad Mini 4", "iPad Pro 9.7\"", "iPad 5", "iPhone 6S", "iPhone 6S Plus", "iPhone SE", "iPhone 7", "iPhone 8", "iPad 6" :
            deviceRamSize = "2048"
            
        case "iPad 7", "iPad Mini 5", "iPad Air 3", "iPhone 7 Plus", "iPhone 8 Plus", "iPhone X", "iPhone XR", "iPhone SE 2nd gen":
            deviceRamSize = "3072"
            
        case "iPad Pro 12.9\"", "iPad Pro 2 12.9\"", "iPad Pro 10.5\"", "iPhone XS Max", "iPhone XS", "iPhone 11 Pro", "iPhone 11 Pro Max", "iPad Pro 11\"", "iPad Pro 3 12.9\"", "iPhone 12", "iPhone 12 Mini", "iPhone 11":
            deviceRamSize = "4096"
            
        case "iPhone 12 Pro", "iPhone 12 Pro Max", "iPad Pro 4 12.9\"":
            deviceRamSize = "6144"
                       
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
