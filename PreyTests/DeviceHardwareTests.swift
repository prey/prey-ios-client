//
//  DeviceHardwareTests.swift
//  PreyTests
//
//  Created by Prey on 13/02/26.
//  Copyright © 2026 Prey, Inc. All rights reserved.
//

import UIKit
import XCTest

@testable import Prey

class DeviceHardwareTests: XCTestCase {

    // MARK: - machineIdentifier

    func testMachineIdentifierNotEmpty() {
        let identifier = UIDevice.current.machineIdentifier
        XCTAssertFalse(identifier.isEmpty, "machineIdentifier should not be empty")
    }

    // MARK: - cpuCores (dynamic)

    func testCpuCoresIsDynamic() {
        let cores = UIDevice.current.cpuCores
        let coresInt = Int(cores) ?? 0
        XCTAssertGreaterThan(coresInt, 0, "cpuCores should return a value > 0 from ProcessInfo")
        XCTAssertEqual(coresInt, ProcessInfo.processInfo.processorCount, "cpuCores should match ProcessInfo.processorCount")
    }

    // MARK: - ramSize (dynamic)

    func testRamSizeIsDynamic() {
        let ram = UIDevice.current.ramSize
        let ramInt = UInt64(ram) ?? 0
        XCTAssertGreaterThan(ramInt, 0, "ramSize should return a value > 0 from ProcessInfo")
        let expectedMB = ProcessInfo.processInfo.physicalMemory / 1024 / 1024
        XCTAssertEqual(ramInt, expectedMB, "ramSize should match ProcessInfo.physicalMemory converted to MB")
    }

    // MARK: - PreyDevice includes machineIdentifier

    func testPreyDeviceIncludesMachineId() {
        let device = PreyDevice()
        XCTAssertNotNil(device.machineIdentifier, "PreyDevice should have a machineIdentifier")
        XCTAssertFalse(device.machineIdentifier!.isEmpty, "PreyDevice machineIdentifier should not be empty")
        XCTAssertEqual(device.machineIdentifier, UIDevice.current.machineIdentifier, "PreyDevice machineIdentifier should match UIDevice")
    }
}
