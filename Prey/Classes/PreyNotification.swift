//
//  PreyNotification.swift
//  Prey
//
//  Created by Javier Cala Uribe on 3/05/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

class PreyNotification {

    // MARK: Properties
    
    static let sharedInstance = PreyNotification()
    fileprivate init() {
    }
    
    // MARK: Functions
    
    // Handle notification response
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        PreyLogger("Handling notification response: \(response.actionIdentifier) with userInfo: \(userInfo)")
        
        // Extract message from userInfo
        if let message = userInfo[kOptions.IDLOCAL.rawValue] as? String {
            PreyLogger("Show message from notification: \(message)")
            
            // Add alert action
            let alertOptions = [kOptions.MESSAGE.rawValue: message] as NSDictionary
            let alertAction = Alert(withTarget: kAction.alert, withCommand: kCommand.start, withOptions: alertOptions)
            
            // Set trigger ID if available
            if let triggerId = userInfo[kOptions.trigger_id.rawValue] as? String {
                alertAction.triggerId = triggerId
            }
            
            // Add and run the action
            PreyModule.sharedInstance.actionArray.append(alertAction)
            PreyModule.sharedInstance.runAction()
        }
        
        // Reset badge count
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    // Register Device to Apple Push Notification Service
    func registerForRemoteNotifications() {
        // Create notification actions
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION", 
            title: "View Details", 
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION", 
            title: "Dismiss", 
            options: [.destructive]
        )
        
        // Create the category with the actions
        let alertCategory = UNNotificationCategory(
            identifier: categoryNotifPreyAlert, 
            actions: [viewAction, dismissAction], 
            intentIdentifiers: [], 
            options: [.customDismissAction]
        )
        
        // Register the notification categories
        UNUserNotificationCenter.current().setNotificationCategories(Set([alertCategory]))
        
        // Request authorization including critical alerts for iOS 15+
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge, .providesAppNotificationSettings, .criticalAlert]) { (granted, error) in
                // Log permission result
                PreyLogger("Notification permission request result: \(granted)")
                if let error = error {
                    PreyLogger("Notification permission error: \(error.localizedDescription)")
                }
                
                // Check permission granted
                guard granted else { 
                    PreyLogger("Push notification permissions not granted")
                    return 
                }
                
                // Get current settings and register for remote
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    // Check notification settings
                    PreyLogger("Current notification authorization status: \(settings.authorizationStatus.rawValue)")
                    
                    guard settings.authorizationStatus == .authorized else { 
                        PreyLogger("Notification authorization not available")
                        return 
                    }
                    
                    // Register for remote notifications on main thread
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                        PreyLogger("Registered for remote notifications")
                    }
                }
            }
    }
    
    // Did Register Remote Notifications
    func didRegisterForRemoteNotificationsWithDeviceToken(_ deviceToken: Data) {
        let tokenAsString = deviceToken.reduce("") { $0 + String(format: "%02x", $1) }
        PreyLogger("📣 TOKEN REGISTER: Got device token from APNS: \(tokenAsString)")
        
        // Check entitlements
        checkEntitlements()
        
        // Create device info for the server
        let preyDevice = PreyDevice()
        let firmwareInfo : [String:String] = [
            "model_name":  preyDevice.model!,
            "vendor_name": preyDevice.vendor!,
        ]
        let processorInfo : [String:String] = [
            "speed": preyDevice.cpuSpeed!,
            "cores": preyDevice.cpuCores!,
            "model":  preyDevice.cpuModel!,
        ]
        let specs : [String: Any] = [
            "processor_info": processorInfo,
            "firmware_info": firmwareInfo,
        ]
        let hardwareAttributes : [String:String] = [
            "ram_size" : preyDevice.ramSize!,
            "uuid" : preyDevice.uuid!,
        ]
    
        let params:[String: Any] = [
            "notification_id" : tokenAsString,
            "specs": specs,
            "device_name": UIDevice.current.name,
            "hardware_attributes":hardwareAttributes
        ]
        
        PreyLogger("📣 TOKEN REGISTER: Preparing to send token to Prey server with params: \(params)")
        
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyLogger("📣 TOKEN REGISTER: Sending token to Prey server using API key: \(username.prefix(6))...")
            
            PreyHTTPClient.sharedInstance.userRegisterToPrey(
                username, 
                password: "x", 
                params: params, 
                messageId: nil, 
                httpMethod: Method.POST.rawValue, 
                endPoint: dataDeviceEndpoint, 
                onCompletion: PreyHTTPResponse.checkResponse(
                    RequestType.dataSend, 
                    preyAction: nil, 
                    onCompletion: { (isSuccess: Bool) in 
                        if isSuccess {
                            PreyLogger("📣 TOKEN REGISTER: ✅ Successfully registered token with Prey server")
                        } else {
                            PreyLogger("📣 TOKEN REGISTER: ❌ Failed to register token with Prey server")
                        }
                    }
                )
            )
        } else {
            PreyLogger("📣 TOKEN REGISTER: ❌ Cannot register token with server - no API key available")
        }
    }
    
    // Did Receive Remote Notifications with improved completion handling
    func didReceiveRemoteNotifications(_ userInfo: [AnyHashable: Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        PreyLogger("📣 PN PROCESSING: Starting to process remote notification")
        PreyLogger("📣 PN PAYLOAD: \(userInfo)")
        
        // Track whether we received any data to return appropriate completion result
        var receivedData = false

        // Handle all payload types
        if let cmdPreyMDM = userInfo["preymdm"] as? NSDictionary {
            PreyLogger("📣 PN TYPE: preymdm payload detected")
            parsePayloadPreyMDMFromPushNotification(parameters: cmdPreyMDM)
            receivedData = true
        } else {
            PreyLogger("📣 PN CHECK: No preymdm payload found")
        }
        
        if let cmdInstruction = userInfo["cmd"] as? NSArray {
            PreyLogger("📣 PN TYPE: cmd instruction payload detected with \(cmdInstruction.count) items")
            parsePayloadInfoFromPushNotification(instructionArray: cmdInstruction)
            receivedData = true
        } else {
            PreyLogger("📣 PN CHECK: No cmd payload found")
        }
        
        if let cmdArray = userInfo["instruction"] as? NSArray {
            PreyLogger("📣 PN TYPE: instruction payload detected with \(cmdArray.count) items")
            parsePayloadInfoFromPushNotification(instructionArray: cmdArray)
            receivedData = true
        } else {
            PreyLogger("📣 PN CHECK: No instruction payload found")
        }
        
        // APNS silent notification check (content-available = 1)
        if let contentAvailable = userInfo["content-available"] as? Int, contentAvailable == 1 {
            PreyLogger("📣 PN TYPE: Silent notification detected with content-available=1")
            receivedData = true
        } else {
            PreyLogger("📣 PN CHECK: No content-available=1 found")
        }
        
        // APNs aps payload check
        if let aps = userInfo["aps"] as? [String: Any] {
            PreyLogger("📣 PN TYPE: aps payload detected: \(aps)")
            // This is a standard APNS notification
            receivedData = true
        } else {
            PreyLogger("📣 PN CHECK: No aps payload found")
        }
        
        // Run any pending actions that may have been parsed from the notification
        if !PreyModule.sharedInstance.actionArray.isEmpty {
            PreyLogger("📣 PN ACTIONS: Found \(PreyModule.sharedInstance.actionArray.count) actions to run")
            PreyModule.sharedInstance.runAction()
        } else {
            PreyLogger("📣 PN ACTIONS: No actions found to run")
        }
        
        // Complete with appropriate result
        let result = receivedData ? UIBackgroundFetchResult.newData : UIBackgroundFetchResult.noData
        PreyLogger("📣 PN COMPLETE: Finishing notification processing with result: \(result == .newData ? "newData" : "noData")")
        completionHandler(result)
    }
    
    // Parse payload info on push notification
    func parsePayloadPreyMDMFromPushNotification(parameters:NSDictionary) {
        // This token is generated BE-side and guards the enrollment service
        // against data pollution attacks
        guard let token = parameters["token"] as? String else {
          PreyLogger("error reading token from json")
          handlePushError("Missing token in preymdm payload")
          return
        }
      
        guard let accountID = parameters["account_id"] as? Int else {
            PreyLogger("error reading account_id from json")
            handlePushError("Missing account_id in preymdm payload")
            return
        }
        
        guard let urlServer = parameters["url"] as? String else {
            PreyLogger("error reading url from json")
            handlePushError("Missing url in preymdm payload")
            return
        }
      
        PreyMobileConfig.sharedInstance.startService(authToken: token, urlServer: urlServer, accountId: accountID)
    }
    
    // Parse payload info on push notification
    func parsePayloadInfoFromPushNotification(instructionArray:NSArray) {
        PreyLogger("📣 PN PARSE: Starting to parse instruction array with \(instructionArray.count) items")
        
        do {
            let data = try JSONSerialization.data(withJSONObject: instructionArray, options: JSONSerialization.WritingOptions.prettyPrinted)
            if let json = String(data: data, encoding:String.Encoding.utf8) {
                PreyLogger("📣 PN PARSE: Instruction JSON: \(json)")
                
                // Log the first action if available for debugging
                if let firstItem = instructionArray.firstObject as? [String: Any] {
                    PreyLogger("📣 PN PARSE: First instruction item: \(firstItem)")
                }
                
                PreyLogger("📣 PN PARSE: Sending to parseActionsFromPanel")
                PreyModule.sharedInstance.parseActionsFromPanel(json)
                PreyLogger("📣 PN PARSE: Completed parsing actions from panel")
            } else {
                PreyLogger("📣 PN PARSE ERROR: Could not convert JSON data to string")
            }
        } catch let error as NSError {
            PreyLogger("📣 PN PARSE ERROR: JSON serialization failed: \(error.localizedDescription)")
            handlePushError("Failed to parse instruction payload: \(error.localizedDescription)")
        }
    }
    
    // Helper method for handling errors from push notifications
    func handlePushError(_ error: String) {
        PreyLogger("📣 PN ERROR: 🚨 \(error)")
    }
    
    // Check entitlements and device name
    func checkEntitlements() {
        // Check for device-name entitlement
        if let deviceNameEntitlement = Bundle.main.object(forInfoDictionaryKey: "com.apple.developer.device-information.user-assigned-device-name") as? Bool {
            PreyLogger("🔐 ENTITLEMENT: Device name entitlement found: \(deviceNameEntitlement)")
        } else {
            PreyLogger("🔐 ENTITLEMENT: Device name entitlement not found in runtime bundle, check that it's properly set in Prey.entitlements file")
        }
        
        // Check for APNs environment entitlement
        if let apsEnvironment = Bundle.main.object(forInfoDictionaryKey: "aps-environment") as? String {
            PreyLogger("🔐 ENTITLEMENT: APNs environment: \(apsEnvironment)")
        } else {
            PreyLogger("🔐 ENTITLEMENT: APNs environment not found in runtime bundle, check that it's properly set in Prey.entitlements file")
        }
        
        // Get the device name
        let deviceName = UIDevice.current.name
        PreyLogger("📱 DEVICE: Current device name: \(deviceName)")
    }
}
