//
//  DeviceAuth.swift
//  Prey
//
//  Created by Javier Cala Uribe on 26/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import CoreLocation
import AVFoundation
import UserNotifications
import Contacts
import Photos

class DeviceAuth: NSObject, UIAlertViewDelegate, CLLocationManagerDelegate {

    // MARK: Singleton
    
    static let sharedInstance = DeviceAuth()
    override fileprivate init() {
    }

    // Location Service Auth
    let authLocation = CLLocationManager()
    
    // MARK: Methods
    
    // Check all device auth
    func checkAllDeviceAuthorization(completionHandler:@escaping (_ granted: Bool) -> Void){
        // Check UNUserNotificationCenter async
        checkNotify { granted in
            DispatchQueue.main.async {
                if granted && self.checkLocation() && self.checkCamera() {
                    completionHandler(true)
                } else {
                    completionHandler(false)
                }
            }
        }
    }
    
    // Check notification
    func checkNotify(completionHandler:@escaping (_ granted: Bool) -> Void) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                // Check notification settings
                if settings.authorizationStatus == .authorized {
                    completionHandler(true)
                } else {
                    DispatchQueue.main.async {
                        self.displayMessage("You need to grant Prey access to show alert notifications in order to remotely mark it as missing.".localized,
                                       titleMessage:"Alert notification disabled".localized)
                        completionHandler(false)
                    }
                }
            }
        } else {
            // For iOS 8 and 9
            if let notificationSettings = UIApplication.shared.currentUserNotificationSettings {
                if notificationSettings.types.rawValue > 0 {
                    completionHandler(true)
                } else {
                    DispatchQueue.main.async {
                        self.displayMessage("You need to grant Prey access to show alert notifications in order to remotely mark it as missing.".localized,
                                            titleMessage:"Alert notification disabled".localized)
                        completionHandler(false)
                    }
                }
            } else {completionHandler(true)}
        }
    }
    
    // Check location
    func checkLocation() -> Bool {
        
        var locationAuth = false
        
        if (CLLocationManager.locationServicesEnabled() &&
            CLLocationManager.authorizationStatus() == .notDetermined) {
            authLocation.requestAlwaysAuthorization()
        }
        
        if (CLLocationManager.locationServicesEnabled() &&
            CLLocationManager.authorizationStatus() != .notDetermined &&
            CLLocationManager.authorizationStatus() != .denied &&
            CLLocationManager.authorizationStatus() != .restricted) {
            locationAuth = true
        }
        
        if !locationAuth {
            displayMessage("To fully protect your device Prey must have access to its location at all times. In Settings, go to Location and select Always.".localized,
                           titleMessage: "Enable Location".localized,
                           cancelBtn: "Later".localized
            )
        }
        
        return locationAuth
    }
    
    // Check camera
    func checkCamera() -> Bool {
        
        var cameraAuth = false
        
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized {
            cameraAuth = true
        } else {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:{(granted: Bool) in
                cameraAuth = granted
            })
        }
        
        if !cameraAuth {
            displayMessage("Camera is disabled for Prey. Reports will not be sent.".localized,
                           titleMessage:"Enable Camera".localized)
        }
        
        return cameraAuth
    }
    
    // Display message
    func displayMessage(_ alertMessage:String, titleMessage:String, cancelBtn:String = "Cancel".localized) {
        
        let acceptBtn    = "Go to Settings".localized
        
        let anAlert      = UIAlertView()
        anAlert.title    = titleMessage
        anAlert.message  = alertMessage
        anAlert.delegate = self
        anAlert.addButton(withTitle: acceptBtn)
        anAlert.addButton(withTitle: cancelBtn)
        
        anAlert.show()
    }

    // Call next request auth item
    func callNextRequestAuth(_ idBtn: String) {
        guard let appWindow = UIApplication.shared.delegate?.window else {
            PreyLogger("error with sharedApplication")
            return
        }
        let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController
        if let homeWebVC:HomeWebVC = navigationController.topViewController as? HomeWebVC {
            homeWebVC.evaluateJS(homeWebVC.webView, code: "var btn = document.getElementById('\(idBtn)'); btn.click();")
        }
    }
    
    // Request auth location
    func requestAuthLocation() {
        authLocation.delegate = self
        if (CLLocationManager.locationServicesEnabled() &&
            CLLocationManager.authorizationStatus() == .notDetermined) {
            authLocation.requestAlwaysAuthorization()
        } else {
            callNextRequestAuth("btnLocation")
        }
    }

    // Request auth photos
    func requestAuthPhotos() {
        PHPhotoLibrary.requestAuthorization({ authorization -> Void in
            DispatchQueue.main.async {self.callNextRequestAuth("btnPhotos")}
        })
    }

    // Request auth contacts
    func requestAuthContacts() {
        if #available(iOS 9.0, *) {
            CNContactStore().requestAccess(for: .contacts, completionHandler: { (authorized: Bool, error: Error?) -> Void in
                DispatchQueue.main.async {self.callNextRequestAuth("btnContacts")}
            })
        } else {
            self.callNextRequestAuth("btnContacts")
        }
    }

    // Request auth camera
    func requestAuthCamera() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:{(granted: Bool) in
            DispatchQueue.main.async {self.callNextRequestAuth("btnCamera")}
        })
    }

    // Request auth notification
    func requestAuthNotification(_ callNextView: Bool) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                DispatchQueue.main.async {
                    let alertCategory = UNNotificationCategory(identifier: categoryNotifPreyAlert, actions: [], intentIdentifiers: [], options: [])
                    UNUserNotificationCenter.current().setNotificationCategories(Set([alertCategory]))
                    if callNextView { self.callNextReactView() }
                    // Check permission granted
                    guard granted else { return }
                    UNUserNotificationCenter.current().getNotificationSettings { settings in
                        // Check notification settings
                        guard settings.authorizationStatus == .authorized else { return }
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                }
            }
        } else {
            // For iOS 8 and 9
            let settings = UIUserNotificationSettings(types:[UIUserNotificationType.alert,
                                                             UIUserNotificationType.badge,
                                                             UIUserNotificationType.sound],
                                                      categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
            if callNextView { self.callNextReactView() }
        }
    }
    
    // Call next ReactView
    func callNextReactView() {
        guard let appWindow = UIApplication.shared.delegate?.window else {
            PreyLogger("error with sharedApplication")
            return
        }
        let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController
        if let homeWebVC:HomeWebVC = navigationController.topViewController as? HomeWebVC {
            homeWebVC.loadViewOnWebView("activation")
        }
        // Check location aware action on device status
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:statusDeviceEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.statusDevice, preyAction:nil, onCompletion:{(isSuccess: Bool) in PreyLogger("Request check status") }))
        }
    }

    // MARK: CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        callNextRequestAuth("btnLocation")
    }
    
    // MARK: UIAlertViewDelegate
    
    // AlertView
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        
        guard buttonIndex == 0 else {
            return
        }
        
        if let url = URL(string:UIApplication.openSettingsURLString) {
            UIApplication.shared.openURL(url)
        }
    }
}
