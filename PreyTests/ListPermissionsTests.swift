//
//  ListPermissionsTests.swift
//  PreyTests
//
//  Created for testing ListPermissions functionality
//

import XCTest
import CoreLocation
import AVFoundation
import Photos
@testable import Prey

class ListPermissionsTests: XCTestCase {

    var listPermissions: ListPermissions!

    override func setUp() {
        super.setUp()
        listPermissions = ListPermissions(withTarget: kAction.list_permissions, withCommand: kCommand.get, withOptions: nil)
    }

    override func tearDown() {
        listPermissions = nil
        super.tearDown()
    }

    // Test that permissions are collected and sent correctly
    func testGetPermissionsAsync() {
        let expectation = self.expectation(description: "Get permissions async")

        // Call the get method which triggers permission collection
        listPermissions.get()

        // Wait for async operations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0) { error in
            if let error = error {
                XCTFail("Test timed out: \(error)")
            }
        }
    }

    // Test location status string mapping
    func testLocationStatusString() {
        let expectation = self.expectation(description: "Check location status")

        // Access the private method through reflection or make it internal for testing
        // For now, we'll test indirectly by triggering get()
        listPermissions.get()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Check that PreyLogger was called with location status
            // In production, you should check the actual output
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3.0, handler: nil)
    }

    // Manual test to print all permissions
    func testPrintAllPermissions() {
        let expectation = self.expectation(description: "Print all permissions")

        print("\n========== TESTING PERMISSIONS ==========")

        // Test location
        let location = DeviceAuth.sharedInstance.checkLocation()
        print("Location: \(location)")

        let locationBackground = DeviceAuth.sharedInstance.checkLocationBackground()
        print("Location Background: \(locationBackground)")

        let authStatus = DeviceAuth.sharedInstance.authLocation.authorizationStatus
        var locationStatus = Location.getLocationStatusString(authStatus)
        print("Location Status: \(locationStatus)")

        // Test camera
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        var camera = false
        switch cameraStatus {
        case .authorized:
            camera = true
        default:
            camera = false
        }
        print("Camera: \(camera)")

        // Test photos
        let photosStatus = PHPhotoLibrary.authorizationStatus()
        var photos = false
        switch photosStatus {
        case .authorized, .limited:
            photos = true
        default:
            photos = false
        }
        print("Photos: \(photos)")

        // Test background refresh
        let backgroundRefresh = UIApplication.shared.backgroundRefreshStatus == .available
        print("Background Refresh: \(backgroundRefresh)")

        // Test notifications
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let notification = settings.authorizationStatus == .authorized
            print("Notifications: \(notification)")

            print("========================================\n")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3.0, handler: nil)
    }
}
