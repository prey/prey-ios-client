//
//  PreyDeviceTests.swift
//  PreyTests
//
//  Created on 2026-03-24.
//  Copyright © 2026 Prey, Inc. All rights reserved.
//

import UIKit
import XCTest

@testable import Prey

class PreyDeviceTests: XCTestCase {

    var sut: PreyDevice!

    override func setUp() {
        super.setUp()
        sut = PreyDevice()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitSetsName() {
        XCTAssertNotNil(sut.name, "name should not be nil")
        XCTAssertEqual(sut.name, UIDevice.current.name)
    }

    func testInitSetsType() {
        XCTAssertNotNil(sut.type, "type should not be nil")
        let expectedType = IS_IPAD ? "Tablet" : "Phone"
        XCTAssertEqual(sut.type, expectedType)
    }

    func testTypeIsPhoneOrTablet() {
        XCTAssertTrue(sut.type == "Phone" || sut.type == "Tablet",
                       "type should be either 'Phone' or 'Tablet', got '\(sut.type!)'")
    }

    func testInitSetsOS() {
        XCTAssertEqual(sut.os, "iOS")
    }

    func testInitSetsVendor() {
        XCTAssertEqual(sut.vendor, "Apple")
    }

    func testInitSetsVersion() {
        XCTAssertNotNil(sut.version, "version should not be nil")
        XCTAssertEqual(sut.version, UIDevice.current.systemVersion)
    }

    func testInitSetsUUID() {
        XCTAssertNotNil(sut.uuid, "uuid should not be nil")
        XCTAssertEqual(sut.uuid, UIDevice.current.identifierForVendor?.uuidString)
    }

    func testInitSetsMacAddress() {
        XCTAssertEqual(sut.macAddress, "02:00:00:00:00:00",
                       "macAddress should be the iOS default")
    }

    func testInitSetsRamSize() {
        XCTAssertNotNil(sut.ramSize, "ramSize should not be nil")
        let ramInt = UInt64(sut.ramSize!) ?? 0
        XCTAssertGreaterThan(ramInt, 0, "ramSize should be > 0")
    }

    func testInitSetsCpuCores() {
        XCTAssertNotNil(sut.cpuCores, "cpuCores should not be nil")
        let cores = Int(sut.cpuCores!) ?? 0
        XCTAssertGreaterThan(cores, 0, "cpuCores should be > 0")
        XCTAssertEqual(cores, ProcessInfo.processInfo.processorCount)
    }

    func testInitSetsMachineIdentifier() {
        XCTAssertNotNil(sut.machineIdentifier, "machineIdentifier should not be nil")
        XCTAssertFalse(sut.machineIdentifier!.isEmpty, "machineIdentifier should not be empty")
        XCTAssertEqual(sut.machineIdentifier, UIDevice.current.machineIdentifier)
    }

    func testDeviceKeyIsNilByDefault() {
        XCTAssertNil(sut.deviceKey, "deviceKey should be nil after init")
    }

    // MARK: - Consistency Tests

    func testMultipleInstancesReturnConsistentValues() {
        let device2 = PreyDevice()
        XCTAssertEqual(sut.os, device2.os)
        XCTAssertEqual(sut.vendor, device2.vendor)
        XCTAssertEqual(sut.type, device2.type)
        XCTAssertEqual(sut.version, device2.version)
        XCTAssertEqual(sut.uuid, device2.uuid)
        XCTAssertEqual(sut.macAddress, device2.macAddress)
        XCTAssertEqual(sut.machineIdentifier, device2.machineIdentifier)
        XCTAssertEqual(sut.cpuCores, device2.cpuCores)
        XCTAssertEqual(sut.ramSize, device2.ramSize)
    }

    // MARK: - addDeviceWith Tests

    func testAddDeviceWithNoApiKeyCallsCompletionWithFalse() {
        // When there is no userApiKey, addDeviceWith should call completion with false
        let originalKey = PreyConfig.sharedInstance.userApiKey
        PreyConfig.sharedInstance.userApiKey = nil

        let expectation = self.expectation(description: "addDevice completion")
        PreyDevice.addDeviceWith { isSuccess in
            XCTAssertFalse(isSuccess, "Should fail when no API key is set")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3.0)

        // Restore
        PreyConfig.sharedInstance.userApiKey = originalKey
    }

    // MARK: - infoDevice Tests

    func testInfoDeviceWithNoApiKeyCallsCompletionWithFalse() {
        let originalKey = PreyConfig.sharedInstance.userApiKey
        PreyConfig.sharedInstance.userApiKey = nil

        let expectation = self.expectation(description: "infoDevice completion")
        PreyDevice.infoDevice { isSuccess in
            XCTAssertFalse(isSuccess, "Should fail when no API key is set")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3.0)

        PreyConfig.sharedInstance.userApiKey = originalKey
    }

    // MARK: - Dynamic hardware info

    func testInitSetsStorageCapacity() {
        XCTAssertNotNil(sut.storageCapacity, "storageCapacity should not be nil")
        let gb = Int(sut.storageCapacity!) ?? 0
        XCTAssertGreaterThan(gb, 0, "storageCapacity should be > 0")
    }

    func testInitSetsScreenSize() {
        XCTAssertNotNil(sut.screenSize, "screenSize should not be nil")
        XCTAssertTrue(sut.screenSize!.contains("x"), "screenSize should be in WxH format")
    }

    func testInitSetsScreenScale() {
        XCTAssertNotNil(sut.screenScale, "screenScale should not be nil")
        let scale = Double(sut.screenScale!) ?? 0
        XCTAssertGreaterThan(scale, 0, "screenScale should be > 0")
    }

    func testInitSetsThermalState() {
        XCTAssertNotNil(sut.thermalState, "thermalState should not be nil")
        let validStates = ["nominal", "fair", "serious", "critical", "unknown"]
        XCTAssertTrue(validStates.contains(sut.thermalState!),
                       "thermalState should be a valid state, got '\(sut.thermalState!)'")
    }

    func testInitSetsActiveProcessorCount() {
        XCTAssertNotNil(sut.activeProcessorCount, "activeProcessorCount should not be nil")
        let count = Int(sut.activeProcessorCount!) ?? 0
        XCTAssertGreaterThan(count, 0, "activeProcessorCount should be > 0")
    }
}
