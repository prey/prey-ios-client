//
//  UIDeviceExt.swift
//  Prey
//
//  Created by Javier Cala Uribe on 2/05/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import UIKit

/// Extension for UIDevice
extension UIDevice {
    /// Return raw machine identifier (e.g. "iPhone18,1")
    var machineIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let identifier = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String(cString: ptr)
            }
        }
        // On simulator, return the simulated model identifier
        if identifier == "i386" || identifier == "x86_64" || identifier == "arm64" {
            if let simId = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
                return simId
            }
        }
        return identifier
    }

    /// Return Cpu Cores (dynamic via ProcessInfo)
    var cpuCores: String {
        return String(ProcessInfo.processInfo.processorCount)
    }

    /// Return Ram Size in MB (dynamic via ProcessInfo)
    var ramSize: String {
        let ramMB = ProcessInfo.processInfo.physicalMemory / 1024 / 1024
        return String(ramMB)
    }
}
