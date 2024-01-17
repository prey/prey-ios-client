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

class ListPermissions : PreyAction {
    
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
        //get permissions
        let location = DeviceAuth.sharedInstance.checkLocation();
        PreyLogger("locationAuth: \(location)")
        let locationBackground = DeviceAuth.sharedInstance.checkLocationBackground();
        PreyLogger("locationAuthBackground: \(locationBackground)")
        let camera = DeviceAuth.sharedInstance.checkCamera();
        PreyLogger("cameraAuth: \(camera)")
        let backgroundAppRefresh = DeviceAuth.sharedInstance.checkBackgroundRefreshStatus();
        PreyLogger("backgroundAppRefresh: \(backgroundAppRefresh)")
        DeviceAuth.sharedInstance.checkNotify{ granted in
            let notification=granted
            PreyLogger("notification: \(notification)")
            PHPhotoLibrary.requestAuthorization({ authorization -> Void in
                var photos=false;
                switch (authorization) {
                case PHAuthorizationStatus.authorized:
                    photos=true;
                case PHAuthorizationStatus.denied:
                    photos=false;
                case PHAuthorizationStatus.limited:
                    photos=true;
                case PHAuthorizationStatus.notDetermined:
                    photos=false;
                case PHAuthorizationStatus.restricted:
                    photos=false;
                }
                //send listPermissions
                let permissionParam:[String: Any] = [
                    kPermission.location.rawValue : location,
                    kPermission.location_background.rawValue : locationBackground,
                    kPermission.camera.rawValue : camera,
                    kPermission.background_app_refresh.rawValue : backgroundAppRefresh,
                    kPermission.notification.rawValue : notification,
                    kPermission.photos.rawValue : photos]
                let params:[String: Any] = [
                    kGeofence.INFO.rawValue : permissionParam,
                    kGeofence.NAME.rawValue : "list_permission"]
                PreyLogger("listPermissions\(params)")
                GeofencingManager.sharedInstance.sendNotifyToPanel(params,toEndpoint:eventsDeviceEndpoint);
                //send stop list_permissions
                let paramsStop = self.getParamsTo(kAction.list_permissions.rawValue, command: kCommand.start.rawValue, status: kStatus.stopped.rawValue)
                self.sendData(paramsStop, toEndpoint: responseDeviceEndpoint)
            })
        }
    }
}
