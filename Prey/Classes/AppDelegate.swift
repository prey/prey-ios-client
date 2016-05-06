//
//  AppDelegate.swift
//  Prey
//
//  Created by Javier Cala Uribe on 5/8/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: Properties
    
    var window: UIWindow?

    // MARK: UIApplicationDelegate
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Check notification_id with server
        if PreyConfig.sharedInstance.isRegistered {
            PreyNotification.sharedInstance.registerForRemoteNotifications()
        }
        
        return true
    }    
    
    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
    }

    func applicationWillTerminate(application: UIApplication) {
    }
    
    // MARK: Notification
    
    // Did register notifications
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        PreyNotification.sharedInstance.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
    }
    
    // Fail register notifications
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("Error Register Notification: \(error)")
    }
    
    // Did receive remote notification
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        PreyNotification.sharedInstance.didReceiveRemoteNotifications(userInfo, completionHandler:completionHandler)
    }
}

