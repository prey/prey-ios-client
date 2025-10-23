//
//  ListPermissions.swift
//  Prey
//
//  Created by Orlando Aliaga on 28-12-23.
//  Copyright © 2023 Prey, Inc. All rights reserved.
//

import Foundation
import CoreLocation
import AVFoundation
import UserNotifications
import Photos
import UIKit

class ListPermissions : PreyAction, @unchecked Sendable {
    
    // MARK: Properties
    
    // MARK: Functions
    
    override func start() {
        get()
    }
    
    // Prey command
    override func get() {
        //send start list_permissions
        let paramsStart = getParamsTo(kAction.list_permissions.rawValue, command: kCommand.start.rawValue, status: kStatus.started.rawValue)
        self.sendData(paramsStart, toEndpoint: responseDeviceEndpoint)

        //get permissions asynchronously
        getPermissionsAsync { permissionParam in
            //send listPermissions
            let params:[String: Any] = [
                kEvent.info.rawValue : permissionParam,
                kEvent.name.rawValue : "list_permission"]
            PreyLogger("listPermissions: \(params)")
            self.sendData(params, toEndpoint: eventsDeviceEndpoint)

            //send stop list_permissions
            let paramsStop = self.getParamsTo(kAction.list_permissions.rawValue, command: kCommand.stop.rawValue, status: kStatus.stopped.rawValue)
            self.sendData(paramsStop, toEndpoint: responseDeviceEndpoint)
        }
    }

    // Get all permissions asynchronously
    private func getPermissionsAsync(completion: @escaping ([String: Any]) -> Void) {
        // Get location status string
        let locationStatus = getLocationStatusString()
        let location = DeviceAuth.sharedInstance.checkLocation()
        let locationBackground = DeviceAuth.sharedInstance.checkLocationBackground()
        let backgroundAppRefresh = DeviceAuth.sharedInstance.checkBackgroundRefreshStatus()

        PreyLogger("locationAuth: \(location)")
        PreyLogger("locationAuthBackground: \(locationBackground)")
        PreyLogger("locationStatus: \(locationStatus)")
        PreyLogger("backgroundAppRefresh: \(backgroundAppRefresh)")

        // Check notification permission
        DeviceAuth.sharedInstance.checkNotify { notification in
            PreyLogger("notification: \(notification)")

            // Check camera permission
            self.checkCameraPermission { camera in
                PreyLogger("cameraAuth: \(camera)")

                // Check photos permission (only check, don't request)
                self.checkPhotosPermission { photos in
                    PreyLogger("photosAuth: \(photos)")

                    // Build permission parameters
                    let permissionParam: [String: Any] = [
                        kPermission.location.rawValue: location,
                        kPermission.location_background.rawValue: locationBackground,
                        "location_status": locationStatus,
                        kPermission.camera.rawValue: camera,
                        kPermission.background_app_refresh.rawValue: backgroundAppRefresh,
                        kPermission.notification.rawValue: notification,
                        kPermission.photos.rawValue: photos
                    ]

                    completion(permissionParam)
                }
            }
        }
    }

    // Get location status as string
    private func getLocationStatusString() -> String {
        let authStatus = DeviceAuth.sharedInstance.authLocation.authorizationStatus

        switch authStatus {
        case .notDetermined:
            return "never"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorizedAlways:
            return "always"
        case .authorizedWhenInUse:
            return "when_in_use"
        @unknown default:
            return "unknown"
        }
    }

    // Check camera permission without requesting
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            completion(true)
        case .notDetermined, .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    // Check photos permission without requesting
    private func checkPhotosPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()

        switch status {
        case .authorized, .limited:
            completion(true)
        case .denied, .notDetermined, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
}
