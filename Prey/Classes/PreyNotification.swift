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
    private init() {
    }
    
    var requestVerificationSucceeded : ((UIBackgroundFetchResult) -> Void)?
    
    // MARK: Functions
    
    // Local notification
    func checkLocalNotification(application:UIApplication, localNotification:UILocalNotification) {
        
        if let message:String = localNotification.alertBody {
            PreyLogger("Show message local notification")
            // Add alert action
            let alertOptions = [kOptions.MESSAGE.rawValue: message] as NSDictionary
            if let alertAction:Alert = Alert(withTarget:kAction.alert, withCommand:kCommand.start, withOptions:alertOptions) {
                PreyModule.sharedInstance.actionArray.append(alertAction)
                PreyModule.sharedInstance.runAction()
            }            
        }
        
        application.applicationIconBadgeNumber = -1
        application.cancelAllLocalNotifications()
    }
    
    // Register Device to Apple Push Notification Service
    func registerForRemoteNotifications() {
        
        if #available(iOS 8.0, *) {
            
            let settings = UIUserNotificationSettings(forTypes:[UIUserNotificationType.Alert,
                                                                UIUserNotificationType.Badge,
                                                                UIUserNotificationType.Sound],
                                                      categories: nil)

            UIApplication.sharedApplication().registerUserNotificationSettings(settings)
            UIApplication.sharedApplication().registerForRemoteNotifications()
            
        } else {
            UIApplication.sharedApplication().registerForRemoteNotificationTypes([UIRemoteNotificationType.Alert,
                                                                                  UIRemoteNotificationType.Badge,
                                                                                  UIRemoteNotificationType.Sound])
        }
    }
    
    // Did Register Remote Notifications
    func didRegisterForRemoteNotificationsWithDeviceToken(deviceToken: NSData) {
        
        let characterSet: NSCharacterSet    = NSCharacterSet(charactersInString: "<>")
        let tokenAsString: String           = (deviceToken.description as NSString)
                                            .stringByTrimmingCharactersInSet(characterSet)
                                            .stringByReplacingOccurrencesOfString(" ", withString: "") as String

        PreyLogger("Token: \(tokenAsString)")
        
        let params:[String: AnyObject] = ["notification_id" : tokenAsString]
        
        // Check userApiKey isn't empty
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:dataDeviceEndpoint, onCompletion:PreyHTTPResponse.checkDataSend(nil))
        }
    }
    
    // Did Receive Remote Notifications
    func didReceiveRemoteNotifications(userInfo: [NSObject : AnyObject], completionHandler:(UIBackgroundFetchResult) -> Void) {
        
        PreyLogger("Remote notification received \(userInfo.description)")
        
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
    func checkRequestVerificationSucceded(isSuccess:Bool) {
        
        if isSuccess {
            requestVerificationSucceeded?(UIBackgroundFetchResult.NewData)
        } else {
            requestVerificationSucceeded?(UIBackgroundFetchResult.Failed)
        }
    }
}