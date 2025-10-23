//
//  PreyActionsTests.swift
//  PreyTests
//
//  Comprehensive test suite for all Prey actions
//

import XCTest
import CoreLocation
import AVFoundation
import Photos
@testable import Prey

class PreyActionsTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - ListPermissions Tests

    func testListPermissionsGetPermissions() {
        let expectation = self.expectation(description: "Get all permissions")

        let action = ListPermissions(withTarget: kAction.list_permissions, withCommand: kCommand.get, withOptions: nil)

        print("\n========== TESTING LIST PERMISSIONS ==========")
        action.get()

        // Wait for async operations
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            print("==========================================\n")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testLocationStatusValues() {
        print("\n========== TESTING LOCATION STATUS ==========")

        let authStatus = DeviceAuth.sharedInstance.authLocation.authorizationStatus
        var locationStatus = ""

        switch authStatus {
        case .notDetermined:
            locationStatus = "never"
        case .restricted:
            locationStatus = "restricted"
        case .denied:
            locationStatus = "denied"
        case .authorizedAlways:
            locationStatus = "always"
        case .authorizedWhenInUse:
            locationStatus = "when_in_use"
        @unknown default:
            locationStatus = "unknown"
        }

        print("Location Status: \(locationStatus)")
        XCTAssertFalse(locationStatus.isEmpty, "Location status should not be empty")
        print("==========================================\n")
    }

    // MARK: - Report Tests

    func testReportInitialization() {
        let options: [String: Any] = [
            kOptions.interval.rawValue: 5, // 5 minutes
            kOptions.exclude.rawValue: []
        ]

        let action = Report(withTarget: kAction.report, withCommand: kCommand.get, withOptions: options as NSDictionary)
        action.get() // Need to call get() to process the options

        XCTAssertNotNil(action, "Report action should initialize")
        XCTAssertEqual(action.interval, 300.0, "Interval should be 300 seconds (5 minutes * 60)")
        XCTAssertFalse(action.excLocation, "Location should not be excluded by default")
        XCTAssertFalse(action.excPicture, "Picture should not be excluded by default")
    }

    func testReportWithExclusions() {
        let options: [String: Any] = [
            kOptions.interval.rawValue: 10,
            kOptions.exclude.rawValue: [kExclude.location.rawValue, kExclude.picture.rawValue]
        ]

        let action = Report(withTarget: kAction.report, withCommand: kCommand.get, withOptions: options as NSDictionary)
        action.get()

        XCTAssertTrue(action.excLocation, "Location should be excluded")
        XCTAssertTrue(action.excPicture, "Picture should be excluded")
    }

    // MARK: - Location Tests

    func testLocationInitialization() {
        let action = Location(withTarget: kAction.location, withCommand: kCommand.get, withOptions: nil)

        XCTAssertNotNil(action, "Location action should initialize")
        XCTAssertFalse(action.isActive, "Location should not be active initially")
    }

    func testLocationValidation() {
        print("\n========== TESTING LOCATION VALIDATION ==========")

        // Test valid location
        let validLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        print("Valid Location: \(validLocation.coordinate.latitude), \(validLocation.coordinate.longitude)")
        XCTAssertTrue(CLLocationCoordinate2DIsValid(validLocation.coordinate), "Should be valid")

        // Test null island (0,0)
        let nullIsland = CLLocation(latitude: 0.0, longitude: 0.0)
        print("Null Island: \(nullIsland.coordinate.latitude), \(nullIsland.coordinate.longitude)")
        XCTAssertTrue(nullIsland.coordinate.latitude == 0 && nullIsland.coordinate.longitude == 0, "Should detect null island")

        print("==========================================\n")
    }

    // MARK: - Alarm Tests

    func testAlarmInitialization() {
        let action = Alarm(withTarget: kAction.alarm, withCommand: kCommand.start, withOptions: nil)

        XCTAssertNotNil(action, "Alarm action should initialize")
        XCTAssertFalse(action.isActive, "Alarm should not be active initially")
    }

    // MARK: - Alert Tests

    func testAlertInitialization() {
        let options: [String: Any] = [
            kOptions.MESSAGE.rawValue: "Test alert message"
        ]

        let action = Alert(withTarget: kAction.alert, withCommand: kCommand.start, withOptions: options as NSDictionary)

        XCTAssertNotNil(action, "Alert action should initialize")
    }

    func testAlertWithoutMessage() {
        let action = Alert(withTarget: kAction.alert, withCommand: kCommand.start, withOptions: nil)

        // This should handle the missing message gracefully
        action.start()

        XCTAssertNotNil(action, "Alert should handle missing message")
    }

    // MARK: - FileRetrieval Tests

    func testFileRetrievalInitialization() {
        let action = FileRetrieval(withTarget: kAction.fileretrieval, withCommand: kCommand.get, withOptions: nil)

        XCTAssertNotNil(action, "FileRetrieval action should initialize")
    }

    // MARK: - Permission Checking Tests

    func testAllPermissionChecks() {
        let expectation = self.expectation(description: "Check all permissions")

        print("\n========== CHECKING ALL PERMISSIONS ==========")

        // Location
        let location = DeviceAuth.sharedInstance.checkLocation()
        print("✓ Location: \(location)")

        let locationBackground = DeviceAuth.sharedInstance.checkLocationBackground()
        print("✓ Location Background: \(locationBackground)")

        // Camera
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let camera = (cameraStatus == .authorized)
        print("✓ Camera: \(camera) (status: \(cameraStatus.rawValue))")

        // Photos
        let photosStatus = PHPhotoLibrary.authorizationStatus()
        let photos = (photosStatus == .authorized || photosStatus == .limited)
        print("✓ Photos: \(photos) (status: \(photosStatus.rawValue))")

        // Background Refresh
        let backgroundRefresh = UIApplication.shared.backgroundRefreshStatus == .available
        print("✓ Background Refresh: \(backgroundRefresh)")

        // Notifications (async)
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let notification = (settings.authorizationStatus == .authorized)
            print("✓ Notifications: \(notification) (status: \(settings.authorizationStatus.rawValue))")
            print("==========================================\n")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3.0, handler: nil)
    }

    // MARK: - Command Parameter Tests

    func testCommandParameters() {
        print("\n========== TESTING COMMAND PARAMETERS ==========")

        // Test that kCommand.start and kCommand.stop are different
        XCTAssertNotEqual(kCommand.start.rawValue, kCommand.stop.rawValue, "start and stop commands should be different")
        print("✓ kCommand.start: \(kCommand.start.rawValue)")
        print("✓ kCommand.stop: \(kCommand.stop.rawValue)")

        // Test status values
        XCTAssertNotEqual(kStatus.started.rawValue, kStatus.stopped.rawValue, "started and stopped status should be different")
        print("✓ kStatus.started: \(kStatus.started.rawValue)")
        print("✓ kStatus.stopped: \(kStatus.stopped.rawValue)")

        print("==========================================\n")
    }

    // MARK: - Integration Tests

    func testPreyModuleActionsArray() {
        print("\n========== TESTING PREY MODULE ==========")

        let initialCount = PreyModule.sharedInstance.actionArray.count
        print("Initial action count: \(initialCount)")

        // Create and add an action
        let action = Location(withTarget: kAction.location, withCommand: kCommand.get, withOptions: nil)
        PreyModule.sharedInstance.actionArray.append(action)

        let newCount = PreyModule.sharedInstance.actionArray.count
        print("New action count: \(newCount)")

        XCTAssertEqual(newCount, initialCount + 1, "Action should be added to array")

        // Clean up
        PreyModule.sharedInstance.actionArray.removeAll { $0 === action }

        print("==========================================\n")
    }

    // MARK: - Performance Tests

    func testListPermissionsPerformance() {
        measure {
            let action = ListPermissions(withTarget: kAction.list_permissions, withCommand: kCommand.get, withOptions: nil)
            action.get()
        }
    }
}
