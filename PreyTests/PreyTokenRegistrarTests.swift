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

    /// Regression: `clearCache()` must preserve the stored APNs token.
    /// Removing it stranded the re-attach flow when the user detached and
    /// re-logged in within the same app session — iOS does not re-deliver
    /// the token unless `registerForRemoteNotifications()` is called again,
    /// so `sendIfPossible` silently found nothing to send.
    func testNotificationTokenRegistrarClearCachePreservesTokenButClearsDedup() {
        let sharedSuite = UserDefaults(suiteName: NotificationTokenRegistrar.suiteName)!
        let originalToken = sharedSuite.string(forKey: NotificationTokenRegistrar.tokenKey)
        let originalLastValue = sharedSuite.string(forKey: NotificationTokenRegistrar.lastValueKey)
        let originalLastSent = sharedSuite.object(forKey: NotificationTokenRegistrar.lastSentKey) as? Date
        defer {
            if let t = originalToken { sharedSuite.set(t, forKey: NotificationTokenRegistrar.tokenKey) }
            else { sharedSuite.removeObject(forKey: NotificationTokenRegistrar.tokenKey) }
            if let v = originalLastValue { sharedSuite.set(v, forKey: NotificationTokenRegistrar.lastValueKey) }
            else { sharedSuite.removeObject(forKey: NotificationTokenRegistrar.lastValueKey) }
            if let s = originalLastSent { sharedSuite.set(s, forKey: NotificationTokenRegistrar.lastSentKey) }
            else { sharedSuite.removeObject(forKey: NotificationTokenRegistrar.lastSentKey) }
        }

        sharedSuite.set("tok", forKey: NotificationTokenRegistrar.tokenKey)
        sharedSuite.set("tok", forKey: NotificationTokenRegistrar.lastValueKey)
        sharedSuite.set(Date(), forKey: NotificationTokenRegistrar.lastSentKey)

        NotificationTokenRegistrar.clearCache()

        XCTAssertEqual(sharedSuite.string(forKey: NotificationTokenRegistrar.tokenKey), "tok",
                       "clearCache() must keep the APNs token so a re-attach can re-send it without waiting on iOS")
        XCTAssertNil(sharedSuite.string(forKey: NotificationTokenRegistrar.lastValueKey))
        XCTAssertNil(sharedSuite.object(forKey: NotificationTokenRegistrar.lastSentKey))
    }

    func testLocationPushRegistrarClearCachePreservesTokenButClearsDedup() {
        let sharedSuite = UserDefaults(suiteName: LocationPushRegistrar.suiteName)!
        let originalToken = sharedSuite.string(forKey: LocationPushRegistrar.tokenKey)
        let originalLastValue = sharedSuite.string(forKey: LocationPushRegistrar.lastValueKey)
        let originalLastSent = sharedSuite.object(forKey: LocationPushRegistrar.lastSentKey) as? Date
        defer {
            if let t = originalToken { sharedSuite.set(t, forKey: LocationPushRegistrar.tokenKey) }
            else { sharedSuite.removeObject(forKey: LocationPushRegistrar.tokenKey) }
            if let v = originalLastValue { sharedSuite.set(v, forKey: LocationPushRegistrar.lastValueKey) }
            else { sharedSuite.removeObject(forKey: LocationPushRegistrar.lastValueKey) }
            if let s = originalLastSent { sharedSuite.set(s, forKey: LocationPushRegistrar.lastSentKey) }
            else { sharedSuite.removeObject(forKey: LocationPushRegistrar.lastSentKey) }
        }

        sharedSuite.set("loc", forKey: LocationPushRegistrar.tokenKey)
        sharedSuite.set("loc", forKey: LocationPushRegistrar.lastValueKey)
        sharedSuite.set(Date(), forKey: LocationPushRegistrar.lastSentKey)

        LocationPushRegistrar.clearCache()

        XCTAssertEqual(sharedSuite.string(forKey: LocationPushRegistrar.tokenKey), "loc",
                       "clearCache() must keep the LocationPush token so a re-attach can re-send it")
        XCTAssertNil(sharedSuite.string(forKey: LocationPushRegistrar.lastValueKey))
        XCTAssertNil(sharedSuite.object(forKey: LocationPushRegistrar.lastSentKey))
    }

    // MARK: - PreyConfig.resetValues() clears the registrar cache

    func testResetValuesClearsDedupButPreservesTokensForReAttach() {
        let sharedSuite = UserDefaults(suiteName: NotificationTokenRegistrar.suiteName)!

        // Snapshot everything we're about to stomp on so the test is side-effect-free.
        let originalApnsToken = sharedSuite.string(forKey: NotificationTokenRegistrar.tokenKey)
        let originalApnsLastValue = sharedSuite.string(forKey: NotificationTokenRegistrar.lastValueKey)
        let originalApnsLastSent = sharedSuite.object(forKey: NotificationTokenRegistrar.lastSentKey) as? Date
        let originalLocToken = sharedSuite.string(forKey: LocationPushRegistrar.tokenKey)
        let originalLocLastValue = sharedSuite.string(forKey: LocationPushRegistrar.lastValueKey)
        let originalLocLastSent = sharedSuite.object(forKey: LocationPushRegistrar.lastSentKey) as? Date
        let originalApiKey = PreyConfig.sharedInstance.userApiKey
        let originalDeviceKey = PreyConfig.sharedInstance.deviceKey
        let originalIsRegistered = PreyConfig.sharedInstance.isRegistered
        defer {
            if let t = originalApnsToken { sharedSuite.set(t, forKey: NotificationTokenRegistrar.tokenKey) }
            else { sharedSuite.removeObject(forKey: NotificationTokenRegistrar.tokenKey) }
            if let v = originalApnsLastValue { sharedSuite.set(v, forKey: NotificationTokenRegistrar.lastValueKey) }
            else { sharedSuite.removeObject(forKey: NotificationTokenRegistrar.lastValueKey) }
            if let s = originalApnsLastSent { sharedSuite.set(s, forKey: NotificationTokenRegistrar.lastSentKey) }
            else { sharedSuite.removeObject(forKey: NotificationTokenRegistrar.lastSentKey) }
            if let t = originalLocToken { sharedSuite.set(t, forKey: LocationPushRegistrar.tokenKey) }
            else { sharedSuite.removeObject(forKey: LocationPushRegistrar.tokenKey) }
            if let v = originalLocLastValue { sharedSuite.set(v, forKey: LocationPushRegistrar.lastValueKey) }
            else { sharedSuite.removeObject(forKey: LocationPushRegistrar.lastValueKey) }
            if let s = originalLocLastSent { sharedSuite.set(s, forKey: LocationPushRegistrar.lastSentKey) }
            else { sharedSuite.removeObject(forKey: LocationPushRegistrar.lastSentKey) }
            PreyConfig.sharedInstance.userApiKey = originalApiKey
            PreyConfig.sharedInstance.deviceKey = originalDeviceKey
            PreyConfig.sharedInstance.isRegistered = originalIsRegistered
            PreyConfig.sharedInstance.saveValues()
        }

        // Prime both caches as if a previous attach had succeeded.
        sharedSuite.set("apns", forKey: NotificationTokenRegistrar.tokenKey)
        sharedSuite.set("apns", forKey: NotificationTokenRegistrar.lastValueKey)
        sharedSuite.set(Date(), forKey: NotificationTokenRegistrar.lastSentKey)
        sharedSuite.set("loc", forKey: LocationPushRegistrar.tokenKey)
        sharedSuite.set("loc", forKey: LocationPushRegistrar.lastValueKey)
        sharedSuite.set(Date(), forKey: LocationPushRegistrar.lastSentKey)

        PreyConfig.sharedInstance.resetValues()

        XCTAssertEqual(sharedSuite.string(forKey: NotificationTokenRegistrar.tokenKey), "apns",
                       "resetValues() must keep the APNs token so a re-attach can re-send it")
        XCTAssertNil(sharedSuite.string(forKey: NotificationTokenRegistrar.lastValueKey),
                     "resetValues() must drop the APNs dedup cache so a re-attach re-sends the token")
        XCTAssertNil(sharedSuite.object(forKey: NotificationTokenRegistrar.lastSentKey))
        XCTAssertEqual(sharedSuite.string(forKey: LocationPushRegistrar.tokenKey), "loc",
                       "resetValues() must keep the LocationPush token")
        XCTAssertNil(sharedSuite.string(forKey: LocationPushRegistrar.lastValueKey),
                     "resetValues() must drop the LocationPush dedup cache as well")
        XCTAssertNil(sharedSuite.object(forKey: LocationPushRegistrar.lastSentKey))
    }

    /// Regression for "hice login y no obtuve el token":
    ///
    /// 1. Device attached, APNs token T has been stored and deduped.
    /// 2. User detaches → PreyConfig.resetValues() runs.
    /// 3. User re-logs in (email/password) in the same app session — iOS
    ///    does NOT re-deliver the APNs token, so sendIfPossible relies on
    ///    whatever is in the app-group suite.
    ///
    /// Invariant: after step 2, both the APNs token and the LocationPush
    /// token must still be present, and the dedup cache must be empty so
    /// the next sendIfPossible actually hits the network.
    func testDetachPreservesTokensSoReAttachCanResend() {
        let sharedSuite = UserDefaults(suiteName: NotificationTokenRegistrar.suiteName)!

        let originalApnsToken = sharedSuite.string(forKey: NotificationTokenRegistrar.tokenKey)
        let originalApnsLastValue = sharedSuite.string(forKey: NotificationTokenRegistrar.lastValueKey)
        let originalApnsLastSent = sharedSuite.object(forKey: NotificationTokenRegistrar.lastSentKey) as? Date
        let originalLocToken = sharedSuite.string(forKey: LocationPushRegistrar.tokenKey)
        let originalLocLastValue = sharedSuite.string(forKey: LocationPushRegistrar.lastValueKey)
        let originalLocLastSent = sharedSuite.object(forKey: LocationPushRegistrar.lastSentKey) as? Date
        let originalApiKey = PreyConfig.sharedInstance.userApiKey
        let originalDeviceKey = PreyConfig.sharedInstance.deviceKey
        let originalIsRegistered = PreyConfig.sharedInstance.isRegistered
        defer {
            if let t = originalApnsToken { sharedSuite.set(t, forKey: NotificationTokenRegistrar.tokenKey) }
            else { sharedSuite.removeObject(forKey: NotificationTokenRegistrar.tokenKey) }
            if let v = originalApnsLastValue { sharedSuite.set(v, forKey: NotificationTokenRegistrar.lastValueKey) }
            else { sharedSuite.removeObject(forKey: NotificationTokenRegistrar.lastValueKey) }
            if let s = originalApnsLastSent { sharedSuite.set(s, forKey: NotificationTokenRegistrar.lastSentKey) }
            else { sharedSuite.removeObject(forKey: NotificationTokenRegistrar.lastSentKey) }
            if let t = originalLocToken { sharedSuite.set(t, forKey: LocationPushRegistrar.tokenKey) }
            else { sharedSuite.removeObject(forKey: LocationPushRegistrar.tokenKey) }
            if let v = originalLocLastValue { sharedSuite.set(v, forKey: LocationPushRegistrar.lastValueKey) }
            else { sharedSuite.removeObject(forKey: LocationPushRegistrar.lastValueKey) }
            if let s = originalLocLastSent { sharedSuite.set(s, forKey: LocationPushRegistrar.lastSentKey) }
            else { sharedSuite.removeObject(forKey: LocationPushRegistrar.lastSentKey) }
            PreyConfig.sharedInstance.userApiKey = originalApiKey
            PreyConfig.sharedInstance.deviceKey = originalDeviceKey
            PreyConfig.sharedInstance.isRegistered = originalIsRegistered
            PreyConfig.sharedInstance.saveValues()
        }

        // Step 1: simulate an attached device with primed dedup.
        let apnsToken = "deadbeefcafe"
        let locToken = "locpushtoken"
        sharedSuite.set(apnsToken, forKey: NotificationTokenRegistrar.tokenKey)
        sharedSuite.set(apnsToken, forKey: NotificationTokenRegistrar.lastValueKey)
        sharedSuite.set(Date().addingTimeInterval(-60), forKey: NotificationTokenRegistrar.lastSentKey)
        sharedSuite.set(locToken, forKey: LocationPushRegistrar.tokenKey)
        sharedSuite.set(locToken, forKey: LocationPushRegistrar.lastValueKey)
        sharedSuite.set(Date().addingTimeInterval(-60), forKey: LocationPushRegistrar.lastSentKey)

        // Step 2: detach.
        PreyConfig.sharedInstance.resetValues()

        // Token survives — this is the whole point of the fix.
        XCTAssertEqual(sharedSuite.string(forKey: NotificationTokenRegistrar.tokenKey), apnsToken,
                       "Detach must not lose the APNs token — iOS won't re-deliver it within the same session")
        XCTAssertEqual(sharedSuite.string(forKey: LocationPushRegistrar.tokenKey), locToken,
                       "Detach must not lose the LocationPush token either")

        // Dedup must be gone so the next sendIfPossible actually attempts the POST.
        XCTAssertTrue(TokenRegistrationValidator.shouldSendToken(
            tokenHex: apnsToken,
            suite: sharedSuite,
            lastValueKey: NotificationTokenRegistrar.lastValueKey,
            lastSentKey: NotificationTokenRegistrar.lastSentKey,
            logPrefix: "TEST"
        ), "After detach the dedup cache must not block the re-attach resend")
        XCTAssertTrue(TokenRegistrationValidator.shouldSendToken(
            tokenHex: locToken,
            suite: sharedSuite,
            lastValueKey: LocationPushRegistrar.lastValueKey,
            lastSentKey: LocationPushRegistrar.lastSentKey,
            logPrefix: "TEST"
        ), "Same expectation for the LocationPush dedup cache")
    }
}
