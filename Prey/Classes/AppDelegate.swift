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
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // MARK: Properties
    
    var window: UIWindow?
    var bgTask = UIBackgroundTaskIdentifier.invalid
    
    override init() {
        super.init()
        
        // Register for notifications about app state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActiveNotification),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
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
        
        PreyLogger("⭐️ didFinishLaunchingWithOptions - App launch started at \(Date())")
        
        // CRITICAL: Start an immediate background task to prevent suspension
        bgTask = application.beginBackgroundTask { [weak self] in
            PreyLogger("⚠️ Launch background task expiring")
            self?.stopBackgroundTask()
        }
        
        PreyLogger("⭐️ Started launch protection background task: \(bgTask.rawValue)")
        
        // Request Always authorization for location
        let locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        
        // Register for background tasks
        let refreshIdentifier = "\(Bundle.main.bundleIdentifier!).refresh"
        let updateIdentifier = "\(Bundle.main.bundleIdentifier!).update"
        let fetchIdentifier = "\(Bundle.main.bundleIdentifier!).fetch"
        
        // Make sure we register before scheduling
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshIdentifier, using: nil) { task in
            self.handleAppRefresh(task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: updateIdentifier, using: nil) { task in
            self.handleAppUpdate(task as! BGProcessingTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: fetchIdentifier, using: nil) { task in
            self.handleAppFetch(task as! BGAppRefreshTask)
        }
        
        PreyLogger("Registered background tasks with identifiers: \(refreshIdentifier), \(updateIdentifier), \(fetchIdentifier)")
        
        // Set up notification delegate and register notification categories
        UNUserNotificationCenter.current().delegate = self
        
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
        UNUserNotificationCenter.current().setNotificationCategories([alertCategory])
        
        // First check existing notification status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            PreyLogger("📱 PUSH INIT: Current notification authorization status: \(self.authStatusString(settings.authorizationStatus))")
            PreyLogger("📱 PUSH INIT: Alert Setting: \(self.settingStatusString(settings.alertSetting))")
            PreyLogger("📱 PUSH INIT: Badge Setting: \(self.settingStatusString(settings.badgeSetting))")
            PreyLogger("📱 PUSH INIT: Sound Setting: \(self.settingStatusString(settings.soundSetting))")
            
            if #available(iOS 15.0, *) {
                PreyLogger("📱 PUSH INIT: Critical Alert Setting: \(self.settingStatusString(settings.criticalAlertSetting))")
            }
            
            // Request notification permissions if not already authorized
            if settings.authorizationStatus != .authorized {
                PreyLogger("📱 PUSH INIT: Requesting notification permissions...")
                
                // Request with multiple options
                let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .criticalAlert, .provisional]
                UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
                    if let error = error {
                        PreyLogger("📱 PUSH INIT ERROR: ⚠️ Failed to request notification authorization: \(error.localizedDescription)")
                    } else {
                        PreyLogger("📱 PUSH INIT: ✓ Notification authorization request result: \(granted)")
                        
                        // Register for remote notifications on successful authorization
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                            PreyLogger("📱 PUSH INIT: Registered for remote notifications after authorization")
                        }
                    }
                }
            } else {
                // Already authorized, register directly
                DispatchQueue.main.async {
                    PreyLogger("📱 PUSH INIT: Already authorized, registering for remote notifications")
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        PreyLogger("Set UNUserNotificationCenter delegate to AppDelegate and registered categories")
        
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
            
            // CRITICAL: Start critical requests on background thread
            DispatchQueue.global(qos: .userInitiated).async {
                PreyLogger("⭐️ Starting immediate server sync on launch")
                
                // Process pending requests first - highest priority
                RequestCacheManager.sharedInstance.sendRequest()
                
                if let username = PreyConfig.sharedInstance.userApiKey {
                    // Check for actions first
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
                            onCompletion: { isSuccess in
                                PreyLogger("⭐️ Launch action check: \(isSuccess)")
                                
                                // Process any actions immediately
                                PreyModule.sharedInstance.checkActionArrayStatus()
                                PreyModule.sharedInstance.runAction()
                            }
                        )
                    )
                    
                    // Check device status in parallel
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
                            onCompletion: { isSuccess in
                                PreyLogger("⭐️ Launch status check: \(isSuccess)")
                            }
                        )
                    )
                }
            }
            
            // Less critical feature - can run after critical work
            TriggerManager.sharedInstance.checkTriggers()
            
            // Handle notification if app was launched from a notification - CRITICAL PATH
            if let notification = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
                PreyLogger("⭐️ App launched from remote notification - processing immediately")
                
                // Start a high-priority task to handle the notification separately
                let notificationTask = application.beginBackgroundTask { [weak self] in
                    PreyLogger("⚠️ Notification launch task expiring")
                }
                
                // Process immediately on background thread, don't delay
                DispatchQueue.global(qos: .userInitiated).async {
                    PreyNotification.sharedInstance.didReceiveRemoteNotifications(notification) { result in
                        PreyLogger("⭐️ Launch notification processed immediately: \(result)")
                        
                        // Run any actions that might have been triggered
                        PreyModule.sharedInstance.checkActionArrayStatus()
                        PreyModule.sharedInstance.runAction()
                        
                        // End the background task
                        application.endBackgroundTask(notificationTask)
                    }
                }
            }
            
            // Setup periodic timer for foreground API calls - on background thread to avoid UI delay
            DispatchQueue.global().async {
                self.setupForegroundTimer()
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
        
        // Schedule background refresh - CRITICAL
        scheduleAppRefresh()
        
        // Ensure our background task stays alive long enough for critical operations
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) { [weak self] in
            if let self = self, self.bgTask != .invalid {
                PreyLogger("⭐️ Ending launch protection background task after 5s")
                self.stopBackgroundTask()
            }
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
        PreyLogger("applicationDidEnterBackground")
        
        // Hide keyboard
        window?.endEditing(true)
        
        // Create a background task to give us more time
        self.bgTask = UIApplication.shared.beginBackgroundTask {
            self.stopBackgroundTask()
        }
        
        PreyLogger("Started background task in applicationDidEnterBackground: \(self.bgTask.rawValue)")
        
        // Remove the automatic location sending when entering background
        // This was previously:
        // let locationAction = Location(withTarget: kAction.location, withCommand: kCommand.get, withOptions: nil)
        // PreyModule.sharedInstance.actionArray.append(locationAction)
        PreyLogger("NOT sending location when entering background - this is now disabled")
        
        // Check for pending actions before going to background
        PreyModule.sharedInstance.checkActionArrayStatus()
        
        // Schedule background refresh
        scheduleAppRefresh()
        
        // Ensure location services are properly configured for background
        DeviceAuth.sharedInstance.ensureBackgroundLocationIsConfigured()
        
        // Check for shared location data from extension and process it
        if let userDefaults = UserDefaults(suiteName: "group.com.prey.ios"),
           let extensionLocation = userDefaults.dictionary(forKey: "lastLocation"),
           let method = extensionLocation["method"] as? String,
           method == "extension",
           let lat = extensionLocation["lat"] as? Double,
           let lng = extensionLocation["lng"] as? Double,
           let accuracy = extensionLocation["accuracy"] as? Double,
           let timestamp = extensionLocation["timestamp"] as? TimeInterval {
            
            let age = Date().timeIntervalSince1970 - timestamp
            PreyLogger("✅ Found location from extension (age: \(Int(age))s): \(lat), \(lng)")
            
            // Only use if less than 10 minutes old
            if age < 600 && let username = PreyConfig.sharedInstance.userApiKey {
                // Send this location to the server immediately
                let locationParams: [String: Any] = [
                    "lng": lng,
                    "lat": lat,
                    "accuracy": accuracy,
                    "method": "extension_background",
                    "altitude": extensionLocation["alt"] as? Double ?? 0
                ]
                
                let params: [String: Any] = [
                    "location": locationParams,
                    "skip_toast": true
                ]
                
                // Send to server
                PreyLogger("Sending extension location to server")
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
                        onCompletion: { isSuccess in
                            PreyLogger("Extension location sent to server: \(isSuccess)")
                        }
                    )
                )
            } else {
                PreyLogger("Extension location too old or no API key available")
            }
        }
        
        // Request device status from server
        if let username = PreyConfig.sharedInstance.userApiKey {
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
                    onCompletion: { (isSuccess: Bool) in 
                        PreyLogger("Background status check: \(isSuccess)") 
                    }
                )
            )
        }
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
        
        // Check if we need to sync with the server
        if PreyConfig.sharedInstance.isRegistered {
            // Perform immediate sync with server
            syncWithServer()
            
            // Setup periodic timer for foreground API calls
            setupForegroundTimer()
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
        let refreshIdentifier = "\(Bundle.main.bundleIdentifier!).refresh"
        let updateIdentifier = "\(Bundle.main.bundleIdentifier!).update"
        let fetchIdentifier = "\(Bundle.main.bundleIdentifier!).fetch"
        
        // Cancel any existing tasks before scheduling new ones
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: refreshIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: updateIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: fetchIdentifier)
        
        // For production reliability, prioritize processing task for longer runtime
        // Schedule update task (longer background processing) - HIGHEST PRIORITY
        let updateRequest = BGProcessingTaskRequest(identifier: updateIdentifier)
        updateRequest.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        updateRequest.requiresNetworkConnectivity = true
        updateRequest.requiresExternalPower = false
        
        // Schedule fetch task (data fetching) - MEDIUM PRIORITY
        let fetchRequest = BGAppRefreshTaskRequest(identifier: fetchIdentifier)
        fetchRequest.earliestBeginDate = Date(timeIntervalSinceNow: 20 * 60) // 20 minutes
        
        // Schedule refresh task (short, frequent updates) - LOWEST PRIORITY
        let refreshRequest = BGAppRefreshTaskRequest(identifier: refreshIdentifier)
        refreshRequest.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60) // 30 minutes
        
        // Track submission success for logging
        var tasksSubmitted = [String]()
        
        do {
            // Submit tasks in priority order
            try BGTaskScheduler.shared.submit(updateRequest)
            tasksSubmitted.append("update")
            
            try BGTaskScheduler.shared.submit(fetchRequest)
            tasksSubmitted.append("fetch")
            
            try BGTaskScheduler.shared.submit(refreshRequest)
            tasksSubmitted.append("refresh")
            
            PreyLogger("Background tasks scheduled successfully: \(tasksSubmitted.joined(separator: ", "))")
        } catch {
            PreyLogger("Could not schedule background tasks: \(error.localizedDescription), submitted: \(tasksSubmitted.joined(separator: ", "))")
            
            // Use UIBackgroundTask as fallback - this is critical for production
            self.bgTask = UIApplication.shared.beginBackgroundTask {
                self.stopBackgroundTask()
            }
            
            if self.bgTask != .invalid {
                PreyLogger("Started fallback background task: \(self.bgTask.rawValue), time: \(UIApplication.shared.backgroundTimeRemaining)s")
                
                // Create a work item that can be cancelled if needed
                let workItem = DispatchWorkItem { [weak self] in
                    guard let self = self else { return }
                    
                    // Process device info and status
                    if let username = PreyConfig.sharedInstance.userApiKey {
                        // Check device status
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
                                onCompletion: { _ in
                                    // Process any pending actions after status check
                                    PreyModule.sharedInstance.checkActionArrayStatus()
                                    RequestCacheManager.sharedInstance.sendRequest()
                                    
                                    // End background task after processing
                                    self.stopBackgroundTask()
                                }
                            )
                        )
                    } else {
                        self.stopBackgroundTask()
                    }
                }
                
                // Run the work with a shorter delay to ensure it completes
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 2, execute: workItem)
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
        
        // Check for shared location data from extension and process it
        if let userDefaults = UserDefaults(suiteName: "group.com.prey.ios"),
           let extensionLocation = userDefaults.dictionary(forKey: "lastLocation"),
           let method = extensionLocation["method"] as? String,
           method == "extension",
           let lat = extensionLocation["lat"] as? Double,
           let lng = extensionLocation["lng"] as? Double,
           let accuracy = extensionLocation["accuracy"] as? Double,
           let timestamp = extensionLocation["timestamp"] as? TimeInterval {
            
            let age = Date().timeIntervalSince1970 - timestamp
            PreyLogger("✅ Found location from extension (age: \(Int(age))s): \(lat), \(lng)")
            
            // Only use if less than 10 minutes old
            if age < 600 && let username = PreyConfig.sharedInstance.userApiKey {
                // Send this location to the server immediately
                let locationParams: [String: Any] = [
                    "lng": lng,
                    "lat": lat,
                    "accuracy": accuracy,
                    "method": "extension_background",
                    "altitude": extensionLocation["alt"] as? Double ?? 0
                ]
                
                let params: [String: Any] = [
                    "location": locationParams,
                    "skip_toast": true
                ]
                
                // Send to server
                PreyLogger("Sending extension location to server")
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
                        onCompletion: { isSuccess in
                            PreyLogger("Extension location sent to server: \(isSuccess)")
                        }
                    )
                )
            } else {
                PreyLogger("Extension location too old or no API key available")
            }
        }
        
        // Process any pending actions - do this first and with more detailed logging
        PreyLogger("Checking for pending actions in background refresh")
        PreyModule.sharedInstance.checkActionArrayStatus()
        
        // Process any cached requests
        PreyLogger("Processing cached requests in background refresh")
        RequestCacheManager.sharedInstance.sendRequest()
        
        // Ensure location services are properly configured
        PreyLogger("Ensuring location services are configured in background refresh")
        DeviceAuth.sharedInstance.ensureBackgroundLocationIsConfigured()
        
        // Check device info and triggers
        PreyLogger("Checking device info in background refresh")
        PreyDevice.infoDevice { isSuccess in
            PreyLogger("Background refresh - infoDevice: \(isSuccess), time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
            
            TriggerManager.sharedInstance.checkTriggers()
            
            // Check for actions again after device info is updated
            PreyLogger("Checking for actions again after device info update")
            PreyModule.sharedInstance.checkActionArrayStatus()
            
            // Give location services a chance to update
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                // Check for actions one more time before completing
                PreyLogger("Final check for actions before completing background task")
                PreyModule.sharedInstance.checkActionArrayStatus()
                
                // Complete the background task
                PreyLogger("Completing background task, time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
                task.setTaskCompleted(success: true)
                self.stopBackgroundTask()
            }
        }
    }
    
    func handleAppUpdate(_ task: BGProcessingTask) {
        // Schedule a new update task immediately to ensure we always have one scheduled
        scheduleAppRefresh()
        
        // Create task assertion with longer timeout
        let taskAssertionID = UIApplication.shared.beginBackgroundTask {
            PreyLogger("Background update task expiring in AppDelegate")
            self.stopBackgroundTask()
        }
        self.bgTask = taskAssertionID
        
        PreyLogger("Background update task started with ID: \(taskAssertionID.rawValue), time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
        
        // Add task expiration handler with more robust handling
        task.expirationHandler = { [weak self] in
            guard let self = self else { return }
            PreyLogger("⚠️ BGProcessingTask expiring after \(UIApplication.shared.backgroundTimeRemaining) seconds")
            self.stopBackgroundTask()
            task.setTaskCompleted(success: false)
            
            // Try to schedule a new task before we exit
            self.scheduleAppRefresh()
        }
        
        // Get the start time to track performance
        let startTime = Date()
        
        // Use a dispatch group to track all operations
        let updateGroup = DispatchGroup()
        var tasksCompleted = 0
        let totalTasks = 4
        
        // Only proceed if we have a valid API key
        guard let username = PreyConfig.sharedInstance.userApiKey else {
            PreyLogger("No API key available for background update")
            task.setTaskCompleted(success: false)
            self.stopBackgroundTask()
            return
        }
        
        // 1. Process any cached requests first - these might be important
        updateGroup.enter()
        PreyLogger("Processing cached requests in background update")
        RequestCacheManager.sharedInstance.sendRequest()
        
        // Small delay to allow processing to start before continuing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            tasksCompleted += 1
            PreyLogger("Background update - cached requests processing started (\(tasksCompleted)/\(totalTasks))")
            updateGroup.leave()
        }
        
        // 2. Get device information - critical for tracking
        updateGroup.enter()
        PreyLogger("Checking device info in background update")
        PreyDevice.infoDevice { isSuccess in
            tasksCompleted += 1
            PreyLogger("Background update - infoDevice: \(isSuccess) (\(tasksCompleted)/\(totalTasks))")
            updateGroup.leave()
        }
        
        // 3. Check for device triggers
        updateGroup.enter()
        PreyLogger("Checking triggers in background update")
        TriggerManager.sharedInstance.checkTriggers()
        
        // Small delay to allow trigger checking to process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            tasksCompleted += 1
            PreyLogger("Background update - triggers checked (\(tasksCompleted)/\(totalTasks))")
            updateGroup.leave()
        }
        
        // 4. Check for actions from server
        updateGroup.enter()
        PreyLogger("Background update: requesting actions from server")
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
                    tasksCompleted += 1
                    PreyLogger("Background update actions check: \(isSuccess) (\(tasksCompleted)/\(totalTasks))")
                    if isSuccess {
                        // Process the actions immediately
                        PreyModule.sharedInstance.runAction()
                    }
                    updateGroup.leave()
                }
            )
        )
        
        // Set 10-minute timeout (BGProcessingTask can run for much longer than BGAppRefreshTask)
        let timeoutResult = updateGroup.wait(timeout: .now() + 600)
        if timeoutResult == .timedOut {
            PreyLogger("⚠️ Background update timed out after 10 minutes")
        }
        
        // Final check for any actions that may have been received
        PreyModule.sharedInstance.checkActionArrayStatus()
        
        // Calculate elapsed time
        let elapsedSeconds = Date().timeIntervalSince(startTime)
        
        // Complete the background task
        PreyLogger("Completing background update task - \(tasksCompleted)/\(totalTasks) tasks completed, time: \(elapsedSeconds)s")
        task.setTaskCompleted(success: true)
        
        // End the background task
        self.stopBackgroundTask()
    }
    
    func handleAppFetch(_ task: BGAppRefreshTask) {
        // Schedule a new fetch task immediately to ensure we always have one scheduled
        scheduleAppRefresh()
        
        // Create task assertion with longer timeout and save in property
        let taskAssertionID = UIApplication.shared.beginBackgroundTask {
            PreyLogger("Background fetch task expiring in AppDelegate")
            self.stopBackgroundTask()
        }
        self.bgTask = taskAssertionID
        
        PreyLogger("Background fetch task started with ID: \(taskAssertionID.rawValue), time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
        
        // Set up expiration handler with appropriate cleanup
        task.expirationHandler = { [weak self] in
            guard let self = self else { return }
            PreyLogger("⚠️ BGFetch expiring after \(UIApplication.shared.backgroundTimeRemaining) seconds")
            self.stopBackgroundTask()
            task.setTaskCompleted(success: false)
            
            // Try to schedule a new task before we exit
            self.scheduleAppRefresh()
        }
        
        // Get the start time to track performance
        let startTime = Date()
        
        // Use a dispatch group with timeout to track operations
        let fetchGroup = DispatchGroup()
        var wasSuccess = false
        var tasksCompleted = 0
        
        // Only proceed if we have a valid API key
        guard let username = PreyConfig.sharedInstance.userApiKey else {
            PreyLogger("No API key available for background fetch")
            task.setTaskCompleted(success: false)
            self.stopBackgroundTask()
            return
        }
        
        // CRITICAL: Check for pending actions first - this is the most important
        // This will process any previously received actions
        PreyLogger("Background fetch: checking for pending actions")
        PreyModule.sharedInstance.checkActionArrayStatus()
        
        // 1. Check for actions from server - HIGHEST PRIORITY
        fetchGroup.enter()
        PreyLogger("Background fetch: requesting actions from server")
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
                    tasksCompleted += 1
                    PreyLogger("Background fetch actions check: \(isSuccess) (\(tasksCompleted)/3)")
                    if isSuccess {
                        wasSuccess = true
                        // Process the actions immediately
                        PreyModule.sharedInstance.runAction()
                    }
                    fetchGroup.leave()
                }
            )
        )
        
        // 2. Send location data if available - MEDIUM PRIORITY
        fetchGroup.enter()
        if let userDefaults = UserDefaults(suiteName: "group.com.prey.ios"),
           let locationDict = userDefaults.dictionary(forKey: "lastLocation") {
            
            PreyLogger("Background fetch: sending cached location to server")
            
            // Send the location to the server
            let locParam:[String: Any] = [
                kAction.location.rawValue: locationDict,
                kDataLocation.skip_toast.rawValue: true
            ]
            
            PreyHTTPClient.sharedInstance.userRegisterToPrey(
                username,
                password: "x",
                params: locParam,
                messageId: nil,
                httpMethod: Method.POST.rawValue,
                endPoint: dataDeviceEndpoint,
                onCompletion: PreyHTTPResponse.checkResponse(
                    RequestType.dataSend,
                    preyAction: nil,
                    onCompletion: { (isSuccess: Bool) in
                        tasksCompleted += 1
                        PreyLogger("Background fetch location send: \(isSuccess) (\(tasksCompleted)/3)")
                        if isSuccess {
                            wasSuccess = true
                        }
                        fetchGroup.leave()
                    }
                )
            )
        } else {
            PreyLogger("No location data available to send")
            tasksCompleted += 1
            fetchGroup.leave()
        }
        
        // 3. Check device status - LOWEST PRIORITY but still important
        fetchGroup.enter()
        PreyLogger("Background fetch: checking device status")
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
                onCompletion: { (isSuccess: Bool) in
                    tasksCompleted += 1
                    PreyLogger("Background fetch status check: \(isSuccess) (\(tasksCompleted)/3)")
                    if isSuccess {
                        wasSuccess = true
                    }
                    fetchGroup.leave()
                }
            )
        )
        
        // Set 25-second timeout for group (iOS gives us up to 30s max)
        let timeoutResult = fetchGroup.wait(timeout: .now() + 25)
        if timeoutResult == .timedOut {
            PreyLogger("⚠️ Background fetch timed out after 25 seconds")
        }
        
        // Process any actions that may have been received
        PreyModule.sharedInstance.checkActionArrayStatus()
        
        // Process any cached requests that need to be sent
        RequestCacheManager.sharedInstance.sendRequest()
        
        // Calculate elapsed time
        let elapsedSeconds = Date().timeIntervalSince(startTime)
        
        // Complete the background task with appropriate result
        PreyLogger("Completing background fetch task with success: \(wasSuccess), tasks completed: \(tasksCompleted)/3, time: \(elapsedSeconds)s")
        task.setTaskCompleted(success: wasSuccess)
        
        // Ensure location services are configured
        DeviceAuth.sharedInstance.ensureBackgroundLocationIsConfigured()
        
        // End the background task
        self.stopBackgroundTask()
    }
    
    // MARK: Notification
    
    // Did register notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PreyLogger("📱 PUSH REGISTRATION SUCCESS: didRegisterForRemoteNotificationsWithDeviceToken")
        
        // Log the token in a more readable format
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        PreyLogger("📱 PUSH TOKEN: \(tokenString)")
        
        // Determine if we're using sandbox or production APNs
        let isSandboxAPNs = detectSandboxEnvironment()
        PreyLogger("📱 PUSH ENVIRONMENT: \(isSandboxAPNs ? "SANDBOX/DEVELOPMENT" : "PRODUCTION") 🔑")
        PreyLogger("📱 PUSH ENVIRONMENT NOTE: Server must send to the \(isSandboxAPNs ? "SANDBOX" : "PRODUCTION") gateway!")
        
        // Also log token in different formats
        var tokenParts = [String]()
        for i in 0..<deviceToken.count {
            tokenParts.append(deviceToken[i].description)
        }
        PreyLogger("📱 PUSH TOKEN (Alt Format): <\(tokenParts.joined(separator: " "))>")
        
        // Log other notification settings
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            PreyLogger("📱 PUSH SETTINGS: Authorization Status: \(self.authStatusString(settings.authorizationStatus))")
            PreyLogger("📱 PUSH SETTINGS: Alert Setting: \(self.settingStatusString(settings.alertSetting))")
            PreyLogger("📱 PUSH SETTINGS: Badge Setting: \(self.settingStatusString(settings.badgeSetting))")
            PreyLogger("📱 PUSH SETTINGS: Sound Setting: \(self.settingStatusString(settings.soundSetting))")
            
            if #available(iOS 15.0, *) {
                PreyLogger("📱 PUSH SETTINGS: Critical Alert Setting: \(self.settingStatusString(settings.criticalAlertSetting))")
            }
        }
        
        // Process the token
        PreyNotification.sharedInstance.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
        
        // Schedule a background refresh when we get a new token
        scheduleAppRefresh()
        
        // Perform immediate sync with server
        syncWithServer()
    }
    
    // MARK: Foreground API sync
    
    private var foregroundTimer: Timer?
    
    func setupForegroundTimer() {
        // Cancel existing timer if any
        foregroundTimer?.invalidate()
        
        // Create a new timer that runs every 3 minutes
        foregroundTimer = Timer.scheduledTimer(
            //timeInterval: 180,
            timeInterval: 60,
            target: self,
            selector: #selector(foregroundTimerFired),
            userInfo: nil,
            repeats: true
        )
        
        // Add timer to RunLoop to ensure it fires even during scrolling
        RunLoop.current.add(foregroundTimer!, forMode: .common)
        
        // Configure timer to be more tolerant of exact timing
        foregroundTimer?.tolerance = 10.0
        
        PreyLogger("Foreground timer set up to sync with server every 3 minutes")
    }
    
    @objc private func applicationWillResignActiveNotification() {
        PreyLogger("App will resign active - stopping foreground timer")
        foregroundTimer?.invalidate()
        foregroundTimer = nil
    }
    
    @objc func foregroundTimerFired() {
        syncWithServer()
    }
    
    // Track server sync in progress to avoid overlapping calls
    private var serverSyncInProgress = false
    private var lastSyncTimestamp: Date?
    
    func syncWithServer() {
        // Only sync if not already in progress and not done within the last 10 seconds
        let shouldSync = !serverSyncInProgress && 
            (lastSyncTimestamp == nil || Date().timeIntervalSince(lastSyncTimestamp!) > 10)
        
        guard shouldSync else {
            let reason = serverSyncInProgress ? "sync already in progress" : "last sync was too recent"
            PreyLogger("Skipping server sync - \(reason)")
            return
        }
        
        // Set sync in progress
        serverSyncInProgress = true
        lastSyncTimestamp = Date()
        
        PreyLogger("Starting server sync")
        
        // Make sure we have a valid API key
        guard let username = PreyConfig.sharedInstance.userApiKey else {
            PreyLogger("No API key available for server sync")
            serverSyncInProgress = false
            return
        }
        
        // Create a timeout timer to release the lock if something goes wrong
        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { [weak self] _ in
            if self?.serverSyncInProgress == true {
                PreyLogger("⚠️ Server sync timeout - releasing lock after 60 seconds")
                self?.serverSyncInProgress = false
            }
        }
        
        // First check device info
        PreyDevice.infoDevice { [weak self] isSuccess in
            PreyLogger("Foreground sync - infoDevice: \(isSuccess)")
            
            // Then get user profile (whether device info succeeded or not)
            PreyUser.logInToPrey(username, userPassword: "x") { isLoginSuccess in
                PreyLogger("Foreground sync - profile: \(isLoginSuccess)")
                
                // Setup a dispatch group to wait for all API calls to finish
                let syncGroup = DispatchGroup()
                
                // Check if token needs refreshing (more than 1 hour old)
                if (PreyConfig.sharedInstance.tokenWebTimestamp + 60*60) < CFAbsoluteTimeGetCurrent() {
                    syncGroup.enter()
                    PreyUser.getTokenFromPanel(username, userPassword: "x") { isTokenSuccess in
                        PreyLogger("Foreground sync - token refresh: \(isTokenSuccess)")
                        syncGroup.leave()
                    }
                }
                
                // Check for actions from server
                syncGroup.enter()
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
                        onCompletion: { isActionsSuccess in
                            PreyLogger("Foreground sync - actions check: \(isActionsSuccess)")
                            
                            // Run actions if needed
                            if isActionsSuccess {
                                PreyModule.sharedInstance.runAction()
                            }
                            
                            syncGroup.leave()
                        }
                    )
                )
                
                // When all API calls finish
                syncGroup.notify(queue: .main) {
                    PreyLogger("Server sync completed")
                    timeoutTimer.invalidate()
                    self?.serverSyncInProgress = false
                }
            }
        }
    }
    
    // MARK: UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               didReceive response: UNNotificationResponse, 
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        PreyLogger("Received notification response: \(response.actionIdentifier) with userInfo: \(userInfo)")
        
        // Forward handling to PreyNotification
        PreyNotification.sharedInstance.handleNotificationResponse(response)
        
        // Call completion handler
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // Don't show notifications in foreground, we're using the alert view instead
        PreyLogger("Will present notification in foreground: \(notification.request.identifier)")
        
        // Check if this is a Prey alert notification
        if notification.request.content.categoryIdentifier == categoryNotifPreyAlert {
            // For Prey alerts, we don't show notification banners in foreground
            // as we're already showing the AlertVC
            completionHandler([])
            
            // Extract message and triggerId to show in AlertVC
            let message = notification.request.content.body
            
            // Check if it's a Prey Alert and contain a trigger ID
            if let userInfo = notification.request.content.userInfo as? [String: Any],
               let message = userInfo[kOptions.IDLOCAL.rawValue] as? String {
                
                // Create and display the alert action through our Alert class
                let alertOptions = [kOptions.MESSAGE.rawValue: message] as NSDictionary
                let alertAction = Alert(withTarget: kAction.alert, withCommand: kCommand.start, withOptions: alertOptions)
                
                // Set trigger ID if available
                if let triggerId = userInfo[kOptions.trigger_id.rawValue] as? String {
                    alertAction.triggerId = triggerId
                }
                
                // Add the action but don't run it - we just want the alert view
                PreyModule.sharedInstance.actionArray.append(alertAction)
                alertAction.showAlertVC(message)
            }
        } else {
            // For other notifications, show them normally
            if #available(iOS 14.0, *) {
                completionHandler([.banner, .sound, .badge, .list])
            } else {
                completionHandler([.alert, .sound, .badge])
            }
        }
    }
    
    // Fail register notifications
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PreyLogger("📱 PUSH REGISTRATION ERROR: 🚨 \(error.localizedDescription)")
        
        // Log more details about the error
        let nsError = error as NSError
        PreyLogger("📱 PUSH REGISTRATION ERROR DETAILS: domain=\(nsError.domain), code=\(nsError.code), userInfo=\(nsError.userInfo)")
        
        // Check for common error codes
        if nsError.code == 3000 {
            PreyLogger("📱 PUSH REGISTRATION ERROR: This is likely an issue with APNs certificates or entitlements")
        } else if nsError.code == 3010 {
            PreyLogger("📱 PUSH REGISTRATION ERROR: This indicates the simulator was used (expected, as simulator cannot receive push notifications)")
        }
    }
    
    // Did receive remote notification
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Enhanced logging with critical priority information
        let isBackground = application.applicationState == .background
        let contentAvailable = userInfo["content-available"] as? Int ?? 0
        let priorityStr = userInfo["apns-priority"] as? String ?? "unknown"
        let isCritical = userInfo["apns-push-type"] as? String == "critical" || priorityStr == "10"
        
        // CRITICAL: Start background tasks IMMEDIATELY in production builds
        scheduleAppRefresh()
        
        PreyLogger("📱 PUSH RECEIVED: App State: \(isBackground ? "Background" : "Foreground"), Content-Available: \(contentAvailable), Critical: \(isCritical)")
        
        // Log detailed push payload for debugging
        for (key, value) in userInfo {
            PreyLogger("📱 PUSH KEY: \(key) = \(value)")
        }
        
        // Schedule new background tasks immediately to maximize our chances
        scheduleAppRefresh()
        
        // Create a high-priority background task to ensure we have time to process
        var notificationBgTask = UIBackgroundTaskIdentifier.invalid
        let startTime = Date()
        
        // Start the background task with expiration protection
        notificationBgTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            PreyLogger("⚠️ Notification background task expiring after \(Date().timeIntervalSince(startTime)) seconds")
            
            guard let self = self else { return }
            
            // Try to create a new background task before the current one expires
            let cascadingTask = UIApplication.shared.beginBackgroundTask {
                PreyLogger("⚠️ Cascading notification background task also expiring")
                if notificationBgTask != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(notificationBgTask)
                    notificationBgTask = UIBackgroundTaskIdentifier.invalid
                }
                
                // Try to capture final actions before we're terminated
                PreyModule.sharedInstance.checkActionArrayStatus()
                completionHandler(.failed)
            }
            
            if cascadingTask != UIBackgroundTaskIdentifier.invalid {
                // End old task and use new one
                UIApplication.shared.endBackgroundTask(notificationBgTask)
                notificationBgTask = cascadingTask
                PreyLogger("Switched to cascading background task: \(cascadingTask.rawValue)")
                
                // Use this new time to schedule more background tasks
                self.scheduleAppRefresh()
            } else {
                // Clean up if we can't create a new task
                if notificationBgTask != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(notificationBgTask)
                    notificationBgTask = UIBackgroundTaskIdentifier.invalid
                }
                PreyLogger("Notification background task expired without renewal")
                completionHandler(.failed)
            }
        }
        
        let remainingTime = UIApplication.shared.backgroundTimeRemaining
        PreyLogger("🔍 Started notification background task: \(notificationBgTask.rawValue) with \(remainingTime.isFinite ? String(format: "%.1f", remainingTime) : "unlimited") seconds")
        
        // Process with strict timeouts to ensure we complete in time
        let dispatchGroup = DispatchGroup()
        var wasDataReceived = false
        var tasksCompleted = 0
        let totalTasks = 4 // Update this if you add/remove tasks
        
        // Check if we should prioritize certain operations based on payload
        let isActionRequest = userInfo["action"] != nil || userInfo["command"] != nil
        
        // CRITICAL: Process pending actions immediately - this is the most important task
        // If the user is missing their device, we must process any pending actions right away
        PreyLogger("🔍 Checking for pending actions first")
        PreyModule.sharedInstance.checkActionArrayStatus()
        
        // 1. Process the notification through PreyNotification handler
        dispatchGroup.enter()
        PreyLogger("🔍 Processing notification payload")
        PreyNotification.sharedInstance.didReceiveRemoteNotifications(userInfo) { result in
            tasksCompleted += 1
            PreyLogger("🔍 Notification payload processed: \(result) (\(tasksCompleted)/\(totalTasks))")
            
            if result == .newData {
                wasDataReceived = true
            }
            
            // Process any cached requests - might contain important actions
            RequestCacheManager.sharedInstance.sendRequest()
            
            dispatchGroup.leave()
        }
        
        // 2. Request actions from server - highest priority for theft recovery
        dispatchGroup.enter()
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyLogger("🔍 Requesting actions from server")
            
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
                    onCompletion: { isSuccess in
                        tasksCompleted += 1
                        PreyLogger("🔍 Action request completed: \(isSuccess) (\(tasksCompleted)/\(totalTasks))")
                        
                        if isSuccess {
                            wasDataReceived = true
                            // Execute any actions immediately
                            PreyModule.sharedInstance.runAction()
                        }
                        
                        dispatchGroup.leave()
                    }
                )
            )
        } else {
            tasksCompleted += 1
            dispatchGroup.leave()
        }
        
        // 3. Update device info - important for tracking
        dispatchGroup.enter()
        PreyLogger("🔍 Updating device info")
        PreyDevice.infoDevice { isSuccess in
            tasksCompleted += 1
            PreyLogger("🔍 Device info update: \(isSuccess) (\(tasksCompleted)/\(totalTasks))")
            
            // Report possible status change back to server if this is a background notification
            if isBackground && isSuccess {
                wasDataReceived = true
            }
            
            dispatchGroup.leave()
        }
        
        // 4. Check device status - lowest priority but still needed
        dispatchGroup.enter()
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyLogger("🔍 Checking device status")
            
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
                    onCompletion: { isSuccess in
                        tasksCompleted += 1
                        PreyLogger("🔍 Status check completed: \(isSuccess) (\(tasksCompleted)/\(totalTasks))")
                        
                        if isSuccess {
                            wasDataReceived = true
                        }
                        
                        dispatchGroup.leave()
                    }
                )
            )
        } else {
            tasksCompleted += 1
            dispatchGroup.leave()
        }
        
        // Set a safe timeout for our operations - 25 seconds max to allow time for cleanup
        let timeoutResult = dispatchGroup.wait(timeout: .now() + 25)
        if timeoutResult == .timedOut {
            PreyLogger("⚠️ Push notification processing timed out after 25 seconds")
        }
        
        // Final check for actions
        PreyModule.sharedInstance.checkActionArrayStatus()
        
        // Calculate elapsed time
        let elapsedSeconds = Date().timeIntervalSince(startTime)
        
        // Get the latest actions status for logging
        let pendingActions = PreyModule.sharedInstance.actionArray.count
        
        // Determine our result
        let result: UIBackgroundFetchResult
        if wasDataReceived {
            result = .newData
        } else if timeoutResult == .timedOut || tasksCompleted < totalTasks {
            result = .failed
        } else {
            result = .noData
        }
        
        // Schedule more background work before we complete
        scheduleAppRefresh()
        
        // Complete the operation with detailed stats
        PreyLogger("🔍 Remote notification processing completed in \(String(format: "%.1f", elapsedSeconds))s - Result: \(result), Tasks: \(tasksCompleted)/\(totalTasks), Pending actions: \(pendingActions)")
        completionHandler(result)
        
        // End the background task cleanly
        if notificationBgTask != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(notificationBgTask)
            PreyLogger("🔍 Notification background task ended")
            notificationBgTask = UIBackgroundTaskIdentifier.invalid
        }
    }
    
    // Did receiveLocalNotification - this method is deprecated in iOS 10+
    // but we're implementing it for compatibility if needed
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        PreyLogger("Received local notification - deprecated method called")
        
        // Extract the message from the notification
        if let message = notification.alertBody {
            PreyLogger("Local notification message: \(message)")
            
            // Create an alert action 
            let alertOptions = [kOptions.MESSAGE.rawValue: message] as NSDictionary
            let alertAction = Alert(withTarget: kAction.alert, withCommand: kCommand.start, withOptions: alertOptions)
            
            // Add trigger ID if available
            if let info = notification.userInfo, let triggerId = info[kOptions.trigger_id.rawValue] as? String {
                alertAction.triggerId = triggerId
            }
            
            // Run the action
            PreyModule.sharedInstance.actionArray.append(alertAction)
            PreyModule.sharedInstance.runAction()
        }
        
        // Reset badge count
        application.applicationIconBadgeNumber = 0
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
    
    // MARK: Notification Helper Methods
    
    /// Detect if the app is running in the sandbox/development environment
    func detectSandboxEnvironment() -> Bool {
        // Check if app is running in sandbox environment
        
        #if targetEnvironment(simulator)
            return true // Simulator always uses sandbox
        #endif
        
        // Check for development provisioning profile
        if Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil {
            return true // Development provisioning profile means sandbox
        }
        
        // Check environment configuration
        if let apsEnvironment = Bundle.main.object(forInfoDictionaryKey: "aps-environment") as? String,
           apsEnvironment == "development" {
            return true // Explicitly configured for development
        }
        
        // Default to production if we can't determine
        return false
    }
    
    /// Convert UNAuthorizationStatus to a readable string
    func authStatusString(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Determined"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown (\(status.rawValue))"
        }
    }
    
    /// Convert UNNotificationSetting to a readable string
    func settingStatusString(_ setting: UNNotificationSetting) -> String {
        switch setting {
        case .enabled: return "Enabled"
        case .disabled: return "Disabled"
        case .notSupported: return "Not Supported"
        @unknown default: return "Unknown (\(setting.rawValue))"
        }
    }
}
