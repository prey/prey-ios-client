//
//  PreyNotificationMDMTests.swift
//  PreyTests
//
//  Copyright © 2026 Prey, Inc. All rights reserved.
//

@testable import Prey
import XCTest

/// Tests covering the preymdm push payload validator. The enrollment flow
/// now runs silently (no user-facing notification / tap) so the validator
/// must reject malformed payloads rather than crashing or starting the
/// MobileConfig server with garbage input.
class PreyNotificationMDMTests: XCTestCase {
    // MARK: - Valid payloads

    func testValidPayloadReturnsParsedStruct() {
        let params: NSDictionary = [
            "token": "abc123",
            "account_id": 42,
            "url": "https://solid.preyproject.com/mdm/enroll"
        ]

        let payload = PreyNotification.parsePreyMDMPayload(params)

        XCTAssertEqual(
            payload,
            PreyNotification.PreyMDMPayload(
                token: "abc123",
                accountId: 42,
                url: "https://solid.preyproject.com/mdm/enroll"
            )
        )
    }

    func testExtraFieldsAreIgnored() {
        let params: NSDictionary = [
            "token": "abc123",
            "account_id": 42,
            "url": "https://example.com",
            "extra_key": "ignored",
            "another": 99
        ]

        let payload = PreyNotification.parsePreyMDMPayload(params)

        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?.token, "abc123")
    }

    // MARK: - Missing fields

    func testMissingTokenReturnsNil() {
        let params: NSDictionary = [
            "account_id": 42,
            "url": "https://example.com"
        ]
        XCTAssertNil(PreyNotification.parsePreyMDMPayload(params))
    }

    func testMissingAccountIdReturnsNil() {
        let params: NSDictionary = [
            "token": "abc",
            "url": "https://example.com"
        ]
        XCTAssertNil(PreyNotification.parsePreyMDMPayload(params))
    }

    func testMissingURLReturnsNil() {
        let params: NSDictionary = [
            "token": "abc",
            "account_id": 42
        ]
        XCTAssertNil(PreyNotification.parsePreyMDMPayload(params))
    }

    // MARK: - Wrong types

    func testTokenWrongTypeReturnsNil() {
        let params: NSDictionary = [
            "token": 123, // should be String
            "account_id": 42,
            "url": "https://example.com"
        ]
        XCTAssertNil(PreyNotification.parsePreyMDMPayload(params))
    }

    func testAccountIdWrongTypeReturnsNil() {
        let params: NSDictionary = [
            "token": "abc",
            "account_id": "42", // should be Int, not String
            "url": "https://example.com"
        ]
        XCTAssertNil(PreyNotification.parsePreyMDMPayload(params))
    }

    func testURLWrongTypeReturnsNil() {
        let params: NSDictionary = [
            "token": "abc",
            "account_id": 42,
            "url": 999 // should be String
        ]
        XCTAssertNil(PreyNotification.parsePreyMDMPayload(params))
    }

    // MARK: - Empty strings

    func testEmptyTokenReturnsNil() {
        let params: NSDictionary = [
            "token": "",
            "account_id": 42,
            "url": "https://example.com"
        ]
        XCTAssertNil(PreyNotification.parsePreyMDMPayload(params),
                     "Empty token must be rejected to avoid starting the enrollment server with no auth")
    }

    func testEmptyURLReturnsNil() {
        let params: NSDictionary = [
            "token": "abc",
            "account_id": 42,
            "url": ""
        ]
        XCTAssertNil(PreyNotification.parsePreyMDMPayload(params))
    }

    // MARK: - Edge cases

    func testEmptyDictionaryReturnsNil() {
        XCTAssertNil(PreyNotification.parsePreyMDMPayload(NSDictionary()))
    }

    func testAccountIdZeroIsAccepted() {
        // 0 is a valid Int; only missing/wrong-typed fields should be rejected.
        let params: NSDictionary = [
            "token": "abc",
            "account_id": 0,
            "url": "https://example.com"
        ]
        let payload = PreyNotification.parsePreyMDMPayload(params)
        XCTAssertEqual(payload?.accountId, 0)
    }

    // MARK: - PendingMDMPayloadStore

    /// Round-trip: save then take returns the same payload and clears the slot.
    func testPendingStoreSaveAndTakeRoundTrip() {
        let suite = UserDefaults(suiteName: "group.com.prey.ios")!
        suite.removeObject(forKey: "PendingPreyMDMPayload")
        defer { suite.removeObject(forKey: "PendingPreyMDMPayload") }

        let payload = PreyNotification.PreyMDMPayload(
            token: "stored-token",
            accountId: 7,
            url: "https://solid.preyproject.com/mdm/enroll"
        )
        PreyNotification.PendingMDMPayloadStore.save(payload)

        XCTAssertEqual(PreyNotification.PendingMDMPayloadStore.take(), payload)
        XCTAssertNil(
            PreyNotification.PendingMDMPayloadStore.take(),
            "take() must clear the slot so the same payload doesn't fire twice"
        )
    }

    func testPendingStoreReturnsNilWhenEmpty() {
        let suite = UserDefaults(suiteName: "group.com.prey.ios")!
        suite.removeObject(forKey: "PendingPreyMDMPayload")

        XCTAssertNil(PreyNotification.PendingMDMPayloadStore.take())
    }

    func testPendingStoreClearRemovesPayload() {
        let suite = UserDefaults(suiteName: "group.com.prey.ios")!
        defer { suite.removeObject(forKey: "PendingPreyMDMPayload") }

        let payload = PreyNotification.PreyMDMPayload(
            token: "tok", accountId: 1, url: "https://example.com"
        )
        PreyNotification.PendingMDMPayloadStore.save(payload)
        PreyNotification.PendingMDMPayloadStore.clear()

        XCTAssertNil(PreyNotification.PendingMDMPayloadStore.take())
    }

    /// Even if a stale dictionary is in the slot, take() must reject it without
    /// crashing — the validator runs on the dictionary before returning.
    func testPendingStoreRejectsCorruptedPayload() {
        let suite = UserDefaults(suiteName: "group.com.prey.ios")!
        defer { suite.removeObject(forKey: "PendingPreyMDMPayload") }

        suite.set(["token": "abc"], forKey: "PendingPreyMDMPayload") // missing fields

        XCTAssertNil(PreyNotification.PendingMDMPayloadStore.take())
        XCTAssertNil(suite.dictionary(forKey: "PendingPreyMDMPayload"),
                     "Even on rejection the slot must be cleared so a future valid push can land")
    }

    // MARK: - MDM dispatch (active vs. not-active routing)

    /// With the app already `.active` the push parser must start the server
    /// synchronously AND leave the pending store empty. Otherwise a second
    /// server start fires when the user returns from Safari and
    /// `applicationDidBecomeActive` calls `consumePendingMDMPayload()`.
    /// This is the regression guard for the double-start bug.
    func testDispatchWithActiveAppClearsPendingAndStartsImmediately() {
        let suite = UserDefaults(suiteName: "group.com.prey.ios")!
        suite.removeObject(forKey: "PendingPreyMDMPayload")
        defer { suite.removeObject(forKey: "PendingPreyMDMPayload") }

        let payload = PreyNotification.PreyMDMPayload(
            token: "live-tok", accountId: 1, url: "https://example.com"
        )

        let decision = PreyNotification.dispatchForMDMPayload(payload, appIsActive: true)

        XCTAssertEqual(decision, .startImmediately)
        XCTAssertNil(suite.dictionary(forKey: "PendingPreyMDMPayload"),
                     "Active path must not persist the payload — otherwise didBecomeActive re-runs the server")
    }

    func testDispatchWithInactiveAppSavesAndDefers() {
        let suite = UserDefaults(suiteName: "group.com.prey.ios")!
        suite.removeObject(forKey: "PendingPreyMDMPayload")
        defer { suite.removeObject(forKey: "PendingPreyMDMPayload") }

        let payload = PreyNotification.PreyMDMPayload(
            token: "background-tok", accountId: 9, url: "https://example.com/enroll"
        )

        let decision = PreyNotification.dispatchForMDMPayload(payload, appIsActive: false)

        XCTAssertEqual(decision, .deferUntilActive)
        XCTAssertEqual(
            PreyNotification.PendingMDMPayloadStore.take(),
            payload,
            "Inactive path must persist the payload so didBecomeActive can consume it"
        )
    }

    /// Background push arrives first (payload saved), then a new push lands
    /// while the app is active — the active path must clear the stale payload
    /// so returning from Safari doesn't re-start the server.
    func testDispatchActiveAfterInactiveDropsStalePending() {
        let suite = UserDefaults(suiteName: "group.com.prey.ios")!
        suite.removeObject(forKey: "PendingPreyMDMPayload")
        defer { suite.removeObject(forKey: "PendingPreyMDMPayload") }

        let stale = PreyNotification.PreyMDMPayload(
            token: "stale", accountId: 1, url: "https://example.com/stale"
        )
        _ = PreyNotification.dispatchForMDMPayload(stale, appIsActive: false)
        XCTAssertNotNil(suite.dictionary(forKey: "PendingPreyMDMPayload"),
                        "Precondition: inactive path must have persisted the stale payload")

        let fresh = PreyNotification.PreyMDMPayload(
            token: "fresh", accountId: 2, url: "https://example.com/fresh"
        )
        let decision = PreyNotification.dispatchForMDMPayload(fresh, appIsActive: true)

        XCTAssertEqual(decision, .startImmediately)
        XCTAssertNil(suite.dictionary(forKey: "PendingPreyMDMPayload"),
                     "Active path must drop stale pending so didBecomeActive isn't fooled into a second start")
    }

    // MARK: - Architectural invariant: never prompt the "hard" notification dialog

    /// Prey must only request notification authorization with `.provisional`.
    /// A non-provisional `requestAuthorization` would pop the iOS prompt at
    /// launch — which was explicitly deprecated in favor of silent/provisional
    /// delivery for preymdm. This test scans every .swift file in Prey/Classes
    /// and fails if any call to `requestAuthorization` omits `.provisional`.
    func testRequestAuthorizationOnlyUsesProvisional() throws {
        let classesURL = try classesSourceDirectory()
        var offenders: [(file: String, snippet: String)] = []

        for fileURL in try swiftFiles(in: classesURL) {
            let source = (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
            for call in extractRequestAuthorizationCalls(from: source) {
                if !call.contains(".provisional") {
                    offenders.append((file: fileURL.lastPathComponent, snippet: call))
                }
            }
        }

        XCTAssertTrue(
            offenders.isEmpty,
            "requestAuthorization must always include .provisional. Offenders:\n" +
            offenders.map { "\($0.file): \($0.snippet)" }.joined(separator: "\n")
        )
    }

    // MARK: - Helpers

    private func classesSourceDirectory(file: StaticString = #file) throws -> URL {
        let testFileURL = URL(fileURLWithPath: "\(file)")
        let classesURL = testFileURL
            .deletingLastPathComponent() // PreyTests/
            .deletingLastPathComponent() // repo root
            .appendingPathComponent("Prey")
            .appendingPathComponent("Classes")

        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: classesURL.path, isDirectory: &isDir), isDir.boolValue else {
            throw XCTSkip("Source directory not reachable: \(classesURL.path)")
        }
        return classesURL
    }

    private func swiftFiles(in directory: URL) throws -> [URL] {
        let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        var results: [URL] = []
        while let url = enumerator?.nextObject() as? URL {
            if url.pathExtension == "swift" {
                results.append(url)
            }
        }
        return results
    }

    /// Extract the `options:` list from each `requestAuthorization(options: [...])` call.
    /// Returns the raw content inside the brackets so we can assert on what it contains.
    private func extractRequestAuthorizationCalls(from source: String) -> [String] {
        let marker = "requestAuthorization(options:"
        var results: [String] = []
        var searchRange = source.startIndex..<source.endIndex

        while let hit = source.range(of: marker, range: searchRange) {
            if let openBracket = source[hit.upperBound...].firstIndex(of: "["),
               let closeBracket = source[openBracket...].firstIndex(of: "]") {
                let inside = String(source[source.index(after: openBracket)..<closeBracket])
                results.append(inside)
                searchRange = closeBracket..<source.endIndex
            } else {
                searchRange = hit.upperBound..<source.endIndex
            }
        }
        return results
    }
}
