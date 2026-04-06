import XCTest
import Foundation

class LocationStoreTests: XCTestCase {

    var sut: LocationStore!
    let testSuite = "com.prey.LocationStoreTests"

    override func setUp() {
        super.setUp()
        sut = LocationStore(suiteName: testSuite)
        let defaults = UserDefaults(suiteName: testSuite)!
        defaults.removePersistentDomain(forName: testSuite)
    }

    override func tearDown() {
        UserDefaults(suiteName: testSuite)?.removePersistentDomain(forName: testSuite)
        sut = nil
        super.tearDown()
    }

    // MARK: - Save

    func testSaveWritesLocationParams() {
        let params: [String: Any] = [
            "lat": -33.4489,
            "lng": -70.6693,
            "alt": 570.0,
            "accuracy": 65.0,
            "method": "native"
        ]

        sut.save(params: params, status: "updated")

        let defaults = UserDefaults(suiteName: testSuite)!
        let saved = defaults.dictionary(forKey: "lastLocation")
        XCTAssertNotNil(saved)
        XCTAssertEqual(saved?["lat"] as? Double, -33.4489)
        XCTAssertEqual(saved?["lng"] as? Double, -70.6693)
        XCTAssertEqual(saved?["method"] as? String, "native")
    }

    func testSaveWritesStatus() {
        sut.save(params: [:], status: "updated_geoip")

        let defaults = UserDefaults(suiteName: testSuite)!
        XCTAssertEqual(defaults.string(forKey: "extension_last_status"), "updated_geoip")
    }

    func testSaveWritesTimestamp() {
        let before = Date().timeIntervalSince1970
        sut.save(params: [:], status: "updated")
        let after = Date().timeIntervalSince1970

        let defaults = UserDefaults(suiteName: testSuite)!
        let ts = defaults.double(forKey: "extension_last_run")
        XCTAssertGreaterThanOrEqual(ts, before)
        XCTAssertLessThanOrEqual(ts, after)
    }

    // MARK: - Load Credentials

    func testLoadCredentialsReturnsNilWhenMissing() {
        XCTAssertNil(sut.loadCredentials())
    }

    func testLoadCredentialsReturnsNilWhenPartial() {
        let defaults = UserDefaults(suiteName: testSuite)!
        defaults.set("apikey", forKey: "UserApiKey")
        // DeviceKey missing
        XCTAssertNil(sut.loadCredentials())
    }

    func testLoadCredentialsReturnsValues() {
        let defaults = UserDefaults(suiteName: testSuite)!
        defaults.set("myApiKey", forKey: "UserApiKey")
        defaults.set("myDeviceKey", forKey: "DeviceKey")

        let creds = sut.loadCredentials()
        XCTAssertNotNil(creds)
        XCTAssertEqual(creds?.apiKey, "myApiKey")
        XCTAssertEqual(creds?.deviceKey, "myDeviceKey")
    }
}
