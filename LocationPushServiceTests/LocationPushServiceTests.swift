import XCTest
import CoreLocation

// LocationPushService.swift is compiled directly in this test target,
// so internal members are accessible without @testable import.

class LocationPushServiceTests: XCTestCase {

    var sut: LocationPushService!
    var testDefaults: UserDefaults!
    let suiteName = "group.com.prey.ios"

    override func setUp() {
        super.setUp()
        sut = LocationPushService()
        testDefaults = UserDefaults(suiteName: suiteName)!
        testDefaults.set("test-api-key", forKey: "UserApiKey")
        testDefaults.set("test-device-key", forKey: "DeviceKey")
        testDefaults.removeObject(forKey: "lastLocation")
        testDefaults.removeObject(forKey: "extension_last_run")
        testDefaults.removeObject(forKey: "extension_last_status")
    }

    override func tearDown() {
        testDefaults.removeObject(forKey: "UserApiKey")
        testDefaults.removeObject(forKey: "DeviceKey")
        testDefaults.removeObject(forKey: "lastLocation")
        testDefaults.removeObject(forKey: "extension_last_run")
        testDefaults.removeObject(forKey: "extension_last_status")
        sut = nil
        testDefaults = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeLocation(lat: Double = -33.4489, lng: Double = -70.6693,
                              alt: Double = 570, accuracy: Double = 65) -> CLLocation {
        CLLocation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                   altitude: alt, horizontalAccuracy: accuracy, verticalAccuracy: 10,
                   timestamp: Date())
    }

    // MARK: - Valid Location Tests

    func testValidLocationPersistsToUserDefaults() {
        let done = expectation(description: "Completion called")

        sut.didReceiveLocationPushPayload([:]) { done.fulfill() }
        sut.locationManager(CLLocationManager(), didUpdateLocations: [makeLocation()])

        waitForExpectations(timeout: 30)

        let saved = testDefaults.dictionary(forKey: "lastLocation")
        XCTAssertNotNil(saved, "Location should be saved to UserDefaults")
        XCTAssertEqual(saved?["lat"] as? Double ?? 0, -33.4489, accuracy: 0.0001)
        XCTAssertEqual(saved?["lng"] as? Double ?? 0, -70.6693, accuracy: 0.0001)
        XCTAssertEqual(saved?["alt"] as? Double, 570)
        XCTAssertEqual(saved?["accuracy"] as? Double, 65)
        XCTAssertEqual(saved?["method"] as? String, "native")
        XCTAssertEqual(testDefaults.string(forKey: "extension_last_status"), "updated")
        XCTAssertNotNil(testDefaults.object(forKey: "extension_last_run"))
    }

    func testUsesLastLocationFromArray() {
        let done = expectation(description: "Completion called")

        sut.didReceiveLocationPushPayload([:]) { done.fulfill() }

        let first = makeLocation(lat: 10, lng: 20, accuracy: 100)
        let second = makeLocation(lat: -33.4489, lng: -70.6693, accuracy: 65)
        sut.locationManager(CLLocationManager(), didUpdateLocations: [first, second])

        waitForExpectations(timeout: 30)

        let saved = testDefaults.dictionary(forKey: "lastLocation")
        XCTAssertEqual(saved?["lat"] as? Double ?? 0, -33.4489, accuracy: 0.0001,
                       "Should use the last location in the array")
    }

    // MARK: - Invalid Location Tests

    func testInvalidAccuracyDoesNotPersist() {
        let done = expectation(description: "Completion called")

        sut.didReceiveLocationPushPayload([:]) { done.fulfill() }
        sut.locationManager(CLLocationManager(), didUpdateLocations: [makeLocation(accuracy: -1)])

        waitForExpectations(timeout: 15)

        XCTAssertNil(testDefaults.dictionary(forKey: "lastLocation"),
                     "Invalid location should not be saved")
    }

    func testEmptyLocationsArrayCallsFinish() {
        let done = expectation(description: "Completion called")

        sut.didReceiveLocationPushPayload([:]) { done.fulfill() }
        sut.locationManager(CLLocationManager(), didUpdateLocations: [])

        waitForExpectations(timeout: 15)
    }

    // MARK: - GeoIP Fallback Tests

    func testLocationDeniedTriggersGeoIPFallback() {
        let done = expectation(description: "Completion called")

        sut.didReceiveLocationPushPayload([:]) { done.fulfill() }
        sut.locationManager(CLLocationManager(), didFailWithError: CLError(.denied))

        waitForExpectations(timeout: 30)

        // If GeoIP succeeded (network available), verify the data
        if let saved = testDefaults.dictionary(forKey: "lastLocation") {
            XCTAssertEqual(saved["method"] as? String, "geoip")
            XCTAssertEqual(saved["accuracy"] as? Double, 5000)
            XCTAssertNotNil(saved["lat"])
            XCTAssertNotNil(saved["lng"])
            XCTAssertEqual(testDefaults.string(forKey: "extension_last_status"), "updated_geoip")
        }
        // If GeoIP failed (no network), completion should still have been called
    }

    func testNonDeniedErrorDoesNotTriggerGeoIP() {
        let done = expectation(description: "Completion called")

        sut.didReceiveLocationPushPayload([:]) { done.fulfill() }
        sut.locationManager(CLLocationManager(), didFailWithError: CLError(.locationUnknown))

        waitForExpectations(timeout: 15)

        XCTAssertNil(testDefaults.dictionary(forKey: "lastLocation"),
                     "Non-denied errors should not trigger GeoIP fallback")
    }

    // MARK: - Timeout Tests

    func testTimeoutCallsCompletion() {
        let done = expectation(description: "Completion called via timeout")

        sut.didReceiveLocationPushPayload([:]) { done.fulfill() }

        // Don't simulate any callback; let the 10s timeout fire
        waitForExpectations(timeout: 15)
    }

    // MARK: - Completion Idempotency

    func testCompletionIsCalledOnlyOnce() {
        var completionCount = 0

        let done = expectation(description: "Completion called")
        done.assertForOverFulfill = false

        sut.didReceiveLocationPushPayload([:]) {
            completionCount += 1
            done.fulfill()
        }

        // Trigger multiple finish() paths simultaneously
        sut.locationManager(CLLocationManager(), didUpdateLocations: [makeLocation()])
        sut.serviceExtensionWillTerminate()

        wait(for: [done], timeout: 30)

        // Extra time to catch any delayed duplicate calls
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 3))

        XCTAssertEqual(completionCount, 1, "Completion should be called exactly once")
    }

    // MARK: - Missing Credentials

    func testMissingCredentialsPersistsButSkipsUpload() {
        testDefaults.removeObject(forKey: "UserApiKey")
        testDefaults.removeObject(forKey: "DeviceKey")

        let done = expectation(description: "Completion called")

        sut.didReceiveLocationPushPayload([:]) { done.fulfill() }
        sut.locationManager(CLLocationManager(), didUpdateLocations: [makeLocation()])

        waitForExpectations(timeout: 15)

        let saved = testDefaults.dictionary(forKey: "lastLocation")
        XCTAssertNotNil(saved, "Location should be saved even without API credentials")
        XCTAssertEqual(saved?["method"] as? String, "native")
    }

    // MARK: - serviceExtensionWillTerminate

    func testServiceExtensionWillTerminateCallsCompletion() {
        let done = expectation(description: "Completion called")

        sut.didReceiveLocationPushPayload([:]) { done.fulfill() }
        sut.serviceExtensionWillTerminate()

        waitForExpectations(timeout: 5)
    }
}
