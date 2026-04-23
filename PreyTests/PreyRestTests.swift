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

/// Integration tests against a live Prey backend. They POST/GET real HTTP
/// requests and mutate a real account, so they are skip-by-default to keep
/// the unit test run deterministic.
///
/// ## How to run
///
/// These tests are opt-in. Set the following environment variables in the
/// Xcode scheme (Product → Scheme → Edit Scheme… → Test → Arguments →
/// Environment Variables):
///
///     PREY_RUN_NETWORK_TESTS   = 1
///     PREY_TEST_USER_EMAIL     = <your test account email>
///     PREY_TEST_USER_PASSWORD  = <your test account password>
///
/// If `PREY_RUN_NETWORK_TESTS` is not set to "1" the tests are skipped.
/// If it IS set but the credential env vars are missing, tests fail fast
/// with a clear message instead of hitting the backend with bogus data.
///
/// ## Which account do I need?
///
/// - A regular Prey panel account (sign up at `panel.preyhq.com` for
///   staging, `panel.preyproject.com` for production). No special role
///   needed — the tests only touch this account's own devices.
/// - The account MUST allow adding a new device (not at the device limit).
/// - These tests **mutate** the account: they add an iOS device in
///   `testRest04AddDevice` and delete it in `testRest12DeleteDevice`. Do
///   not use a personal account you care about — create a disposable one.
///
/// ## Which backend is hit?
///
/// The backend URL is baked into `PreyProtocol.swift` by `#if DEBUG`:
///   - Debug build (default for `Cmd+U`) → `solid.preyhq.com` (staging).
///   - Release build                     → `solid.preyproject.com` (prod).
/// So by default your credentials must be for a **staging** panel account.
///
/// ## Execution order matters
///
/// The tests share state via `PreyConfig.sharedInstance`:
///   01 (LogIn)       → sets `userApiKey`
///   03 (GetToken)    → uses `userApiKey`, sets `tokenPanel`
///   04 (AddDevice)   → uses `userApiKey`, sets `deviceKey`
///   05/06/10         → use `userApiKey` + `deviceKey`
///   12 (DeleteDevice)→ tears down the device created by 04
///
/// Xcode runs tests alphabetically by method name, which is why they're
/// numbered. Running individual tests out of order will fail.
class PreyRestTests: XCTestCase {
    // MARK: Properties

    /// Credentials for the test account. Defaults point at a legacy staging
    /// account that is not guaranteed to work — the env-var path below is
    /// the supported one. Kept as a last-resort fallback so somebody who
    /// forgets the env vars still gets a network error rather than a crash.
    private static let defaultEmail = "test7@prey.io"
    private static let defaultPassword = "password"

    var userEmail: String {
        ProcessInfo.processInfo.environment["PREY_TEST_USER_EMAIL"] ?? Self.defaultEmail
    }

    var userPassword: String {
        ProcessInfo.processInfo.environment["PREY_TEST_USER_PASSWORD"] ?? Self.defaultPassword
    }

    /// Skips the test unless `PREY_RUN_NETWORK_TESTS=1`, and — if enabled —
    /// fails fast when credential env vars are missing instead of waiting
    /// 15 seconds for a login request that was never going to succeed.
    private func skipUnlessNetworkTestsEnabled(file: StaticString = #file, line: UInt = #line) throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["PREY_RUN_NETWORK_TESTS"] == "1",
            """
            Integration test — opt in with the following env vars on the scheme's Test action:
              PREY_RUN_NETWORK_TESTS  = 1
              PREY_TEST_USER_EMAIL    = <staging account email>
              PREY_TEST_USER_PASSWORD = <staging account password>
            See the file header for details.
            """
        )

        let email = ProcessInfo.processInfo.environment["PREY_TEST_USER_EMAIL"]
        let password = ProcessInfo.processInfo.environment["PREY_TEST_USER_PASSWORD"]
        if (email ?? "").isEmpty || (password ?? "").isEmpty {
            XCTFail(
                "PREY_RUN_NETWORK_TESTS is enabled but PREY_TEST_USER_EMAIL / PREY_TEST_USER_PASSWORD are not set. Add them to the scheme's Test action → Arguments → Environment Variables.",
                file: file, line: line
            )
            throw XCTSkip("Missing credentials for integration tests.")
        }
    }

    /// Test log user
    func testRest01LogInUser() throws {
        try skipUnlessNetworkTestsEnabled()

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
        try skipUnlessNetworkTestsEnabled()

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
        try skipUnlessNetworkTestsEnabled()

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
        try skipUnlessNetworkTestsEnabled()

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
        try skipUnlessNetworkTestsEnabled()

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
        try skipUnlessNetworkTestsEnabled()

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
        try skipUnlessNetworkTestsEnabled()

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
