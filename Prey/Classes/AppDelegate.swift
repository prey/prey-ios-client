//
//  AppDelegate.swift
//  Prey
//
//  Created by Javier Cala Uribe on 5/8/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: Properties
    
    var window: UIWindow?
    var bgTask = UIBackgroundTaskIdentifier.invalid
    
    // MARK: Methods
    
    // Display screen
    func displayScreen() {
        
        // Check PreyModule Status
        PreyModule.sharedInstance.checkActionArrayStatus()
        
        // Relaunch viewController
        let homeIdentifier                  = (PreyConfig.sharedInstance.isCamouflageMode) ? StoryboardIdVC.home.rawValue : StoryboardIdVC.homeWeb.rawValue
        self.window                         = UIWindow(frame: UIScreen.main.bounds)
        let mainStoryboard: UIStoryboard    = UIStoryboard(name:StoryboardIdVC.PreyStoryBoard.rawValue, bundle: nil)
        let rootVC: UINavigationController  = mainStoryboard.instantiateViewController(withIdentifier: StoryboardIdVC.navigation.rawValue) as! UINavigationController
        let controller: UIViewController    = mainStoryboard.instantiateViewController(withIdentifier: homeIdentifier)
        
        rootVC.setViewControllers([controller], animated: false)
        
        self.window?.rootViewController = rootVC
        self.window?.makeKeyAndVisible()
    }
    
    func stopBackgroundTask() {
        if self.bgTask != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(self.bgTask)
            self.bgTask = UIBackgroundTaskIdentifier.invalid
        }
    }
    
    // MARK: UIApplicationDelegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // FIXME: Update apikey crashlytics        
        // Config Fabric SDK
        Fabric.with([Crashlytics.self])
        
        // Config Google Analytics
        GAI.sharedInstance().tracker(withTrackingId: GAICode)
        GAI.sharedInstance().trackUncaughtExceptions                = true
        GAI.sharedInstance().dispatchInterval                       = 120
        GAI.sharedInstance().logger.logLevel                        = GAILogLevel.none
        GAI.sharedInstance().defaultTracker.allowIDFACollection     = true

        // Update current localUserSettings with preview versions
        PreyConfig.sharedInstance.updateUserSettings()        
        
        // Config init UIViewController
        displayScreen()
        
        // Config UINavigationBar
        PreyConfig.sharedInstance.configNavigationBar()
        
        // Check notification_id with server
        if PreyConfig.sharedInstance.isRegistered {
            PreyNotification.sharedInstance.registerForRemoteNotifications()
        } else {
            PreyDeployment.sharedInstance.runPreyDeployment()
        }
        
        // Check CLRegion In/Out
        if let locationLaunch = launchOptions?[UIApplication.LaunchOptionsKey.location] {
            PreyLogger("Prey Geofence received while not running: \(locationLaunch)")
            _ = GeofencingManager.sharedInstance
        }
        
        // Check user is Pro
        if PreyConfig.sharedInstance.isPro {
            // Init geofencing region
            _ = GeofencingManager.sharedInstance
        }
        
        return true
    }    
    
    func applicationWillResignActive(_ application: UIApplication) {
        
        // Hide mainView for multitasking preview
        let backgroundImg   = UIImageView(image:UIImage(named:"BgWelcome"))
        backgroundImg.frame = UIScreen.main.bounds
        backgroundImg.alpha = 0
        backgroundImg.tag   = 1985
        
        window?.addSubview(backgroundImg)
        window?.bringSubviewToFront(backgroundImg)
        
        UIView.animate(withDuration: 0.2, animations:{() in backgroundImg.alpha = 1.0})
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        PreyLogger("Prey is in background")
        
        // Check action list to enable background task
        if PreyConfig.sharedInstance.isRegistered, IS_OS_12 {
            bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                DispatchQueue.main.async {
                    self.stopBackgroundTask()
                }
            })
        }
        
        // Hide keyboard
        window?.endEditing(true)
        
        if PreyConfig.sharedInstance.isRegistered {
            // Check if viewController is HomeWebVC
            if let rootVC = window?.rootViewController as? UINavigationController {
                if let controller = rootVC.topViewController {
                    if controller is HomeWebVC {
                        return
                    }
                }
            }
            for view:UIView in (window?.subviews)! {
                if view.tag != 1985 {
                    view.removeFromSuperview()
                }
            }
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        stopBackgroundTask()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {

        // Show mainView
        let backgroundImg   = window?.viewWithTag(1985)
        
        UIView.animate(withDuration: 0.2, animations:{() in backgroundImg?.alpha = 0},
                                   completion:{(Bool)  in backgroundImg?.removeFromSuperview()})
        
        // Relaunch window
        if  window?.rootViewController?.view.superview == window {
            return
        }

        // Check if viewController is QRCodeVC
        if let controller = window?.rootViewController?.presentedViewController {
            if controller is QRCodeScannerVC {
                return
            }
        }
        
        window?.endEditing(true)
        displayScreen()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Show notification to keep background
        let userInfo : [String:String]      = ["keep_background" : "url"]
        let localNotif                      = UILocalNotification()
        localNotif.userInfo                 = userInfo
        localNotif.alertBody                = "Keep Prey in background to enable all of its features.".localized
        localNotif.hasAction                = false
        localNotif.soundName                = UILocalNotificationDefaultSoundName
        application.presentLocalNotificationNow(localNotif)
    }
    
    // MARK: Notification
    
    // Did register notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if PreyConfig.sharedInstance.isRegistered {
            PreyNotification.sharedInstance.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
        }
    }
    
    // Fail register notifications
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PreyLogger("Error Register Notification: \(error)")
    }
    
    // Did receive remote notification
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if PreyConfig.sharedInstance.isRegistered {
            PreyNotification.sharedInstance.didReceiveRemoteNotifications(userInfo, completionHandler:completionHandler)
        }
    }
    
    // Did receiveLocalNotification
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        PreyLogger("Local notification received")
        PreyNotification.sharedInstance.checkLocalNotification(application, localNotification:notification)
    }    
}

