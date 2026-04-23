//
//  SyncCoordinatorTests.swift
//  PreyTests
//
//  Copyright © 2026 Prey, Inc. All rights reserved.
//

@testable import Prey
import XCTest

/// Covers the post-auth/post-attach coordination, specifically the regression
/// where a fresh email/password attach never kicked off Location Push
/// monitoring (it was gated by `isRegistered` at launch, and nothing re-ran
/// it after `checkAddDevice`).
class SyncCoordinatorTests: XCTestCase {
    private var originalApiKey: String?
    private var originalDeviceKey: String?
    private var originalIsRegistered: Bool = false
    private var originalStartLocationPushMonitoring: (() -> Void)!

    override func setUp() {
        super.setUp()
        originalApiKey = PreyConfig.sharedInstance.userApiKey
        originalDeviceKey = PreyConfig.sharedInstance.deviceKey
        originalIsRegistered = PreyConfig.sharedInstance.isRegistered
        originalStartLocationPushMonitoring = SyncCoordinator.startLocationPushMonitoring
    }

    override func tearDown() {
        PreyConfig.sharedInstance.userApiKey = originalApiKey
        PreyConfig.sharedInstance.deviceKey = originalDeviceKey
        PreyConfig.sharedInstance.isRegistered = originalIsRegistered
        PreyConfig.sharedInstance.saveValues()
        SyncCoordinator.startLocationPushMonitoring = originalStartLocationPushMonitoring
        super.tearDown()
    }

    /// Regression: after `checkAddDevice` sets `isRegistered = true` and
    /// `deviceKey = ...`, the post-auth sync must kick off Location Push
    /// monitoring so the registration token can flow in and be POSTed.
    /// Before the fix, nothing re-ran `startMonitoringLocationPushes` after
    /// a fresh attach, leaving the token unsent until the next app launch.
    func testPostAuthSyncStartsLocationPushMonitoringWhenRegistered() {
        PreyConfig.sharedInstance.userApiKey = "test-api-key"
        PreyConfig.sharedInstance.deviceKey = "test-device-key"
        PreyConfig.sharedInstance.isRegistered = true
        PreyConfig.sharedInstance.saveValues()

        var invocations = 0
        SyncCoordinator.startLocationPushMonitoring = { invocations += 1 }

        SyncCoordinator.performPostAuthOrUpgradeSync(reason: .postLogin)

        XCTAssertEqual(invocations, 1,
                       "performPostAuthOrUpgradeSync must trigger LocationPush monitoring on every post-attach sync — otherwise the registration token is never requested")
    }

    func testPostAuthSyncTriggersMonitoringOnAppUpgradeReason() {
        PreyConfig.sharedInstance.userApiKey = "test-api-key"
        PreyConfig.sharedInstance.deviceKey = "test-device-key"
        PreyConfig.sharedInstance.isRegistered = true
        PreyConfig.sharedInstance.saveValues()

        var invocations = 0
        SyncCoordinator.startLocationPushMonitoring = { invocations += 1 }

        SyncCoordinator.performPostAuthOrUpgradeSync(reason: .appUpgrade)

        XCTAssertEqual(invocations, 1,
                       "App upgrade path must also ensure LocationPush monitoring is running — e.g. if an older build never requested it")
    }

    /// Guard invariant: if the user isn't registered yet (the first of two
    /// calls to performPostAuthOrUpgradeSync during email/password attach:
    /// once from checkLogIn, once from checkAddDevice), we must NOT kick
    /// off monitoring. The second call, after checkAddDevice, is the one
    /// that matters.
    func testPostAuthSyncDoesNotStartMonitoringWhenNotRegistered() {
        PreyConfig.sharedInstance.userApiKey = "test-api-key"
        PreyConfig.sharedInstance.deviceKey = nil
        PreyConfig.sharedInstance.isRegistered = false
        PreyConfig.sharedInstance.saveValues()

        var invocations = 0
        SyncCoordinator.startLocationPushMonitoring = { invocations += 1 }

        SyncCoordinator.performPostAuthOrUpgradeSync(reason: .postLogin)

        XCTAssertEqual(invocations, 0,
                       "Pre-addDevice sync must be a no-op — otherwise we'd start LocationPush monitoring without a deviceKey")
    }

    func testPostAuthSyncDoesNotStartMonitoringWhenNoApiKey() {
        PreyConfig.sharedInstance.userApiKey = nil
        PreyConfig.sharedInstance.deviceKey = "test-device-key"
        PreyConfig.sharedInstance.isRegistered = true
        PreyConfig.sharedInstance.saveValues()

        var invocations = 0
        SyncCoordinator.startLocationPushMonitoring = { invocations += 1 }

        SyncCoordinator.performPostAuthOrUpgradeSync(reason: .postLogin)

        XCTAssertEqual(invocations, 0,
                       "Without an API key there's no one to authenticate the LocationPush POST — the whole sync must bail")
    }
}
