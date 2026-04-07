//
//  PreyRestTests.swift
//  PreyTests
//
//  Created by Javier Cala Uribe on 5/8/14.
//  Copyright (c) 2014 Prey, Inc. All rights reserved.
//

@testable import Prey
import UIKit
import XCTest

class PreyRestTests: XCTestCase {
    // MARK: Properties

    let userEmail = "test7@prey.io"
    let userPassword = "password"

    /// Test log user
    func testRest01LogInUser() throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] == "true",
            "Skipping network-dependent test in CI."
        )

        let expectation = self.expectation(description: "Expecta Test: Log In")

        // LogIn to Panel Prey
        PreyUser.logInToPrey(userEmail, userPassword: userPassword, onCompletion: { (isSuccess: Bool) in
            // Check if login is success
            XCTAssertTrue(isSuccess)

            // Check if apiKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.userApiKey)

            expectation.fulfill()
        })

        waitForExpectations(timeout: 15, handler: nil)
    }

    /// Test get token from panel
    func testRest03GetToken() throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] == "true",
            "Skipping network-dependent test in CI."
        )

        let expectation = self.expectation(description: "Expecta Test: Get Token")

        // Get token from panel
        PreyUser.getTokenFromPanel(userEmail, userPassword: userPassword, onCompletion: { (isSuccess: Bool) in
            // Check if get token is success
            XCTAssertTrue(isSuccess)

            // Check if token is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.tokenPanel)

            expectation.fulfill()
        })

        waitForExpectations(timeout: 15, handler: nil)
    }

    /// Test add device
    func testRest04AddDevice() throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] == "true",
            "Skipping network-dependent test in CI."
        )

        let expectation = self.expectation(description: "Expecta Test: Add Device")

        // Add Device to Panel Prey
        PreyDevice.addDeviceWith { (isSuccess: Bool) in
            // Check if add device is success
            XCTAssertTrue(isSuccess)

            // Check if deviceKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.deviceKey)

            expectation.fulfill()
        }

        waitForExpectations(timeout: 15, handler: nil)
    }

    /// Test check status for device
    func testRest05CheckStatusForDevice() throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] == "true",
            "Skipping network-dependent test in CI."
        )

        let expectation = self.expectation(description: "Expecta Test: Check Status")

        let response: (Data?, URLResponse?, Error?) -> Void = { data, response, error in
            // Error is nil
            XCTAssertNil(error)

            let httpURLResponse = response as! HTTPURLResponse

            XCTAssertEqual(httpURLResponse.statusCode, 200)

            // Check if actionArray is nil
            let actionArray: String? = String(data: data!, encoding: String.Encoding.utf8)
            XCTAssertNotNil(actionArray)

            expectation.fulfill()
        }

        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.sendDataToPrey(username, password: "x", params: nil, messageId: nil, httpMethod: Method.GET.rawValue, endPoint: actionsDeviceEndpoint, onCompletion: response)
        } else {
            // Check if apiKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.userApiKey)
        }

        waitForExpectations(timeout: 15, handler: nil)
    }

    /// Test NotificationId
    func testRest06CheckNotificationId() throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] == "true",
            "Skipping network-dependent test in CI."
        )

        let expectation = self.expectation(description: "Expecta Test: Check NotificationId")

        let response: (Data?, URLResponse?, Error?) -> Void = { _, response, error in
            // Error is nil
            XCTAssertNil(error)

            let httpURLResponse = response as! HTTPURLResponse

            XCTAssertEqual(httpURLResponse.statusCode, 200)

            expectation.fulfill()
        }

        let params = ["notification_id": "t3stT0k3n"]

        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.sendDataToPrey(username, password: "x", params: params, messageId: nil, httpMethod: Method.POST.rawValue, endPoint: dataDeviceEndpoint, onCompletion: response)
        } else {
            // Check if apiKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.userApiKey)
        }

        waitForExpectations(timeout: 15, handler: nil)
    }

    /// Test Response Device
    func testRest10ResponseDevice() throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] == "true",
            "Skipping network-dependent test in CI."
        )

        let expectation = self.expectation(description: "Expecta Test: Response Device")

        let response: (Data?, URLResponse?, Error?) -> Void = { _, response, error in
            // Error is nil
            XCTAssertNil(error)

            let httpURLResponse = response as! HTTPURLResponse

            XCTAssertEqual(httpURLResponse.statusCode, 200)

            expectation.fulfill()
        }

        // Params struct
        let params: [String: Any] = [
            kData.status.rawValue: kStatus.started.rawValue,
            kData.target.rawValue: kAction.location.rawValue,
            kData.command.rawValue: kCommand.start.rawValue
        ]

        // Send info to panel
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.sendDataToPrey(username, password: "x", params: params, messageId: nil, httpMethod: Method.POST.rawValue, endPoint: responseDeviceEndpoint, onCompletion: response)
        } else {
            // Check if apiKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.userApiKey)
        }

        waitForExpectations(timeout: 15, handler: nil)
    }

    /// Test Delete Device
    func testRest12DeleteDevice() throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] == "true",
            "Skipping network-dependent test in CI."
        )

        let expectation = self.expectation(description: "Expecta Test: Delete Device")

        // Check if deviceKey is nil
        XCTAssertNotNil(PreyConfig.sharedInstance.deviceKey)

        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.sendDataToPrey(username, password: "x", params: nil, messageId: nil, httpMethod: Method.DELETE.rawValue, endPoint: deleteDeviceEndpoint, onCompletion: PreyHTTPResponse.checkResponse(RequestType.deleteDevice, preyAction: nil, onCompletion: { (isSuccess: Bool) in
                // Check if add device is success
                XCTAssertTrue(isSuccess)

                expectation.fulfill()
            }))
        } else {
            // Check if apiKey is nil
            XCTAssertNotNil(PreyConfig.sharedInstance.userApiKey)
        }

        waitForExpectations(timeout: 60, handler: nil)
    }
}
