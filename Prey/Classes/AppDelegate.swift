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
        
        // Check CLRegion In/Out
        if let locationLaunch = launchOptions?[UIApplicationLaunchOptionsLocationKey] {
            print("Prey Geofence received while not running: \(locationLaunch)")
            GeofencingManager.sharedInstance
        }
 
        // Check user is Pro
        if PreyConfig.sharedInstance.isPro {
            // Init geofencing region
            GeofencingManager.sharedInstance
        }
        
        // Config init UIViewController
        self.window                         = UIWindow(frame: UIScreen.mainScreen().bounds)
        let mainStoryboard: UIStoryboard    = UIStoryboard(name:StoryboardIdVC.PreyStoryBoard.rawValue, bundle: nil)
        let rootVC: UINavigationController  = mainStoryboard.instantiateViewControllerWithIdentifier(StoryboardIdVC.navigation.rawValue) as! UINavigationController
        let controller: UIViewController    = (PreyConfig.sharedInstance.isRegistered) ? mainStoryboard.instantiateViewControllerWithIdentifier(StoryboardIdVC.home.rawValue) :
                                                                                         mainStoryboard.instantiateViewControllerWithIdentifier(StoryboardIdVC.welcome.rawValue)
        
        rootVC.pushViewController(controller, animated:false)
        
        self.window?.rootViewController = rootVC
        self.window?.makeKeyAndVisible()
        
        return true
    }    
    
    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
        print("Prey is in background")
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
    
    // Did receiveLocalNotification
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        print("Local notification received")
    }
}

