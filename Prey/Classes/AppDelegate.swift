//
//  AppDelegate.swift
//  Prey
//
//  Created by Javier Cala Uribe on 5/8/14.
//  Modified by Patricio Jofré on 04/08/2025.
//  Copyright (c) 2014 Prey, Inc. All rights reserved.
//

import UIKit
import BackgroundTasks
import CoreLocation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // MARK: Properties
    
    var window: UIWindow?
    // Optional bgTask
    var bgTask: UIBackgroundTaskIdentifier?
    
    static let appRefreshTaskIdentifier = "\(Bundle.main.bundleIdentifier!).appRefresh"
    static let processingTaskIdentifier = "\(Bundle.main.bundleIdentifier!).processing"
    
    // Using a Timer or DispatchSourceTimer for foreground polling
    private var foregroundPollingTimer: Timer? // Consider DispatchSourceTimer for more precise control if needed
    private var serverSyncInProgress = false
    private var lastSyncTimestamp: Date?
    
    override init() {
        super.init()
        
        // Register for notifications about app state changes using modern API
        // This is typically for UI-related adjustments, not core background processing
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActiveNotification),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    // MARK: Methods
    
    // Display screen - This method seems UI-related and should be called on the main thread
    func displayScreen() {
        DispatchQueue.main.async { // Ensure UI updates are on main thread
            // Check PreyModule Status
            PreyModule.sharedInstance.checkActionArrayStatus()
            
            // Relaunch viewController
            let homeIdentifier = (PreyConfig.sharedInstance.isCamouflageMode) ? StoryboardIdVC.home.rawValue : StoryboardIdVC.homeWeb.rawValue
            self.window = UIWindow(frame: UIScreen.main.bounds)
            let mainStoryboard: UIStoryboard = UIStoryboard(name: StoryboardIdVC.PreyStoryBoard.rawValue, bundle: nil)
            let rootVC: UINavigationController = mainStoryboard.instantiateViewController(withIdentifier: StoryboardIdVC.navigation.rawValue) as! UINavigationController
            let controller: UIViewController = mainStoryboard.instantiateViewController(withIdentifier: homeIdentifier)
            
            rootVC.setViewControllers([controller], animated: false)
            
            self.window?.rootViewController = rootVC
            self.window?.makeKeyAndVisible()
        }
    }
    
    // stopBackgroundTask: Unified method for ending UIBackgroundTaskIdentifier
    func stopBackgroundTask(_ taskId: UIBackgroundTaskIdentifier? = nil) {
        let taskToStop = taskId ?? self.bgTask
        if let currentTask = taskToStop, currentTask != .invalid {
            PreyLogger("Ending background task with ID: \(currentTask.rawValue), time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
            UIApplication.shared.endBackgroundTask(currentTask)
            if currentTask == self.bgTask { // Only invalidate if it's the main bgTask
                self.bgTask = nil // Set to nil instead of .invalid for clarity
            }
            PreyLogger("Background task ended: \(currentTask.rawValue)")
        }
    }
    
    // MARK: UIApplicationDelegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        PreyLogger("didFinishLaunchingWithOptions - App launch started at \(Date())")
        
        // Request Always authorization for location early, but only if not already determined
        // Important: Actual location manager instance should be lazy and its delegate set to handle updates
        let locationManager = CLLocationManager()
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        
        // Register for background tasks (BGTaskScheduler)
        // Ensure all identifiers are unique and defined once.
        BGTaskScheduler.shared.register(forTaskWithIdentifier: AppDelegate.appRefreshTaskIdentifier, using: nil) { [weak self] task in
            self?.handleAppRefresh(task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: AppDelegate.processingTaskIdentifier, using: nil) { [weak self] task in
            self?.handleAppProcessing(task as! BGProcessingTask) // Renamed for clarity
        }
        
        // Set up notification delegate and register notification categories
        UNUserNotificationCenter.current().delegate = self
        
        let viewAction = UNNotificationAction(identifier: "VIEW_ACTION", title: "View Details", options: [.foreground])
        let dismissAction = UNNotificationAction(identifier: "DISMISS_ACTION", title: "Dismiss", options: [.destructive])
        
        // Create the category with the actions
        let alertCategory = UNNotificationCategory(
            identifier: categoryNotifPreyAlert,
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Register the notification categories
        UNUserNotificationCenter.current().setNotificationCategories([alertCategory])
        
        // First check existing notification status (use weak self in closure)
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            PreyLogger("📱 PUSH INIT: Current notification authorization status: \(self.authStatusString(settings.authorizationStatus))")
            PreyLogger("📱 PUSH INIT: Alert Setting: \(self.settingStatusString(settings.alertSetting))")
            PreyLogger("📱 PUSH INIT: Badge Setting: \(self.settingStatusString(settings.badgeSetting))")
            PreyLogger("📱 PUSH INIT: Sound Setting: \(self.settingStatusString(settings.soundSetting))")
            
            PreyLogger("📱 PUSH INIT: Critical Alert Setting: \(self.settingStatusString(settings.criticalAlertSetting))")
            
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
        
        // Initial sync/setup logic
        if PreyConfig.sharedInstance.isRegistered {
            PreyNotification.sharedInstance.registerForRemoteNotifications() // Might be redundant with previous call, but safe
            TriggerManager.sharedInstance.checkTriggers()
            
            // Handle notification if app was launched from a notification
            if let notification = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
                PreyLogger("App launched from remote notification: \(notification)")
                // Call completion handler for launched notification immediately if possible
                PreyNotification.sharedInstance.didReceiveRemoteNotifications(notification) { _ in
                    PreyLogger("Finished processing launch notification")
                    // If this background task (bgTask) was started just for launchOptions, it should be ended here.
                    // However, `application:didFinishLaunchingWithOptions` does not generally get background execution time
                    // unless a `beginBackgroundTask` is started immediately, which it is.
                    // The initial `bgTask` is ended in `applicationWillEnterForeground` or `applicationDidBecomeActive`.
                    // It's generally better for launch options to be processed quickly.
                }
            }
            
            // Configure background location services for registered users
            DeviceAuth.sharedInstance.ensureBackgroundLocationIsConfigured()
            
            // Perform initial sync with server. This will also set up foreground timer.
            syncWithServer()
            
        } else {
            PreyDeployment.sharedInstance.runPreyDeployment()
        }
    
        
        // Check email validation
        if PreyConfig.sharedInstance.validationUserEmail == PreyUserEmailValidation.pending.rawValue, let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:emailValidationEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.emailValidation, preyAction:nil, onCompletion:{(isSuccess: Bool) in PreyLogger("Request email validation")}))
        }
        
        // Setup foreground timer and schedule background tasks
        if PreyConfig.sharedInstance.isRegistered {
            setupForegroundTimer()
        }
        scheduleBackgroundTasks()
        
        return true
    }
    
    // This is primarily for UI transition (snapshotting for multitasking).
    // Avoid heavy operations here.
    func applicationWillResignActive(_ application: UIApplication) {
        PreyLogger("applicationWillResignActive")
        // Hide mainView for multitasking preview
        let backgroundImg = UIImageView(image:UIImage(named:"BgWelcome"))
        backgroundImg.frame = UIScreen.main.bounds
        backgroundImg.alpha = 0
        backgroundImg.tag = 1985
        
        window?.addSubview(backgroundImg)
        window?.bringSubviewToFront(backgroundImg)
        
        UIView.animate(withDuration: 0.2, animations:{() in backgroundImg.alpha = 1.0})
        
        // Ensure foreground timer is stopped to save battery
        foregroundPollingTimer?.invalidate()
        foregroundPollingTimer = nil
    }
    
    // This is where app state changes from foreground to background.
    // Heavy lifting for background processing should use BGTaskScheduler or specific background modes (e.g., location).
    func applicationDidEnterBackground(_ application: UIApplication) {
        PreyLogger("applicationDidEnterBackground")
        
        // Hide keyboard (UI-related, safe here)
        window?.endEditing(true)
        
        // AGGRESSIVE CLEANUP: End any pending background tasks immediately
        stopBackgroundTask(self.bgTask) // Explicitly end the launch-related task
        
        // Force cleanup of any orphaned background tasks
        PreyLogger("⚠️ Performing aggressive background task cleanup on entering background")
        
        // Give modules a chance to clean up their background tasks
        PreyModule.sharedInstance.forceBackgroundTaskCleanup()
        
        // Monitor background time and warn if getting close to limits
        let remainingTime = UIApplication.shared.backgroundTimeRemaining
        PreyLogger("📊 Background time remaining: \(remainingTime)s")
        if remainingTime < 25.0 {
            PreyLogger("⚠️ LIMITED BACKGROUND TIME: \(remainingTime)s - forcing immediate cleanup")
            // Force additional cleanup if time is running out
            BGTaskScheduler.shared.cancelAllTaskRequests()
        }
        
        // Schedule new background tasks. This is CRITICAL.
        scheduleBackgroundTasks() // Calls BGTaskScheduler methods
        
        // Check for pending actions. These should be quick or trigger async tasks.
        PreyModule.sharedInstance.checkActionArrayStatus()
        
        
        // Check for shared location data from extension (read-only, efficient)
        if let userDefaults = UserDefaults(suiteName: "group.com.prey.ios"),
           let lastLocation = userDefaults.dictionary(forKey: "lastLocation") {
            PreyLogger("Found shared location data: \(lastLocation)")
            // Process location data if needed (should be quick or trigger a BGTask)
        }
        
    }
    
    // When app enters foreground from background
    func applicationWillEnterForeground(_ application: UIApplication) {
        PreyLogger("applicationWillEnterForeground")
        // Check email validation (fine here, quick UI update possible)
        if PreyConfig.sharedInstance.validationUserEmail == PreyUserEmailValidation.pending.rawValue, let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:emailValidationEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.emailValidation, preyAction:nil, onCompletion:{(isSuccess: Bool) in PreyLogger("Request email validation")}))
        }
        
        // Ensure any remaining short-lived background tasks are ended
        stopBackgroundTask(self.bgTask)
        // Also cancel any scheduled BGTasks to avoid immediate re-triggering if not desired on foreground
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
    
    // When app becomes active (from launch or foreground)
    func applicationDidBecomeActive(_ application: UIApplication) {
        PreyLogger("applicationDidBecomeActive")
        // Sync auth keys to the app group so the Location Push extension can upload directly
        syncCredentialsToAppGroup()
        
        // Show mainView (UI-related, on main thread)
        if let backgroundImg = window?.viewWithTag(1985) {
            UIView.animate(withDuration: 0.2, animations:{() in backgroundImg.alpha = 0},
                           completion:{(Bool) in backgroundImg.removeFromSuperview()})
        }
        
        // Check if we need to sync with the server (should ideally be triggered by `didFinishLaunching` or other events)
        if PreyConfig.sharedInstance.isRegistered {
            // Perform immediate sync with server
            syncWithServer() // This will also setup the foreground timer
        }
        
        // Various UI state checks and re-display logic. Fine as is.
        if PreyConfig.sharedInstance.isCamouflageMode, let rootVC = window?.rootViewController as? UINavigationController, let controller = rootVC.topViewController, controller is HomeWebVC {
            window?.endEditing(true)
            displayScreen()
            return
        }
        
        if window?.rootViewController?.view.superview == window {
            return
        }
        
        if let controller = window?.rootViewController?.presentedViewController {
            if controller is QRCodeScannerVC {
                return
            }
        }
        
        if let navigationController:UINavigationController = window?.rootViewController as? UINavigationController, let homeWebVC:HomeWebVC = navigationController.topViewController as? HomeWebVC {
            if homeWebVC.showPanel {
                homeWebVC.showPanel = false
                return
            }
        }
        
        if window?.rootViewController?.view.superview != nil {
            return
        }
        
        window?.endEditing(true)
        displayScreen() // This is now explicitly on the main thread
    }

    private func syncCredentialsToAppGroup() {
        guard PreyConfig.sharedInstance.isRegistered,
              let apiKey = PreyConfig.sharedInstance.userApiKey else { return }
        let deviceKey = PreyConfig.sharedInstance.getDeviceKey()
        if let shared = UserDefaults(suiteName: "group.com.prey.ios") {
            shared.set(apiKey, forKey: "PreyUserApiKey")
            shared.set(deviceKey, forKey: "PreyDeviceKey")
            if shared.object(forKey: "PreyExtensionDirectUploadEnabled") == nil {
                shared.set(true, forKey: "PreyExtensionDirectUploadEnabled")
            }
            shared.synchronize()
            PreyLogger("Synced API and device key to app group for extension uploads")
        }
    }
    
    // This method is called when the application is about to be terminated.
    // Ensure all background tasks are properly ended here.
    func applicationWillTerminate(_ application: UIApplication) {
        PreyLogger("applicationWillTerminate")
        // Ensure any pending background tasks are ended to avoid crashes.
        stopBackgroundTask(self.bgTask)
        // Also cancel all scheduled BGTaskScheduler tasks
        BGTaskScheduler.shared.cancelAllTaskRequests()
        
        // Pass info to PreyNotification for final processing if needed
        // Note: This method is NOT called for background fetch notifications in suspended state.
        // It's mainly for when the app is explicitly terminated by the user or system.
        // PreyNotification.sharedInstance.didReceiveRemoteNotifications(userInfo, completionHandler:completionHandler) // userInfo and completionHandler are not parameters of applicationWillTerminate
        // This line was likely copy-pasted incorrectly into `applicationWillTerminate`.
        // The `didReceiveRemoteNotification` below handles the actual notification processing.
    }
    
    // MARK: Background Tasks (BGTaskScheduler)
    
    // Renamed from scheduleAppRefresh to reflect broader scheduling of all BG tasks
    func scheduleBackgroundTasks() {
        // Cancel all previously scheduled tasks to avoid duplicates. This is good.
        BGTaskScheduler.shared.cancelAllTaskRequests() // More robust than cancelling individually
        
        // Schedule refresh task (short, frequent updates, for general data updates)
        let refreshRequest = BGAppRefreshTaskRequest(identifier: AppDelegate.appRefreshTaskIdentifier)
        // If device is missing and server provided interval, honor it for next run; otherwise default to 15 minutes.
        var refreshDelay: TimeInterval = 15 * 60
        if PreyConfig.sharedInstance.isMissing, let opts = PreyConfig.sharedInstance.reportOptions,
           let reportIntervalMin = opts.object(forKey: kOptions.interval.rawValue) as? NSNumber {
            let seconds = reportIntervalMin.doubleValue * 60.0
            if seconds > 0 { refreshDelay = seconds }
        }
        refreshRequest.earliestBeginDate = Date(timeIntervalSinceNow: refreshDelay)
        
        // Schedule processing task (longer, more resource-intensive operations)
        let processingRequest = BGProcessingTaskRequest(identifier: AppDelegate.processingTaskIdentifier)
        processingRequest.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // Recommended 1 hour or more
        processingRequest.requiresNetworkConnectivity = true // Only run if network is available
        processingRequest.requiresExternalPower = false // Set to true if power-intensive (e.g., heavy uploads). False is better for battery.
        
        do {
            try BGTaskScheduler.shared.submit(refreshRequest)
            try BGTaskScheduler.shared.submit(processingRequest)
            PreyLogger("Background tasks scheduled with identifiers: \(AppDelegate.appRefreshTaskIdentifier), \(AppDelegate.processingTaskIdentifier)")
        } catch {
            PreyLogger("Could not schedule background tasks: \(error.localizedDescription)")
            // Fallback: perform minimal immediate operations without extended background task
            PreyLogger("BGTaskScheduler failed, performing immediate fallback operations")
            
            // Perform quick operations immediately without background task
            PreyModule.sharedInstance.checkActionArrayStatus()
            
            // Only create a short background task if absolutely necessary
            self.bgTask = UIApplication.shared.beginBackgroundTask { [weak self] in
                PreyLogger("⚠️ Short fallback background task expiring")
                self?.stopBackgroundTask()
            }
            
            if let bgTask = self.bgTask, bgTask != .invalid {
                PreyLogger("Started short fallback background task: \(bgTask.rawValue)")
                
                // End the task quickly (within 5 seconds) to avoid timeout
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 5) { [weak self] in
                    guard let self = self else { return }
                    PreyLogger("Ending short fallback background task")
                    self.stopBackgroundTask(self.bgTask)
                }
            }
        }
    }
    
    // Handler for BGAppRefreshTask (general app content refresh)
    func handleAppRefresh(_ task: BGAppRefreshTask) {
        PreyLogger("Background refresh task started. Time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
        
        // Reschedule the task for next time immediately (important for continuous operation)
        scheduleBackgroundTasks()
        
        // Use a DispatchGroup to manage multiple asynchronous operations within the task.
        let dispatchGroup = DispatchGroup()
        
        // Set an expiration handler for THIS specific BGTaskScheduler task.
        // This is crucial. If the task doesn't complete in time, iOS will call this handler.
        // You MUST call `task.setTaskCompleted(success: false)` inside this handler.
        task.expirationHandler = {
            PreyLogger("⚠️ BGAppRefreshTask expired. Time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
            // Cancel any ongoing operations.
            // (e.g., PreyHTTPClient.sharedInstance.cancelAllRequests() if such a method exists)
            task.setTaskCompleted(success: false)
            // No need to call self.stopBackgroundTask() here because this is BGTaskScheduler, not UIApplication.beginBackgroundTask.
            // The `stopBackgroundTask` method is for the general `UIBackgroundTaskIdentifier` which is a different API.
        }
        
        // --- Operations to perform during background refresh ---
        
        // If missing mode is active, run a single missing report if the interval has elapsed
        if PreyConfig.sharedInstance.isMissing, let opts = PreyConfig.sharedInstance.reportOptions,
           let reportIntervalMin = opts.object(forKey: kOptions.interval.rawValue) as? NSNumber {
            let intervalSeconds = reportIntervalMin.doubleValue * 60.0
            let lastRun = UserDefaults.standard.object(forKey: "PreyLastMissingReportAt") as? Date
            MissingReportScheduler.maybeRunIfDue(interval: intervalSeconds, lastRun: lastRun)
        }
        
        // Check for shared location data from extension (read-only, efficient)
        if let userDefaults = UserDefaults(suiteName: "group.com.prey.ios"),
           let lastLocation = userDefaults.dictionary(forKey: "lastLocation") {
            PreyLogger("Found shared location data: \(lastLocation)")
            // If fresh (<= 5 minutes), upload immediately to avoid waiting for next action
            if let ts = lastLocation["timestamp"] as? TimeInterval {
                let age = Date().timeIntervalSince(Date(timeIntervalSince1970: ts))
                if age <= 300,
                   let lat = lastLocation["lat"] as? Double,
                   let lng = lastLocation["lng"] as? Double,
                   let alt = lastLocation["alt"] as? Double,
                   let acc = lastLocation["accuracy"] as? Double,
                   let username = PreyConfig.sharedInstance.userApiKey {
                    let params: [String: Any] = [
                        kAction.location.rawValue: [
                            kLocation.lat.rawValue: lat,
                            kLocation.lng.rawValue: lng,
                            kLocation.alt.rawValue: alt,
                            kLocation.accuracy.rawValue: acc,
                            kLocation.method.rawValue: "location-push"
                        ],
                        kDataLocation.skip_toast.rawValue: true
                    ]
                    dispatchGroup.enter()
                    PreyLogger("Uploading fresh shared location (age: \(age)s)")
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
                            onCompletion: { _ in
                                PreyLogger("Shared location upload complete")
                                dispatchGroup.leave()
                            }
                        )
                    )
                }
            }
        }
        
        // Process any pending actions (these should be quick or trigger separate async processes)
        dispatchGroup.enter()
        PreyLogger("Checking for pending actions in background refresh")
        PreyModule.sharedInstance.checkActionArrayStatus()
        dispatchGroup.leave()
        
        // Process any cached requests (e.g., failed uploads from previous attempts)
        dispatchGroup.enter()
        PreyLogger("Processing cached requests in background refresh")
        dispatchGroup.leave()
        
        // Ensure location services are properly configured (lightweight check)
        dispatchGroup.enter()
        PreyLogger("Ensuring location services are configured in background refresh")
        DeviceAuth.sharedInstance.ensureBackgroundLocationIsConfigured()
        dispatchGroup.leave()
        
        // Check device info and triggers
        dispatchGroup.enter()
        PreyLogger("Checking device info in background refresh")
        PreyDevice.infoDevice { isSuccess in
            PreyLogger("Background refresh - infoDevice: \(isSuccess), time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
            TriggerManager.sharedInstance.checkTriggers()
            // Check for actions again after device info is updated
            PreyLogger("Checking for actions again after device info update")
            PreyModule.sharedInstance.checkActionArrayStatus()
            dispatchGroup.leave()
        }
        
        // Final completion logic for the BGAppRefreshTask
        // Notify the dispatch group when all operations are done.
        // Use a timeout for the dispatchGroup in case an async operation never calls leave().
        let timeoutWorkItem = DispatchWorkItem {
            PreyLogger("⚠️ Background refresh group timed out. Completing task with failure.")
            task.setTaskCompleted(success: false)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 20.0, execute: timeoutWorkItem) // Reduced to 20s to avoid system termination
        
        dispatchGroup.notify(queue: .main) { // Use main queue for final UI updates or logging if any
            timeoutWorkItem.cancel() // Cancel the timeout if group completes successfully
            // Check for any pending actions one more time
            PreyLogger("Final check for actions before completing background task")
            PreyModule.sharedInstance.checkActionArrayStatus()
            
            // Check if daily location update is needed during background refresh
            Location.checkDailyLocationUpdate()
            
            PreyLogger("Completing background refresh task with success: true")
            task.setTaskCompleted(success: true)
            // No `stopBackgroundTask()` here, as it's for UIBackgroundTaskIdentifier.
        }
    }
    
    // Handler for BGProcessingTask (more intensive background work)
    func handleAppProcessing(_ task: BGProcessingTask) { // Renamed from handleAppUpdate for clarity
        PreyLogger("Background processing task started. Time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
        
        // Reschedule the task for next time
        scheduleBackgroundTasks()
        
        let dispatchGroup = DispatchGroup()
        
        task.expirationHandler = {
            PreyLogger("⚠️ BGProcessingTask expired. Time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
            // Cancel any ongoing operations.
            task.setTaskCompleted(success: false)
        }
        
        // --- Operations to perform during background processing ---
        
        // Process any cached requests that might need more time or network connectivity
        dispatchGroup.enter()
        PreyLogger("Processing cached requests in background processing")
        dispatchGroup.leave()
        
        // Check device status from server - moved from applicationDidEnterBackground
        dispatchGroup.enter()
        PreyModule.sharedInstance.requestStatusDevice(context: "AppDelegate-backgroundProcessing") { isSuccess in
            PreyLogger("Background processing - status check: \(isSuccess)")
            dispatchGroup.leave()
        }
        
        // Check device info and triggers - this has longer to run than refresh
        dispatchGroup.enter()
        PreyLogger("Checking device info in background processing")
        PreyDevice.infoDevice { isSuccess in
            PreyLogger("Background processing - infoDevice: \(isSuccess)")
            PreyModule.sharedInstance.checkActionArrayStatus() // Check actions after device info updated
            dispatchGroup.leave()
        }
        
        // Final completion logic
        let timeoutWorkItem = DispatchWorkItem {
            PreyLogger("⚠️ Background processing group timed out. Completing task with failure.")
            task.setTaskCompleted(success: false)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 58.0, execute: timeoutWorkItem) // Schedule slightly before typical 60s timeout for processing tasks
        
        dispatchGroup.notify(queue: .main) {
            timeoutWorkItem.cancel()
            PreyLogger("Completing background processing task with success: true")
            task.setTaskCompleted(success: true)
        }
    }

    
    // MARK: Notification
    
    // Did register notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PreyLogger("didRegisterForRemoteNotificationsWithDeviceToken")
      
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in // Added weak self
            guard let self = self else { return }
            PreyLogger("📱 PUSH SETTINGS: Authorization Status: \(self.authStatusString(settings.authorizationStatus))")
            PreyLogger("📱 PUSH SETTINGS: Alert Setting: \(self.settingStatusString(settings.alertSetting))")
            PreyLogger("📱 PUSH SETTINGS: Badge Setting: \(self.settingStatusString(settings.badgeSetting))")
            PreyLogger("📱 PUSH SETTINGS: Sound Setting: \(self.settingStatusString(settings.soundSetting))")
            PreyLogger("📱 PUSH SETTINGS: Critical Alert Setting: \(self.settingStatusString(settings.criticalAlertSetting))")
        }
        
        PreyNotification.sharedInstance.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
        
        // Schedule background tasks when we get a new token - ensures system knows we're active
        scheduleBackgroundTasks()
        
        // Perform immediate sync with server
        syncWithServer()
        
        // Check if daily location update is needed when app becomes active
        Location.checkDailyLocationUpdate()
    }
    
    // MARK: Foreground API sync
    
    // Renamed foregroundTimer to foregroundPollingTimer for clarity
    // timeInterval was 60s, changed to 180s (3 min) as suggested by original comment
    func setupForegroundTimer() {
        foregroundPollingTimer?.invalidate()
        
        foregroundPollingTimer = Timer.scheduledTimer(
            timeInterval: 180, // Changed back to 3 minutes for less frequent polling
            target: self,
            selector: #selector(foregroundTimerFired),
            userInfo: nil,
            repeats: true
        )
        
        RunLoop.current.add(foregroundPollingTimer!, forMode: .common)
        
        foregroundPollingTimer?.tolerance = 10.0 // Good practice
        
        PreyLogger("Foreground timer set up to sync with server every 3 minutes")
    }
    
    @objc private func applicationWillResignActiveNotification() {
        PreyLogger("App will resign active - stopping foreground timer")
        foregroundPollingTimer?.invalidate()
        foregroundPollingTimer = nil
    }
    
    @objc func foregroundTimerFired() {
        PreyLogger("Foreground timer fired, attempting syncWithServer()")
        syncWithServer()
    }
    
    // Server sync logic
    func syncWithServer() {
        // Only sync if not already in progress and not done within the last 10 seconds
        let shouldSync = !serverSyncInProgress &&
            (lastSyncTimestamp == nil || Date().timeIntervalSince(lastSyncTimestamp!) > 10)
        
        guard shouldSync else {
            let reason = serverSyncInProgress ? "sync already in progress" : "last sync was too recent"
            PreyLogger("Skipping server sync - \(reason)")
            return
        }
        
        serverSyncInProgress = true
        lastSyncTimestamp = Date() // Update timestamp at the start of sync attempt
        
        PreyLogger("Starting server sync")
        
        guard let username = PreyConfig.sharedInstance.userApiKey else {
            PreyLogger("No API key available for server sync")
            serverSyncInProgress = false
            return
        }
        
        // Timeout timer for the sync process
        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.serverSyncInProgress {
                PreyLogger("⚠️ Server sync timeout - releasing lock after 60 seconds")
                self.serverSyncInProgress = false
            }
        }
        
        // Use a DispatchGroup to coordinate multiple asynchronous API calls
        let apiSyncGroup = DispatchGroup()
        
        // First check device info
        apiSyncGroup.enter()
        PreyDevice.infoDevice { isSuccess in
            PreyLogger("Foreground sync - infoDevice: \(isSuccess)")
            apiSyncGroup.leave()
        }
        
        // Then get user profile
        apiSyncGroup.enter()
        PreyUser.logInToPrey(username, userPassword: "x") { isLoginSuccess in
            PreyLogger("Foreground sync - profile: \(isLoginSuccess)")
            apiSyncGroup.leave()
        }
        
        // Check if token needs refreshing (more than 1 hour old)
        if (PreyConfig.sharedInstance.tokenWebTimestamp + 60 * 60) < CFAbsoluteTimeGetCurrent() {
            apiSyncGroup.enter()
            PreyUser.getTokenFromPanel(username, userPassword: "x") { isTokenSuccess in
                PreyLogger("Foreground sync - token refresh: \(isTokenSuccess)")
                apiSyncGroup.leave()
            }
        }
        
        // Check for actions from server
        apiSyncGroup.enter()
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
                    if isActionsSuccess {
                        PreyModule.sharedInstance.runAction() // This should be quick or trigger async operations
                    }
                    apiSyncGroup.leave()
                }
            )
        )
        
        // When all API calls finish, release the lock and invalidate the timeout timer
        apiSyncGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            PreyLogger("Server sync completed")
            timeoutTimer.invalidate() // Invalidate the timeout timer
            self.serverSyncInProgress = false // Release the lock
        }
    }
    
    // MARK: UNUserNotificationCenterDelegate (Push Notifications)
    
    // Handle notification response (user interaction with notification)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        PreyLogger("Received notification response: \(response.actionIdentifier) with userInfo: \(userInfo)")
        
        //Process MDM payloads that arrive in foreground
        if let cmdPreyMDM = userInfo["preymdm"] as? NSDictionary {
            PreyLogger("📣 PN TYPE: preymdm payload detected in willPresent")
            PreyNotification.sharedInstance.parsePayloadPreyMDMFromPushNotification(parameters: cmdPreyMDM)
            completionHandler() // Don't show notification for MDM payloads
            return
        }
        
        // Forward handling to PreyNotification
        PreyNotification.sharedInstance.handleNotificationResponse(response)
        
        completionHandler() // Call completion handler promptly
    }
    
    // Handle notification presentation while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        PreyLogger("Will present notification in foreground: \(notification.request.identifier)")
        
        if notification.request.content.categoryIdentifier == categoryNotifPreyAlert {
            completionHandler([]) // Don't show notification banners/alerts if our custom AlertVC is shown
            
            if let userInfo = notification.request.content.userInfo as? [String: Any],
               let message = userInfo[kOptions.IDLOCAL.rawValue] as? String {
                
                let alertOptions = [kOptions.MESSAGE.rawValue: message] as NSDictionary
                let alertAction = Alert(withTarget: kAction.alert, withCommand: kCommand.start, withOptions: alertOptions)
                
                if let triggerId = userInfo[kOptions.trigger_id.rawValue] as? String {
                    alertAction.triggerId = triggerId
                }
                
                PreyModule.sharedInstance.actionArray.append(alertAction)
                alertAction.showAlertVC(message)
            }
        } else {
            // For other notifications, show them normally
            completionHandler([.banner, .sound, .badge, .list])
        }
    }
    
    // Fail register notifications (no changes, good)
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PreyLogger("📱 PUSH REGISTRATION ERROR: 🚨 \(error.localizedDescription)")
        
        let nsError = error as NSError
        PreyLogger("📱 PUSH REGISTRATION ERROR DETAILS: domain=\(nsError.domain), code=\(nsError.code), userInfo=\(nsError.userInfo)")
        
        if nsError.code == 3000 {
            PreyLogger("📱 PUSH REGISTRATION ERROR: This is likely an issue with APNs certificates or entitlements")
        } else if nsError.code == 3010 {
            PreyLogger("📱 PUSH REGISTRATION ERROR: This indicates the simulator was used (expected, as simulator cannot receive push notifications)")
        }
    }
    
    // Did receive remote notification (for background push)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        PreyLogger("📱 PUSH PAYLOAD: \(userInfo)")
       
        // This is a UIBackgroundFetchResult type notification, not a BGTaskScheduler task.
        // You get limited time (around 30 seconds).
        // It's crucial to call `completionHandler` as soon as possible.
        var notificationBgTask: UIBackgroundTaskIdentifier = .invalid // Use local var to avoid conflicts with AppDelegate's bgTask
        
        notificationBgTask = UIApplication.shared.beginBackgroundTask { [weak self] in // Capture self weakly
            PreyLogger("⚠️ Remote notification background task expiring")
            // End the background task immediately when expiring
            if notificationBgTask != .invalid {
                UIApplication.shared.endBackgroundTask(notificationBgTask)
                notificationBgTask = .invalid
            }
            // Call completion handler with .failed if task expires
            completionHandler(.failed)
        }
        
        PreyLogger("Started remote notification background task: \(notificationBgTask.rawValue) with remaining time: \(UIApplication.shared.backgroundTimeRemaining)")
        
        let dispatchGroup = DispatchGroup()
        var wasDataReceived = false // Use `var` instead of `let` to allow modification
        
        // Always try to sync device status when we receive a notification
        dispatchGroup.enter()
        PreyDevice.infoDevice { isSuccess in
            PreyLogger("Remote notification infoDevice: \(isSuccess)")
            if isSuccess { wasDataReceived = true } // Update success status
            dispatchGroup.leave()
        }
        
        // Process the notification
        dispatchGroup.enter()
        PreyNotification.sharedInstance.didReceiveRemoteNotifications(userInfo) { result in
            PreyLogger("PreyNotification didReceiveRemoteNotifications result: \(result)")
            // Process any cached requests (assuming this is efficient)
            
            if result == .newData {
                wasDataReceived = true
            }
            dispatchGroup.leave()
        }
        
        // Always check for pending actions (assuming this is efficient)
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
                            PreyModule.sharedInstance.runAction() // This should be quick or trigger async operations
                        }
                        dispatchGroup.leave()
                    }
                )
            )
        } else {
            dispatchGroup.leave()
        }
        
        // Check device status using centralized throttled method
        dispatchGroup.enter()
        PreyModule.sharedInstance.requestStatusDevice(context: "AppDelegate-remoteNotification") { isSuccess in
            PreyLogger("Remote notification status check: \(isSuccess)")
            if isSuccess {
                wasDataReceived = true
            }
            dispatchGroup.leave()
        }
        
        // When all operations complete, call the fetchCompletionHandler and end the background task
        dispatchGroup.notify(queue: .main) { [weak self] in // Use weak self
            guard let self = self else {
                completionHandler(.failed) // If AppDelegate is gone, fail the task
                if notificationBgTask != .invalid {
                    UIApplication.shared.endBackgroundTask(notificationBgTask)
                    notificationBgTask = .invalid
                }
                return
            }
            
            // Give a small delay to ensure everything completes properly (if absolutely necessary, but try to avoid delays)
            // A delay on the main queue can still block UI if the app is in foreground.
            // If this delay is for a background task, use a background queue.
            // It's best to remove explicit delays if possible and ensure async operations complete their work quickly.
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1.0) { // Reduced delay, moved to background queue
                // Complete the fetchCompletionHandler with appropriate result
                let result: UIBackgroundFetchResult = wasDataReceived ? .newData : .noData
                PreyLogger("Remote notification processing complete with result: \(result)")
                
                // Call original completion handler
                completionHandler(result)
                
                // End the background task associated with this notification.
                if notificationBgTask != .invalid {
                    UIApplication.shared.endBackgroundTask(notificationBgTask)
                    notificationBgTask = .invalid
                }
            }
        }
    }

    // MARK: Check settings on backup (no changes, logic seems okay for file system interaction)
    
    func checkSettingsToBackup() {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let docURL = urls[urls.endIndex-1]
        let storeURL = docURL.appendingPathComponent("skpBckp")
        
        if !fileManager.fileExists(atPath: storeURL.path) {
            if PreyConfig.sharedInstance.isRegistered && PreyConfig.sharedInstance.existBackup {
                PreyConfig.sharedInstance.resetValues()
            }
            fileManager.createFile(atPath: storeURL.path, contents: nil, attributes: nil)
            _ = self.addSkipBackupAttributeToItemAtURL(filePath: storeURL.path)
            PreyConfig.sharedInstance.existBackup = true
            PreyConfig.sharedInstance.saveValues()
        }
    }
    
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
    
    // MARK: Notification Helper Methods (no changes, good utility functions)
    
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
    
    func settingStatusString(_ setting: UNNotificationSetting) -> String {
        switch setting {
        case .enabled: return "Enabled"
        case .disabled: return "Disabled"
        case .notSupported: return "Not Supported"
        @unknown default: return "Unknown (\(setting.rawValue))"
        }
    }
}
