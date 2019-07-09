//
//  PreyNotification.swift
//  Prey
//
//  Created by Javier Cala Uribe on 3/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
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
    
    // Local notification
    func checkLocalNotification(_ application:UIApplication, localNotification:UILocalNotification) {
        
        if let message:String = localNotification.alertBody {
            PreyLogger("Show message local notification")
            // Add alert action
            let alertOptions = [kOptions.MESSAGE.rawValue: message] as NSDictionary
            let alertAction:Alert = Alert(withTarget:kAction.alert, withCommand:kCommand.start, withOptions:alertOptions)
            PreyModule.sharedInstance.actionArray.append(alertAction)
            PreyModule.sharedInstance.runAction()
        }
        
        application.applicationIconBadgeNumber = -1
        application.cancelAllLocalNotifications()
    }
    
    // Register Device to Apple Push Notification Service
    func registerForRemoteNotifications() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
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
        } else {
            // For iOS 8 and 9
            let settings = UIUserNotificationSettings(types:[UIUserNotificationType.alert,
                                                             UIUserNotificationType.badge,
                                                             UIUserNotificationType.sound],
                                                      categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // Did Register Remote Notifications
    func didRegisterForRemoteNotificationsWithDeviceToken(_ deviceToken: Data) {
        PreyLogger("Did register device token")
        let tokenAsString = deviceToken.reduce("") { $0 + String(format: "%02x", $1) }
        
        let params:[String: String] = ["notification_id" : tokenAsString]
        
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:dataDeviceEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.dataSend, preyAction:nil, onCompletion:{(isSuccess: Bool) in PreyLogger("Request dataSend")}))
        }
    }
    
    // Did Receive Remote Notifications
    func didReceiveRemoteNotifications(_ userInfo: [AnyHashable: Any], completionHandler:@escaping (UIBackgroundFetchResult) -> Void) {
        
        PreyLogger("Remote notification received")

        // Check payload preymdm
        if let cmdPreyMDM = userInfo["preymdm"] as? NSDictionary {
            parsePayloadPreyMDMFromPushNotification(parameters: cmdPreyMDM)
        }
        // Check payload info
        if let cmdInstruction = userInfo["cmd"] as? NSArray {
            parsePayloadInfoFromPushNotification(instructionArray: cmdInstruction)
        }
        // Check payload info
        if let cmdArray = userInfo["instruction"] as? NSArray {
            parsePayloadInfoFromPushNotification(instructionArray: cmdArray)
        }
        
        // Set completionHandler for request
        requestVerificationSucceeded.append(completionHandler)
        
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:actionsDeviceEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.actionDevice, preyAction:nil, onCompletion:{(isSuccess: Bool) in
                PreyLogger("Request PreyAction")
            }))
        } else {
            checkRequestVerificationSucceded(false)
        }
    }
    
    // Parse payload info on push notification
    func parsePayloadPreyMDMFromPushNotification(parameters:NSDictionary) {
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
        PreyMobileConfig.sharedInstance.startService(urlServer: urlServer, accountId: accountID)
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
