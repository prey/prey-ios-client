//
//  PreyTokenRegistrarTests.swift
//  PreyTests
//
//  Copyright © 2026 Prey, Inc. All rights reserved.
//

@testable import Prey
import XCTest

/// Tests covering the push-token registration flow that started returning
/// `MissingDeviceToken` after 2.2.9:
///  - local 1-hour dedup cache in TokenRegistrationValidator
///  - Registrar persistence into the app-group UserDefaults
///  - PreyConfig.resetValues() clearing the cache on detach/re-attach
class PreyTokenRegistrarTests: XCTestCase {
    private let suiteName = "group.com.prey.ios.tests"
    private var suite: UserDefaults!

    private let lastValueKey = "APNSTokenLastValue"
    private let lastSentKey = "APNSTokenLastSent"

    override func setUp() {
        super.setUp()
        suite = UserDefaults(suiteName: suiteName)
        suite.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        suite.removePersistentDomain(forName: suiteName)
        suite = nil
        super.tearDown()
    }

    // MARK: - TokenRegistrationValidator.shouldSendToken

    func testShouldSendWhenNoPriorSendRecorded() {
        let shouldSend = TokenRegistrationValidator.shouldSendToken(
            tokenHex: "abc123",
            suite: suite,
            lastValueKey: lastValueKey,
            lastSentKey: lastSentKey,
            logPrefix: "TEST"
        )
        XCTAssertTrue(shouldSend, "First-ever send must not be blocked by the cache")
    }

    func testShouldNotSendWhenSameTokenWasSentWithinOneHour() {
        let token = "abc123"
        suite.set(token, forKey: lastValueKey)
        suite.set(Date().addingTimeInterval(-60), forKey: lastSentKey) // 1 min ago

        let shouldSend = TokenRegistrationValidator.shouldSendToken(
            tokenHex: token,
            suite: suite,
            lastValueKey: lastValueKey,
            lastSentKey: lastSentKey,
            logPrefix: "TEST"
        )
        XCTAssertFalse(shouldSend, "Same token within the 1-hour window must be deduped")
    }

    func testShouldSendWhenSameTokenButCacheIsStale() {
        let token = "abc123"
        suite.set(token, forKey: lastValueKey)
        suite.set(Date().addingTimeInterval(-3601), forKey: lastSentKey) // > 1h

        let shouldSend = TokenRegistrationValidator.shouldSendToken(
            tokenHex: token,
            suite: suite,
            lastValueKey: lastValueKey,
            lastSentKey: lastSentKey,
            logPrefix: "TEST"
        )
        XCTAssertTrue(shouldSend, "Cache older than 1 hour must not block a resend")
    }

    func testShouldSendWhenTokenChanged() {
        suite.set("oldtoken", forKey: lastValueKey)
        suite.set(Date(), forKey: lastSentKey)

        let shouldSend = TokenRegistrationValidator.shouldSendToken(
            tokenHex: "newtoken",
            suite: suite,
            lastValueKey: lastValueKey,
            lastSentKey: lastSentKey,
            logPrefix: "TEST"
        )
        XCTAssertTrue(shouldSend, "A different token must bypass the dedup window")
    }

    // MARK: - TokenRegistrationValidator.recordSuccessfulSend

    func testRecordSuccessfulSendPersistsTokenAndTimestamp() {
        let token = "newly-sent-token"
        TokenRegistrationValidator.recordSuccessfulSend(
            tokenHex: token,
            suite: suite,
            lastValueKey: lastValueKey,
            lastSentKey: lastSentKey
        )

        XCTAssertEqual(suite.string(forKey: lastValueKey), token)
        let stampedAt = suite.object(forKey: lastSentKey) as? Date
        XCTAssertNotNil(stampedAt)
        XCTAssertLessThan(abs(stampedAt!.timeIntervalSinceNow), 2.0)
    }

    func testShouldSendBecomesFalseAfterRecordingSameToken() {
        let token = "tok"
        TokenRegistrationValidator.recordSuccessfulSend(
            tokenHex: token,
            suite: suite,
            lastValueKey: lastValueKey,
            lastSentKey: lastSentKey
        )

        let shouldSend = TokenRegistrationValidator.shouldSendToken(
            tokenHex: token,
            suite: suite,
            lastValueKey: lastValueKey,
            lastSentKey: lastSentKey,
            logPrefix: "TEST"
        )
        XCTAssertFalse(shouldSend, "Recording a successful send must prime the dedup cache")
    }

    // MARK: - Registrar persistence (real app-group suite)

    func testNotificationTokenRegistrarStorePersistsToken() {
        let sharedSuite = UserDefaults(suiteName: NotificationTokenRegistrar.suiteName)!
        let originalToken = sharedSuite.string(forKey: NotificationTokenRegistrar.tokenKey)
        defer {
            if let originalToken = originalToken {
                sharedSuite.set(originalToken, forKey: NotificationTokenRegistrar.tokenKey)
            } else {
                sharedSuite.removeObject(forKey: NotificationTokenRegistrar.tokenKey)
            }
        }

        let token = "unit-test-apns-token"
        NotificationTokenRegistrar.store(tokenHex: token)

        XCTAssertEqual(
            sharedSuite.string(forKey: NotificationTokenRegistrar.tokenKey),
            token,
            "store(tokenHex:) must persist the token in the app-group suite"
        )
    }

    // MARK: - clearCache

    func testNotificationTokenRegistrarClearCacheRemovesAllKeys() {
        let sharedSuite = UserDefaults(suiteName: NotificationTokenRegistrar.suiteName)!
        sharedSuite.set("tok", forKey: NotificationTokenRegistrar.tokenKey)
        sharedSuite.set("tok", forKey: NotificationTokenRegistrar.lastValueKey)
        sharedSuite.set(Date(), forKey: NotificationTokenRegistrar.lastSentKey)

        NotificationTokenRegistrar.clearCache()

        XCTAssertNil(sharedSuite.string(forKey: NotificationTokenRegistrar.tokenKey))
        XCTAssertNil(sharedSuite.string(forKey: NotificationTokenRegistrar.lastValueKey))
        XCTAssertNil(sharedSuite.object(forKey: NotificationTokenRegistrar.lastSentKey))
    }

    func testLocationPushRegistrarClearCacheRemovesAllKeys() {
        let sharedSuite = UserDefaults(suiteName: LocationPushRegistrar.suiteName)!
        sharedSuite.set("loc", forKey: LocationPushRegistrar.tokenKey)
        sharedSuite.set("loc", forKey: LocationPushRegistrar.lastValueKey)
        sharedSuite.set(Date(), forKey: LocationPushRegistrar.lastSentKey)

        LocationPushRegistrar.clearCache()

        XCTAssertNil(sharedSuite.string(forKey: LocationPushRegistrar.tokenKey))
        XCTAssertNil(sharedSuite.string(forKey: LocationPushRegistrar.lastValueKey))
        XCTAssertNil(sharedSuite.object(forKey: LocationPushRegistrar.lastSentKey))
    }

    // MARK: - PreyConfig.resetValues() clears the registrar cache

    func testResetValuesClearsAPNsAndLocationPushCache() {
        let sharedSuite = UserDefaults(suiteName: NotificationTokenRegistrar.suiteName)!

        // Prime both caches as if a previous attach had succeeded.
        sharedSuite.set("apns", forKey: NotificationTokenRegistrar.tokenKey)
        sharedSuite.set("apns", forKey: NotificationTokenRegistrar.lastValueKey)
        sharedSuite.set(Date(), forKey: NotificationTokenRegistrar.lastSentKey)
        sharedSuite.set("loc", forKey: LocationPushRegistrar.tokenKey)
        sharedSuite.set("loc", forKey: LocationPushRegistrar.lastValueKey)
        sharedSuite.set(Date(), forKey: LocationPushRegistrar.lastSentKey)

        // Snapshot PreyConfig state so we can restore it after the destructive reset.
        let originalApiKey = PreyConfig.sharedInstance.userApiKey
        let originalDeviceKey = PreyConfig.sharedInstance.deviceKey
        let originalIsRegistered = PreyConfig.sharedInstance.isRegistered
        defer {
            PreyConfig.sharedInstance.userApiKey = originalApiKey
            PreyConfig.sharedInstance.deviceKey = originalDeviceKey
            PreyConfig.sharedInstance.isRegistered = originalIsRegistered
            PreyConfig.sharedInstance.saveValues()
        }

        PreyConfig.sharedInstance.resetValues()

        XCTAssertNil(sharedSuite.string(forKey: NotificationTokenRegistrar.lastValueKey),
                     "resetValues() must drop the APNs dedup cache so a re-attach re-sends the token")
        XCTAssertNil(sharedSuite.object(forKey: NotificationTokenRegistrar.lastSentKey))
        XCTAssertNil(sharedSuite.string(forKey: LocationPushRegistrar.lastValueKey),
                     "resetValues() must drop the LocationPush dedup cache as well")
        XCTAssertNil(sharedSuite.object(forKey: LocationPushRegistrar.lastSentKey))
    }
}
