//
//  PreyNotification.swift
//  Prey
//
//  Created by Javier Cala Uribe on 3/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

class PreyNotification {

    // MARK: Properties
    
    static let sharedInstance = PreyNotification()
    fileprivate init() {
    }
    
    var requestVerificationSucceeded : ((UIBackgroundFetchResult) -> Void)?
    
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
        
        if #available(iOS 8.0, *) {
            
            let settings = UIUserNotificationSettings(types:[UIUserNotificationType.alert,
                                                                UIUserNotificationType.badge,
                                                                UIUserNotificationType.sound],
                                                      categories: nil)

            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
            
        } else {
            UIApplication.shared.registerForRemoteNotifications(matching: [UIRemoteNotificationType.alert,
                                                                                  UIRemoteNotificationType.badge,
                                                                                  UIRemoteNotificationType.sound])
        }
    }
    
    // Did Register Remote Notifications
    func didRegisterForRemoteNotificationsWithDeviceToken(_ deviceToken: Data) {

        var tokenAsString = ""
        for i in 0..<deviceToken.count {
            tokenAsString = tokenAsString + String(format: "%02.2hhx", arguments: [deviceToken[i]])
        }
        PreyLogger("Token: \(tokenAsString)")
        
        let params:[String: String] = ["notification_id" : tokenAsString]
        
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:dataDeviceEndpoint, onCompletion:PreyHTTPResponse.checkDataSend(nil))
        }
    }
    
    // Did Receive Remote Notifications
    func didReceiveRemoteNotifications(_ userInfo: [AnyHashable: Any], completionHandler:@escaping (UIBackgroundFetchResult) -> Void) {
        
        PreyLogger("Remote notification received \(userInfo.description)")
        
        // Check payload info
        if let cmdArray = userInfo["instruction"] as? NSArray {
            do {
                let data = try JSONSerialization.data(withJSONObject: cmdArray, options: JSONSerialization.WritingOptions.prettyPrinted)
                if let json = String(data: data, encoding:String.Encoding.utf8) {
                    PreyLogger("Instruction: \(json)")
                    PreyModule.sharedInstance.parseActionsFromPanel(json)
                }
            } catch let error as NSError{
                PreyLogger("json error: \(error.localizedDescription)")
                PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
            }            
        }
        
        // Set completionHandler for request
        requestVerificationSucceeded = completionHandler
        
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password: "x", params: nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:actionsDeviceEndpoint , onCompletion:PreyHTTPResponse.checkActionDevice())
        } else {
            checkRequestVerificationSucceded(false)
        }
        
    }
    
    // Check request verification
    func checkRequestVerificationSucceded(_ isSuccess:Bool) {
        
        if isSuccess {
            requestVerificationSucceeded?(UIBackgroundFetchResult.newData)
        } else {
            requestVerificationSucceeded?(UIBackgroundFetchResult.failed)
        }
    }
}
