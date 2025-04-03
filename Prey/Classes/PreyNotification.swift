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
    
    var requestVerificationSucceeded        = [((UIBackgroundFetchResult) -> Void)]()
    
    var isCheckingRequestVerificationArray  = false
    
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
        PreyLogger("Did register device token")
        let tokenAsString = deviceToken.reduce("") { $0 + String(format: "%02x", $1) }
        PreyLogger(tokenAsString)
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
            //"hardware_attributes":hardwareAttributes
        ]
        
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:dataDeviceEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.dataSend, preyAction:nil, onCompletion:{(isSuccess: Bool) in PreyLogger("Request dataSend")}))
        }
    }
    
    // Did Receive Remote Notifications
    func didReceiveRemoteNotifications(_ userInfo: [AnyHashable: Any], completionHandler:@escaping (UIBackgroundFetchResult) -> Void) {
        
        PreyLogger("didReceiveRemoteNotifications with payload: \(userInfo)")

        // Check payload preymdm
        if let cmdPreyMDM = userInfo["preymdm"] as? NSDictionary {
            PreyLogger("Processing preymdm payload")
            parsePayloadPreyMDMFromPushNotification(parameters: cmdPreyMDM)
        }
        // Check payload info
        if let cmdInstruction = userInfo["cmd"] as? NSArray {
            PreyLogger("Processing cmd instruction payload")
            parsePayloadInfoFromPushNotification(instructionArray: cmdInstruction)
        }
        // Check payload info
        if let cmdArray = userInfo["instruction"] as? NSArray {
            PreyLogger("Processing instruction payload")
            parsePayloadInfoFromPushNotification(instructionArray: cmdArray)
        }
        
        // APNS silent notification check (content-available = 1)
        if let contentAvailable = userInfo["content-available"] as? Int, contentAvailable == 1 {
            PreyLogger("Processing silent notification with content-available=1")
        }
        
        // Set completionHandler for request
        requestVerificationSucceeded.append(completionHandler)
        
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyLogger("Fetching actions from API in response to push notification")
            PreyHTTPClient.sharedInstance.userRegisterToPrey(
                username, 
                password: "x", 
                params: nil, 
                messageId: nil, 
                httpMethod: Method.GET.rawValue, 
                endPoint: actionsDeviceEndpoint, 
                onCompletion: PreyHTTPResponse.checkResponse(
                    RequestType.actionDevice, 
                    preyAction: nil, 
                    onCompletion: { (isSuccess: Bool) in
                        PreyLogger("Push notification triggered action fetch: \(isSuccess)")
                        
                        // If successful, run actions
                        if isSuccess {
                            PreyModule.sharedInstance.runAction()
                        }
                        
                        // Try device status if actions didn't work
                        if !isSuccess {
                            PreyLogger("Fetching device status after push notification")
                            PreyHTTPClient.sharedInstance.userRegisterToPrey(
                                username,
                                password: "x",
                                params: nil,
                                messageId: nil,
                                httpMethod: Method.GET.rawValue,
                                endPoint: statusDeviceEndpoint,
                                onCompletion: PreyHTTPResponse.checkResponse(
                                    RequestType.statusDevice,
                                    preyAction: nil,
                                    onCompletion: { (statusSuccess: Bool) in
                                        PreyLogger("Push notification triggered status check: \(statusSuccess)")
                                    }
                                )
                            )
                        }
                    }
                )
            )
        } else {
            PreyLogger("No API key available, cannot process push notification")
            checkRequestVerificationSucceded(false)
        }
    }
    
    // Parse payload info on push notification
    func parsePayloadPreyMDMFromPushNotification(parameters:NSDictionary) {
        // This token is generated BE-side and guards the enrollment service
        // against data pollution attacks
        guard let token = parameters["token"] as? String else {
          PreyLogger("error reading token from json")
          PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
          return
        }
      
        guard let accountID = parameters["account_id"] as? Int else {
            PreyLogger("error reading account_id from json")
            PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
            return
        }
        
        guard let urlServer = parameters["url"] as? String else {
            PreyLogger("error reading url from json")
            PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
            return
        }
      
        PreyMobileConfig.sharedInstance.startService(authToken: token, urlServer: urlServer, accountId: accountID)
    }
    
    // Parse payload info on push notification
    func parsePayloadInfoFromPushNotification(instructionArray:NSArray) {
        do {
            let data = try JSONSerialization.data(withJSONObject: instructionArray, options: JSONSerialization.WritingOptions.prettyPrinted)
            if let json = String(data: data, encoding:String.Encoding.utf8) {
                PreyLogger("Instruction")
                PreyModule.sharedInstance.parseActionsFromPanel(json)
            }
        } catch let error as NSError{
            PreyLogger("json error: \(error.localizedDescription)")
            PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
        }
    }
    
    // Check request verification
    func checkRequestVerificationSucceded(_ isSuccess:Bool) {
        // Check if preyActionArray is empty
        guard PreyModule.sharedInstance.actionArray.isEmpty else {
            return
        }
        // Check if array is busy
        guard isCheckingRequestVerificationArray == false else {
            return
        }
        isCheckingRequestVerificationArray = true
        // Finish all completionHandler
        for item in requestVerificationSucceeded {
            if isSuccess {
                item(.newData)
            } else {
                item(.failed)
            }
        }
        requestVerificationSucceeded.removeAll()
        isCheckingRequestVerificationArray = false
    }
}
