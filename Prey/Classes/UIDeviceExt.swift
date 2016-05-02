//
//  UIDeviceExtension.swift
//  Prey
//
//  Created by Javier Cala Uribe on 2/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

// Extension for UIDevice
extension UIDevice {
    
    // Return Ram Size
    var ramSize: String {
        let results = self.getSysInfo(HW_PHYSMEM)/1024/1024
        return String(results)
    }
    
    // Return Hardware Model
    var hwModel: String {
        return self.getSysInfoByName("hw.model")
    }
    
    // Return Cpu Speed
    var cpuSpeed: String {
        let results = self.getSysInfo(HW_CPU_FREQ)/1000000
        return String(results)
    }

    // Return Cpu Cores
    var cpuCores: String {
        return String(self.getSysInfo(HW_NCPU))
    }
    
    // MARK: sysctl utils
    func getSysInfo(typeSpecifier: Int32) -> Int {
        var size: size_t = sizeof(Int)
        var results: Int = 0
        
        var mib: [Int32] = [CTL_HW, typeSpecifier]
        
        sysctl(&mib, 2, &results, &size, nil,0)
        
        return results
    }
    
    func getSysInfoByName(typeSpecifier: String) -> String {
        var size: size_t = 0
        
        sysctlbyname(typeSpecifier, nil, &size, nil, 0)
        
        var machine = [CChar](count: Int(size), repeatedValue: 0)
        sysctlbyname(typeSpecifier, &machine, &size, nil, 0)

        return String.fromCString(machine)!
    }
}
