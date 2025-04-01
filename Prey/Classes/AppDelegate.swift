//
//  AppDelegate.swift
//  Prey
//
//  Created by Javier Cala Uribe on 5/8/14.
//  Copyright (c) 2014 Prey, Inc. All rights reserved.
//

import UIKit
import BackgroundTasks
import CoreLocation

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
            let taskId = self.bgTask
            PreyLogger("Ending background task with ID: \(taskId.rawValue), time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
            UIApplication.shared.endBackgroundTask(self.bgTask)
            self.bgTask = UIBackgroundTaskIdentifier.invalid
            PreyLogger("Background task ended: \(taskId.rawValue)")
        }
    }
    
    // MARK: UIApplicationDelegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        PreyLogger("didFinishLaunchingWithOptions")
        
        // Request Always authorization for location
        let locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        
        // Register for background tasks
        let identifier = "com.prey.refresh"
        
        // Make sure we register before scheduling
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            self.handleAppRefresh(task as! BGAppRefreshTask)
        }
        PreyLogger("Registered background task with identifier: \(identifier)")
        
        // Set background fetch interval
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
             
        // Config Fabric SDK - Removed for iOS 13+
        
        // Check settings info
        checkSettingsToBackup()
        
        // Update current localUserSettings with preview versions
        PreyConfig.sharedInstance.updateUserSettings()        

        // Check user email validation state
        if PreyConfig.sharedInstance.validationUserEmail == nil {
            PreyConfig.sharedInstance.validationUserEmail = PreyUserEmailValidation.inactive.rawValue
            PreyConfig.sharedInstance.saveValues()
        }
        
        // Config init UIViewController
        displayScreen()
        
        // Config UINavigationBar
        PreyConfig.sharedInstance.configNavigationBar()
        
        // Check notification_id with server
        if PreyConfig.sharedInstance.isRegistered {
            PreyNotification.sharedInstance.registerForRemoteNotifications()
            TriggerManager.sharedInstance.checkTriggers()
            RequestCacheManager.sharedInstance.sendRequest()
            DispatchQueue.main.async {
                sleep(2)
                PreyDevice.infoDevice({(isSuccess: Bool) in
                    PreyLogger("infoDevice isSuccess:\(isSuccess)")
                })
                PreyUser.logInToPrey(PreyConfig.sharedInstance.userApiKey!, userPassword: "x" , onCompletion: {(isSuccess: Bool) in
                    PreyLogger("profile isSuccess:\(isSuccess)")
                })
                if (PreyConfig.sharedInstance.tokenWebTimestamp + 60*60) < CFAbsoluteTimeGetCurrent() {
                    PreyUser.getTokenFromPanel(PreyConfig.sharedInstance.userApiKey!, userPassword:"x", onCompletion: {(isSuccess: Bool) in
                        PreyLogger("token isSuccess:\(isSuccess)")
                    })
                }
            }
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
        
        // Check email validation
        if PreyConfig.sharedInstance.validationUserEmail == PreyUserEmailValidation.pending.rawValue, let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:emailValidationEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.emailValidation, preyAction:nil, onCompletion:{(isSuccess: Bool) in PreyLogger("Request email validation")}))
        }
        
        // Schedule background refresh
        scheduleAppRefresh()
        
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
        PreyLogger("applicationDidEnterBackground")
        
        // Hide keyboard
        window?.endEditing(true)
        
        // Schedule background refresh
        scheduleAppRefresh()
        
        // Ensure location services are properly configured for background
        DeviceAuth.sharedInstance.ensureBackgroundLocationIsConfigured()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Check email validation
        if PreyConfig.sharedInstance.validationUserEmail == PreyUserEmailValidation.pending.rawValue, let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:emailValidationEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.emailValidation, preyAction:nil, onCompletion:{(isSuccess: Bool) in PreyLogger("Request email validation")}))
        }

        stopBackgroundTask()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {

        // Show mainView
        if let backgroundImg = window?.viewWithTag(1985) {
            UIView.animate(withDuration: 0.2, animations:{() in backgroundImg.alpha = 0},
                                       completion:{(Bool)  in backgroundImg.removeFromSuperview()})
        }
        

        // Check camouflagegeMode on mainView
        if PreyConfig.sharedInstance.isCamouflageMode, let rootVC = window?.rootViewController as? UINavigationController, let controller = rootVC.topViewController, controller is HomeWebVC {
            window?.endEditing(true)
            displayScreen()
            return
        }
        
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

        // Check if HomeWebVC is presenting Panel
        if let navigationController:UINavigationController = window?.rootViewController as? UINavigationController, let homeWebVC:HomeWebVC = navigationController.topViewController as? HomeWebVC {
            if homeWebVC.showPanel {
                homeWebVC.showPanel = false
                return
            }
        }

        // Check superview on iOS 13 : UIDropShadowView
        if #available(iOS 13.0, *), window?.rootViewController?.view.superview != nil {
            return
        }

        window?.endEditing(true)
        displayScreen()
    }

    func applicationWillTerminate(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        PreyLogger("applicationWillTerminate")
        PreyNotification.sharedInstance.didReceiveRemoteNotifications(userInfo, completionHandler:completionHandler)
    }
    
    // MARK: Background Tasks
    
    func scheduleAppRefresh() {

        let identifier = "com.prey.refresh"
        
        // Cancel any existing tasks before scheduling a new one
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
        
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
            PreyLogger("Background refresh scheduled successfully with identifier: \(identifier)")
        } catch {
            PreyLogger("Could not schedule app refresh: \(error.localizedDescription)")
            
            // Try with a different approach - use regular background tasks instead
            self.bgTask = UIApplication.shared.beginBackgroundTask {
                self.stopBackgroundTask()
            }
            
            if self.bgTask != .invalid {
                PreyLogger("Started regular background task as fallback: \(self.bgTask.rawValue)")
                
                // Schedule a timer to check for updates
                DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                    // Process any pending actions
                    PreyModule.sharedInstance.checkActionArrayStatus()
                    
                    // Process any cached requests
                    RequestCacheManager.sharedInstance.sendRequest()
                    
                    // End the background task
                    self.stopBackgroundTask()
                }
            }
        }

    }
    
    func handleAppRefresh(_ task: BGAppRefreshTask) {
        // Schedule a new refresh task
        scheduleAppRefresh()
        
        // Create task assertion with longer timeout
        let taskAssertionID = UIApplication.shared.beginBackgroundTask {
            PreyLogger("Background task expiring in AppDelegate")
            self.stopBackgroundTask()
        }
        self.bgTask = taskAssertionID
        
        PreyLogger("Background refresh task started with ID: \(taskAssertionID.rawValue), time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
        
        // Add task expiration handler
        task.expirationHandler = {
            PreyLogger("BGTask expiring, time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
            self.stopBackgroundTask()
            task.setTaskCompleted(success: false)
        }
        
        // Process any pending actions
        PreyModule.sharedInstance.checkActionArrayStatus()
        
        // Process any cached requests
        RequestCacheManager.sharedInstance.sendRequest()
        
        // Ensure location services are properly configured
        DeviceAuth.sharedInstance.ensureBackgroundLocationIsConfigured()
        
        // Check device info and triggers
        PreyDevice.infoDevice { isSuccess in
            PreyLogger("Background refresh - infoDevice: \(isSuccess), time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
            
            TriggerManager.sharedInstance.checkTriggers()
            
            // Give location services a chance to update
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                // Complete the background task
                PreyLogger("Completing background task, time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
                task.setTaskCompleted(success: true)
                self.stopBackgroundTask()
            }
        }
    }
    
    // MARK: Notification
    
    // Did register notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PreyLogger("didRegisterForRemoteNotificationsWithDeviceToken")
        
        // Log the token in a more readable format
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        PreyLogger("Device token: \(tokenString)")
        
        // Process the token
        PreyNotification.sharedInstance.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
        
        // Schedule a background refresh when we get a new token
        scheduleAppRefresh()
    }
    
    // Fail register notifications
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PreyLogger("didFailToRegisterForRemoteNotificationsWithError: \(error)")
    }
    
    // Did receive remote notification
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        PreyLogger("didReceiveRemoteNotification")
        PreyNotification.sharedInstance.didReceiveRemoteNotifications(userInfo, completionHandler:completionHandler)
    }
    
    // Did receiveLocalNotification
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        PreyLogger("didReceive")
        PreyNotification.sharedInstance.checkLocalNotification(application, localNotification:notification)
    }
    
     // MARK: Handling Launch for Tasks

    // MARK: Check settings on backup
    
    // check settings
    func checkSettingsToBackup() {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let docURL = urls[urls.endIndex-1]
        let storeURL = docURL.appendingPathComponent("skpBckp")
        
        if !fileManager.fileExists(atPath: storeURL.path) {
            // Not exist skipBackup file
            // Check if app was restored from iCloud
            if PreyConfig.sharedInstance.isRegistered && PreyConfig.sharedInstance.existBackup {
                PreyConfig.sharedInstance.resetValues()
            }
            fileManager.createFile(atPath: storeURL.path, contents: nil, attributes: nil)
            _ = self.addSkipBackupAttributeToItemAtURL(filePath: storeURL.path)
            PreyConfig.sharedInstance.existBackup = true
            PreyConfig.sharedInstance.saveValues()
        }
    }
    
    // Add skip backup
    func addSkipBackupAttributeToItemAtURL(filePath:String) -> Bool {
        let URL:NSURL = NSURL.fileURL(withPath: filePath) as NSURL
        assert(FileManager.default.fileExists(atPath: filePath), "File \(filePath) does not exist")
        var success: Bool
        do {
            try URL.setResourceValue(true, forKey:URLResourceKey.isExcludedFromBackupKey)
            success = true
        } catch let error as NSError {
            success = false
            PreyLogger("Error: \(error) excluding from backup");
        }
        return success
    }
}
