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

    // MARK: Functions
    
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

        print("Token: \(tokenAsString)")
        
        let params:[String: AnyObject] = ["notification_id" : tokenAsString]
        
        // If userApiKey is empty select userEmail
        let username = (PreyConfig.sharedInstance.userApiKey != nil) ? PreyConfig.sharedInstance.userApiKey : ""
        
        PreyHTTPClient.sharedInstance.userRegisterToPrey(username!, password:"x", params:params, httpMethod:Method.POST.rawValue, endPoint:dataDeviceEndpoint, onCompletion:({(data, response, error) in
            
            // Check error with NSURLSession request
            guard error == nil else {
                
                let alertMessage = (error?.localizedRecoverySuggestion != nil) ? error?.localizedRecoverySuggestion : error?.localizedDescription
                print("Error: \(alertMessage)")
                
                return
            }
            
            print("Notification_id: data:\(data) \nresponse:\(response) \nerror:\(error)")
            
            let httpURLResponse = response as! NSHTTPURLResponse
            
            switch httpURLResponse.statusCode {
                
            // === Success
            case 200...299:
                print("Did register for remote notifications")
                
            // === Error
            default:
                print("Failed to register for remote notifications")
            }
        }))
    }
}