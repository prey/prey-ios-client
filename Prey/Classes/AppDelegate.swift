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
        
        PreyLogger("didFinishLaunchingWithOptions")
        
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
            TriggerManager.sharedInstance.checkTriggers()
            RequestCacheManager.sharedInstance.sendRequest()
            
            // Handle notification if app was launched from a notification
            if let notification = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
                PreyLogger("App launched from remote notification: \(notification)")
                PreyNotification.sharedInstance.didReceiveRemoteNotifications(notification) { _ in
                    PreyLogger("Finished processing launch notification")
                }
            }
            
            // Perform immediate sync with server
            syncWithServer()
            
            // Setup periodic timer for foreground API calls
            setupForegroundTimer()
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
        
        // Create a background task to give us more time
        self.bgTask = UIApplication.shared.beginBackgroundTask {
            self.stopBackgroundTask()
        }
        
        PreyLogger("Started background task in applicationDidEnterBackground: \(self.bgTask.rawValue)")
        
        // Force a location action to keep the app running in background
        let locationAction = Location(withTarget: kAction.location, withCommand: kCommand.get, withOptions: nil)
        PreyModule.sharedInstance.actionArray.append(locationAction)
        PreyLogger("Added background location action in applicationDidEnterBackground")
        
        // Check for pending actions before going to background
        PreyModule.sharedInstance.checkActionArrayStatus()
        
        // Schedule background refresh
        scheduleAppRefresh()
        
        // Ensure location services are properly configured for background
        DeviceAuth.sharedInstance.ensureBackgroundLocationIsConfigured()
        
        // Check for shared location data from extension
        if let userDefaults = UserDefaults(suiteName: "group.com.prey.ios"),
           let lastLocation = userDefaults.dictionary(forKey: "lastLocation") {
            PreyLogger("Found shared location data from extension: \(lastLocation)")
            // Process location data if needed
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
        
        // Schedule refresh task (short, frequent updates)
        let refreshRequest = BGAppRefreshTaskRequest(identifier: refreshIdentifier)
        refreshRequest.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        // Schedule update task (longer background processing)
        let updateRequest = BGProcessingTaskRequest(identifier: updateIdentifier)
        updateRequest.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour
        updateRequest.requiresNetworkConnectivity = true
        updateRequest.requiresExternalPower = false
        
        // Schedule fetch task (data fetching)
        let fetchRequest = BGAppRefreshTaskRequest(identifier: fetchIdentifier)
        fetchRequest.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60) // 30 minutes
        
        do {
            // Submit all task requests
            try BGTaskScheduler.shared.submit(refreshRequest)
            try BGTaskScheduler.shared.submit(updateRequest)
            try BGTaskScheduler.shared.submit(fetchRequest)
            PreyLogger("Background tasks scheduled successfully")
        } catch {
            PreyLogger("Could not schedule background tasks: \(error.localizedDescription)")
            
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
        
        // Check for shared location data from extension
        if let userDefaults = UserDefaults(suiteName: "group.com.prey.ios"),
           let lastLocation = userDefaults.dictionary(forKey: "lastLocation") {
            PreyLogger("Found shared location data from extension: \(lastLocation)")
            // Process location data if needed
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
        // Schedule a new update task
        scheduleAppRefresh()
        
        // Create task assertion with longer timeout
        let taskAssertionID = UIApplication.shared.beginBackgroundTask {
            PreyLogger("Background update task expiring in AppDelegate")
            self.stopBackgroundTask()
        }
        self.bgTask = taskAssertionID
        
        PreyLogger("Background update task started with ID: \(taskAssertionID.rawValue)")
        
        // Add task expiration handler
        task.expirationHandler = {
            PreyLogger("BGProcessingTask expiring")
            self.stopBackgroundTask()
            task.setTaskCompleted(success: false)
        }
        
        // Process any cached requests that need more time
        PreyLogger("Processing cached requests in background update")
        RequestCacheManager.sharedInstance.sendRequest()
        
        // Check device info and triggers - this has longer to run than refresh
        PreyLogger("Checking device info in background update")
        PreyDevice.infoDevice { isSuccess in
            PreyLogger("Background update - infoDevice: \(isSuccess)")
            
            // Check for actions after device info is updated
            PreyModule.sharedInstance.checkActionArrayStatus()
            
            // Complete the background task
            PreyLogger("Completing background update task")
            task.setTaskCompleted(success: true)
            self.stopBackgroundTask()
        }
    }
    
    func handleAppFetch(_ task: BGAppRefreshTask) {
        // Schedule a new fetch task
        scheduleAppRefresh()
        
        // Create task assertion with longer timeout
        let taskAssertionID = UIApplication.shared.beginBackgroundTask {
            PreyLogger("Background fetch task expiring in AppDelegate")
            self.stopBackgroundTask()
        }
        self.bgTask = taskAssertionID
        
        PreyLogger("Background fetch task started with ID: \(taskAssertionID.rawValue)")
        
        // Add task expiration handler
        task.expirationHandler = {
            PreyLogger("BGFetch expiring")
            self.stopBackgroundTask()
            task.setTaskCompleted(success: false)
        }
        
        // Use a dispatch group to track completion of all operations
        let fetchGroup = DispatchGroup()
        var wasSuccess = false
        
        // Check for actions from server first
        if let username = PreyConfig.sharedInstance.userApiKey {
            // First check for actions
            fetchGroup.enter()
            PreyLogger("Background fetch: checking for actions from server")
            
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
                        PreyLogger("Background fetch actions check: \(isSuccess)")
                        if isSuccess {
                            wasSuccess = true
                        }
                        fetchGroup.leave()
                    }
                )
            )
            
            // Then check device status
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
                        PreyLogger("Background fetch status check: \(isSuccess)")
                        if isSuccess {
                            wasSuccess = true
                        }
                        fetchGroup.leave()
                    }
                )
            )
            
            // Then send current location if available
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
                            PreyLogger("Background fetch location send: \(isSuccess)")
                            fetchGroup.leave()
                        }
                    )
                )
            } else {
                // No location available
                fetchGroup.leave()
            }
            
            // Process any pending actions from previous calls
            PreyModule.sharedInstance.checkActionArrayStatus()
            
            // When all operations are complete
            fetchGroup.notify(queue: .main) {
                // Ensure all actions are processed
                PreyModule.sharedInstance.checkActionArrayStatus()
                
                // Complete the background task
                PreyLogger("Completing background fetch task with success: \(wasSuccess)")
                task.setTaskCompleted(success: wasSuccess)
                self.stopBackgroundTask()
                
                // Ensure location services are configured
                DeviceAuth.sharedInstance.ensureBackgroundLocationIsConfigured()
            }
        } else {
            // Complete task if we can't make the request
            PreyLogger("No API key available for background fetch")
            task.setTaskCompleted(success: false)
            self.stopBackgroundTask()
        }
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
        PreyLogger("📱 PUSH RECEIVED: didReceiveRemoteNotification - App State: \(application.applicationState == .background ? "Background" : "Foreground"), Content-Available: \(userInfo["content-available"] as? Int ?? 0)")
        
        // Log the push notification content for debugging with better formatting
        PreyLogger("📱 PUSH PAYLOAD: \(userInfo)")
        
        // Log each key-value pair separately for better readability
        for (key, value) in userInfo {
            PreyLogger("📱 PUSH KEY: \(key) = \(value)")
        }
        
        // Create a long-running background task to ensure we have time to process
        var notificationBgTask = UIBackgroundTaskIdentifier.invalid
        
        notificationBgTask = UIApplication.shared.beginBackgroundTask {
            PreyLogger("⚠️ Notification background task expiring")
            
            // Try to request more time with a new background task before expiration
            let newTask = UIApplication.shared.beginBackgroundTask {
                PreyLogger("⚠️ Secondary notification background task expiring")
                if notificationBgTask != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(notificationBgTask)
                    notificationBgTask = UIBackgroundTaskIdentifier.invalid
                }
            }
            
            if newTask != UIBackgroundTaskIdentifier.invalid {
                // End old task and use new one
                UIApplication.shared.endBackgroundTask(notificationBgTask)
                notificationBgTask = newTask
                PreyLogger("Renewed notification background task: \(newTask.rawValue)")
            } else {
                if notificationBgTask != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(notificationBgTask)
                    notificationBgTask = UIBackgroundTaskIdentifier.invalid
                }
                PreyLogger("Notification background task expired")
            }
        }
        
        PreyLogger("Started notification background task: \(notificationBgTask.rawValue) with remaining time: \(UIApplication.shared.backgroundTimeRemaining)")
        
        // Use a dispatch group to ensure all operations complete
        let dispatchGroup = DispatchGroup()
        var wasDataReceived = false
        
        // Always try to sync device status when we receive a notification
        dispatchGroup.enter()
        PreyDevice.infoDevice { isSuccess in
            PreyLogger("Remote notification infoDevice: \(isSuccess)")
            dispatchGroup.leave()
        }
        
        // In foreground mode, trigger an immediate server sync
        if application.applicationState != .background {
            syncWithServer()
        }
        
        // Process the notification
        dispatchGroup.enter()
        PreyNotification.sharedInstance.didReceiveRemoteNotifications(userInfo) { result in
            // Process any cached requests
            RequestCacheManager.sharedInstance.sendRequest()
            
            if result == .newData {
                wasDataReceived = true
            }
            dispatchGroup.leave()
        }
        
        // Always check for pending actions
        dispatchGroup.enter()
        if let username = PreyConfig.sharedInstance.userApiKey {
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
                        PreyLogger("Remote notification action check: \(isSuccess)")
                        if isSuccess {
                            wasDataReceived = true
                            PreyModule.sharedInstance.runAction()
                        }
                        dispatchGroup.leave()
                    }
                )
            )
        } else {
            dispatchGroup.leave()
        }
        
        // Also always check device status
        dispatchGroup.enter()
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
                    onCompletion: { isSuccess in
                        PreyLogger("Remote notification status check: \(isSuccess)")
                        if isSuccess {
                            wasDataReceived = true
                        }
                        dispatchGroup.leave()
                    }
                )
            )
        } else {
            dispatchGroup.leave()
        }
        
        // When all operations complete
        dispatchGroup.notify(queue: .main) {
            // Check for any pending actions
            PreyModule.sharedInstance.checkActionArrayStatus()
            
            // Give a small delay to ensure everything completes properly
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                // Complete the fetchCompletionHandler with appropriate result
                let result: UIBackgroundFetchResult = wasDataReceived ? .newData : .noData
                PreyLogger("Remote notification processing complete with result: \(result)")
                completionHandler(result)
                
                // End the background task
                if notificationBgTask != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(notificationBgTask)
                    PreyLogger("Notification background task completed")
                    notificationBgTask = UIBackgroundTaskIdentifier.invalid
                }
            }
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
        // Delegate to PreyNotification's implementation for consistency
        return PreyNotification.sharedInstance.detectSandboxEnvironment()
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
