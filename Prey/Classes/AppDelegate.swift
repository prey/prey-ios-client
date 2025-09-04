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
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, CLLocationManagerDelegate {
    
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
    private var locationPushManager: CLLocationManager?
    private var hasStartedLocationPushMonitoring = false
    private var locationPushRetryCount = 0
    private let lastKnownVersionKey = "lastKnownAppVersion"
    private let lastKnownBuildKey = "lastKnownAppBuild"
    
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
        // Install crash/exception handlers as early as possible
        CrashHandler.install()
        
        PreyLogger("didFinishLaunchingWithOptions - App launch started at \(Date())")

        // Prepare Location Push manager early and request Always authorization if needed
        if locationPushManager == nil { locationPushManager = CLLocationManager() }
        locationPushManager?.delegate = self
        let initialAuth = locationPushManager?.authorizationStatus ?? .notDetermined
        if initialAuth == .notDetermined {
            // iOS requires asking for WhenInUse first, then upgrade to Always later
            locationPushManager?.requestWhenInUseAuthorization()
        } else if initialAuth == .authorizedAlways {
            // If already authorized, start monitoring immediately
            startMonitoringLocationPushes()
        }
        
        // Register for background tasks (BGTaskScheduler)
        // Ensure all identifiers are unique and defined once.
        BGTaskScheduler.shared.register(forTaskWithIdentifier: AppDelegate.appRefreshTaskIdentifier, using: nil) { [weak self] task in
            self?.handleAppRefresh(task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: AppDelegate.processingTaskIdentifier, using: nil) { [weak self] task in
            self?.handleAppProcessing(task as! BGProcessingTask) // Renamed for clarity
        }
        
        // Set up notification delegate and register categories
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
        
        // Check existing notification status and register for remote notifications
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

        #if DEBUG
        // Integration test hooks (enable via Scheme Environment Variables)
        if ProcessInfo.processInfo.environment["PREY_FORCE_CRASH"] == "1" {
            PreyLogger("[CrashTest] Forcing a crash in 2s to test CrashHandler (SIGABRT)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { CrashHandler.forceCrashForTesting() }
        }
        if ProcessInfo.processInfo.environment["PREY_FORCE_EXCEPTION"] == "1" {
            PreyLogger("[CrashTest] Forcing an NSException in 2s to test CrashHandler (NSException)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                NSException(name: .invalidArgumentException, reason: "Forced test exception", userInfo: nil).raise()
            }
        }
        #endif

        // Start centralized LocationService early; DeviceAuth will bridge updates
        LocationService.shared.addDelegate(DeviceAuth.sharedInstance)
        LocationService.shared.startBackgroundTracking()
        
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
            TriggerManager.sharedInstance.checkTriggers()
            // Sync device name if it changed
            PreyModule.sharedInstance.syncDeviceNameIfChanged()
            
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
            PreyHTTPClient.sharedInstance.sendDataToPrey(username, password:"x", params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:emailValidationEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.emailValidation, preyAction:nil, onCompletion:{(isSuccess: Bool) in PreyLogger("Request email validation")}))
        }
        
        // Setup foreground timer and schedule background tasks
        if PreyConfig.sharedInstance.isRegistered {
            setupForegroundTimer()
        }
        scheduleBackgroundTasks()

        // Detect app upgrade and trigger a consolidated sync
        detectUpgradeAndSync()

        // Upload any pending crash/exception reports from previous runs (no auth required)
        CrashHandler.uploadPendingReportsIfPossible()
        
        return true
        }

        // UI transition (snapshotting for multitasking)
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

    private func detectUpgradeAndSync() {
        let defaults = UserDefaults.standard
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        let lastVersion = defaults.string(forKey: lastKnownVersionKey)
        let lastBuild = defaults.string(forKey: lastKnownBuildKey)

        let isFirstLaunch = (lastVersion == nil || lastBuild == nil)
        let upgraded = (!isFirstLaunch) && (lastVersion != currentVersion || lastBuild != currentBuild)

        // Persist current values
        defaults.set(currentVersion, forKey: lastKnownVersionKey)
        defaults.set(currentBuild, forKey: lastKnownBuildKey)

        if upgraded {
            PreyLogger("Detected app upgrade from v\(lastVersion ?? "?") (\(lastBuild ?? "?")) to v\(currentVersion) (\(currentBuild)) — triggering sync")
            SyncCoordinator.performPostAuthOrUpgradeSync(reason: .appUpgrade)
        }
    }
    
    // This is where app state changes from foreground to background.
    // Heavy lifting for background processing should use BGTaskScheduler or specific background modes (e.g., location).
    func applicationDidEnterBackground(_ application: UIApplication) {
        PreyLogger("applicationDidEnterBackground")
        
        // Hide keyboard (UI-related, safe here)
        window?.endEditing(true)
        
        // End any pending background tasks immediately
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
        
        // Schedule background tasks
        scheduleBackgroundTasks()
        
        // Check for pending actions. These should be quick or trigger async tasks.
        PreyModule.sharedInstance.checkActionArrayStatus()
        
        
        // Check for shared location data from extension (read-only, efficient)
        if let userDefaults = UserDefaults(suiteName: "group.com.prey.ios"),
           let lastLocation = userDefaults.dictionary(forKey: "lastLocation") {
            PreyLogger("Found shared location data: \(lastLocation)")
            // Process location data if needed (should be quick or trigger a BGTask)
        }
        
    }
    
        // Foreground entry
        func applicationWillEnterForeground(_ application: UIApplication) {
        PreyLogger("applicationWillEnterForeground")
        // Check email validation (fine here, quick UI update possible)
        if PreyConfig.sharedInstance.validationUserEmail == PreyUserEmailValidation.pending.rawValue, let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.sendDataToPrey(username, password:"x", params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:emailValidationEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.emailValidation, preyAction:nil, onCompletion:{(isSuccess: Bool) in PreyLogger("Request email validation")}))
        }
        
        // Ensure any remaining short-lived background tasks are ended
        stopBackgroundTask(self.bgTask)
        // Also cancel any scheduled BGTasks to avoid immediate re-triggering if not desired on foreground
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
    
        // App became active
        func applicationDidBecomeActive(_ application: UIApplication) {
        PreyLogger("applicationDidBecomeActive")
        
        // Show mainView (UI-related, on main thread)
        if let backgroundImg = window?.viewWithTag(1985) {
            UIView.animate(withDuration: 0.2, animations:{() in backgroundImg.alpha = 0},
                           completion:{(Bool) in backgroundImg.removeFromSuperview()})
        }
        
        // Sync if registered
        if PreyConfig.sharedInstance.isRegistered {
            // Perform immediate sync with server
            syncWithServer() // This will also setup the foreground timer
            // Sync device name if it changed
            PreyModule.sharedInstance.syncDeviceNameIfChanged()
        }
        
        // UI state checks and re-display logic
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
        displayScreen()
    }
    
    // App termination: end background tasks and cancel BG tasks
    func applicationWillTerminate(_ application: UIApplication) {
        PreyLogger("applicationWillTerminate")
        stopBackgroundTask(self.bgTask)
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
    
    // MARK: Background Tasks (BGTaskScheduler)
    
    func scheduleBackgroundTasks() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
        
        let refreshRequest = BGAppRefreshTaskRequest(identifier: AppDelegate.appRefreshTaskIdentifier)
        refreshRequest.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        let processingRequest = BGProcessingTaskRequest(identifier: AppDelegate.processingTaskIdentifier)
        processingRequest.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
        processingRequest.requiresNetworkConnectivity = true
        processingRequest.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(refreshRequest)
            try BGTaskScheduler.shared.submit(processingRequest)
            PreyLogger("Background tasks scheduled with identifiers: \(AppDelegate.appRefreshTaskIdentifier), \(AppDelegate.processingTaskIdentifier)")
        } catch {
            PreyLogger("Could not schedule background tasks: \(error.localizedDescription)")
            PreyLogger("BGTaskScheduler failed, performing fallback operations")
            PreyModule.sharedInstance.checkActionArrayStatus()
            
            self.bgTask = UIApplication.shared.beginBackgroundTask { [weak self] in
                PreyLogger("⚠️ Short fallback background task expiring")
                self?.stopBackgroundTask()
            }
            
            if let bgTask = self.bgTask, bgTask != .invalid {
                PreyLogger("Started short fallback background task: \(bgTask.rawValue)")
                
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 5) { [weak self] in
                    guard let self = self else { return }
                    PreyLogger("Ending short fallback background task")
                    self.stopBackgroundTask(self.bgTask)
                }
            }
        }
    }
    
    func handleAppRefresh(_ task: BGAppRefreshTask) {
        PreyLogger("Background refresh task started. Time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
        scheduleBackgroundTasks()
        let dispatchGroup = DispatchGroup()
        var didComplete = false
        func complete(_ success: Bool) {
            if didComplete { return }
            didComplete = true
            task.setTaskCompleted(success: success)
        }
        task.expirationHandler = {
            PreyLogger("⚠️ BGAppRefreshTask expired. Time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
            complete(false)
        }
        // Check for shared location data from extension (read-only, efficient)
        if let userDefaults = UserDefaults(suiteName: "group.com.prey.ios"),
           let lastLocation = userDefaults.dictionary(forKey: "lastLocation") {
            PreyLogger("Found shared location data: \(lastLocation)")
        }
        dispatchGroup.enter()
        PreyLogger("Checking for pending actions in background refresh")
        PreyModule.sharedInstance.checkActionArrayStatus()
        dispatchGroup.leave()
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
            complete(false)
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
            complete(true)
            // No `stopBackgroundTask()` here, as it's for UIBackgroundTaskIdentifier.
        }
    }
    
    // Handler for BGProcessingTask (more intensive background work)
    func handleAppProcessing(_ task: BGProcessingTask) {
        PreyLogger("Background processing task started. Time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
        
        // Reschedule the task for next time
        scheduleBackgroundTasks()
        
        let dispatchGroup = DispatchGroup()
        var didComplete = false
        func complete(_ success: Bool) {
            if didComplete { return }
            didComplete = true
            task.setTaskCompleted(success: success)
        }
        
        task.expirationHandler = {
            PreyLogger("⚠️ BGProcessingTask expired. Time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
            // Cancel any ongoing operations.
            complete(false)
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
            complete(false)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 58.0, execute: timeoutWorkItem) // Schedule slightly before typical 60s timeout for processing tasks
        
        dispatchGroup.notify(queue: .main) {
            timeoutWorkItem.cancel()
            PreyLogger("Completing background processing task with success: true")
            complete(true)
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
        
        // Ensure monitoring is active (deduped)
        startMonitoringLocationPushes()
        
        // Schedule background tasks when we get a new token - ensures system knows we're active
        scheduleBackgroundTasks()
        
        // Perform immediate sync with server
        syncWithServer()
        
        // Check if daily location update is needed when app becomes active
        Location.checkDailyLocationUpdate()
    }

    // MARK: Location Push Monitoring
    private func startMonitoringLocationPushes() {
        if locationPushManager == nil { locationPushManager = CLLocationManager() }
        guard let lm = locationPushManager else { return }
        lm.delegate = self

        // Avoid duplicate/overlapping registrations
        if hasStartedLocationPushMonitoring {
            PreyLogger("LOCATION-PUSH monitoring already started; skipping duplicate call")
            return
        }

        // Require Always authorization per Apple docs
        let auth = lm.authorizationStatus
        PreyLogger("LocationPush auth status: \(auth.rawValue)")
        if auth != .authorizedAlways {
            PreyLogger("LOCATION-PUSH requires Always authorization; requesting...")
            lm.requestAlwaysAuthorization()
            return
        }
        // Set flag before starting to prevent race conditions
        hasStartedLocationPushMonitoring = true
        
        lm.startMonitoringLocationPushes { registration, error in
            if let error = error {
                let nsErr = error as NSError
                PreyLogger("LOCATION-PUSH monitoring failed: domain=\(nsErr.domain) code=\(nsErr.code) desc=\(nsErr.localizedDescription)")
                // Reset flag on failure to allow retry
                self.hasStartedLocationPushMonitoring = false
                // Retry a few times with backoff in case it is transient
                if self.locationPushRetryCount < 3 {
                    let delay = Double((self.locationPushRetryCount + 1) * 5)
                    self.locationPushRetryCount += 1
                    PreyLogger("Scheduling LocationPush retry #\(self.locationPushRetryCount) in \(delay)s")
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.startMonitoringLocationPushes()
                    }
                }
                return
            }
            if let registration = registration {
                let tokenHex = registration.map { String(format: "%02x", $0) }.joined()
                PreyLogger("LOCATION-PUSH monitoring started (registration token: \(tokenHex))")
                // Persist token; we will send it after API key is available (post-auth)
                LocationPushRegistrar.store(tokenHex: tokenHex)
                // If API key already available (upgrade path), send immediately
                LocationPushRegistrar.sendIfPossible(source: "startMonitoringLocationPushes")
            } else {
                PreyLogger("LOCATION-PUSH monitoring started for topic .location-query")
            }
            // Flag already set before the call, so no need to set it again here
        }
    }
    
    // Retries when authorization changes to Always
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager === self.locationPushManager else { return }
        let status = manager.authorizationStatus
        PreyLogger("LocationPush auth changed: \(status.rawValue)")
        if status == .authorizedAlways {
            startMonitoringLocationPushes()
        }
    }
    
    // MARK: Foreground API sync
    
    // Renamed foregroundTimer to foregroundPollingTimer for clarity
    // timeInterval set to 180s (3 min)
    func setupForegroundTimer() {
        foregroundPollingTimer?.invalidate()
        
        foregroundPollingTimer = Timer.scheduledTimer(
            timeInterval: 180, // 3 minutes
            target: self,
            selector: #selector(foregroundTimerFired),
            userInfo: nil,
            repeats: true
        )
        
        RunLoop.current.add(foregroundPollingTimer!, forMode: .common)
        
        foregroundPollingTimer?.tolerance = 10.0 // 10 seconds
        
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
        PreyHTTPClient.sharedInstance.sendDataToPrey(
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
        
        // Ignore dismiss actions to avoid triggering 'action started' on swipe-to-clear
        let actionId = response.actionIdentifier
        if actionId == UNNotificationDismissActionIdentifier || actionId == "DISMISS_ACTION" {
            PreyLogger("Notification dismissed by user; no action will be triggered")
            completionHandler()
            return
        }

        // Only handle default tap or explicit view action
        if actionId == UNNotificationDefaultActionIdentifier || actionId == "VIEW_ACTION" {
            PreyNotification.sharedInstance.handleNotificationResponse(response)
        } else {
            PreyLogger("Unhandled notification action: \(actionId); ignoring")
        }

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
       
        // Background fetch with limited time; call completionHandler promptly
        var notificationBgTask: UIBackgroundTaskIdentifier = .invalid // Use local var to avoid conflicts with AppDelegate's bgTask
        var didCompleteFetch = false
        func completeFetch(_ result: UIBackgroundFetchResult) {
            // Ensure completionHandler and BG task end are called exactly once
            if didCompleteFetch { return }
            didCompleteFetch = true
            completionHandler(result)
            if notificationBgTask != .invalid {
                UIApplication.shared.endBackgroundTask(notificationBgTask)
                notificationBgTask = .invalid
            }
        }
        
        notificationBgTask = UIApplication.shared.beginBackgroundTask { [weak self] in // Capture self weakly
            PreyLogger("⚠️ Remote notification background task expiring")
            // End the background task immediately when expiring
            if notificationBgTask != .invalid {
                UIApplication.shared.endBackgroundTask(notificationBgTask)
                notificationBgTask = .invalid
            }
            // Call completion handler with .failed if task expires
            completeFetch(.failed)
        }
        
        PreyLogger("Started remote notification background task: \(notificationBgTask.rawValue) with remaining time: \(UIApplication.shared.backgroundTimeRemaining)")
        
        let dispatchGroup = DispatchGroup()
        var wasDataReceived = false // mutated only on main via our completions
        // Defensive guards to avoid dispatch_group_leave crashes if a completion fires twice
        var didLeaveInfo = false
        var didLeaveNotif = false
        var didLeaveActions = false
        var didLeaveStatus = false
        
        // Always try to sync device status when we receive a notification
        dispatchGroup.enter()
        PreyDevice.infoDevice { isSuccess in
            PreyLogger("Remote notification infoDevice: \(isSuccess)")
            if isSuccess { wasDataReceived = true }
            if !didLeaveInfo { didLeaveInfo = true; dispatchGroup.leave() }
        }
        
        // Process the notification
        dispatchGroup.enter()
        PreyNotification.sharedInstance.didReceiveRemoteNotifications(userInfo) { result in
            PreyLogger("PreyNotification didReceiveRemoteNotifications result: \(result)")
            // Process any cached requests (assuming this is efficient)
            
            if result == .newData {
                wasDataReceived = true
            }
            if !didLeaveNotif { didLeaveNotif = true; dispatchGroup.leave() }
        }
        
        // Always check for pending actions (assuming this is efficient)
        dispatchGroup.enter()
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.sendDataToPrey(
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
                        if !didLeaveActions { didLeaveActions = true; dispatchGroup.leave() }
                    }
                )
            )
        } else {
            if !didLeaveActions { didLeaveActions = true; dispatchGroup.leave() }
        }
        
        // Check device status using centralized throttled method
        dispatchGroup.enter()
        PreyModule.sharedInstance.requestStatusDevice(context: "AppDelegate-remoteNotification") { isSuccess in
            PreyLogger("Remote notification status check: \(isSuccess)")
            if isSuccess {
                wasDataReceived = true
            }
            if !didLeaveStatus { didLeaveStatus = true; dispatchGroup.leave() }
        }
        
        // When all operations complete, call the fetchCompletionHandler and end the background task
        dispatchGroup.notify(queue: .main) { [weak self] in // Use weak self
            guard let self = self else { completeFetch(.failed); return }
            
            // Give a small delay to ensure everything completes properly (if absolutely necessary, but try to avoid delays)
            // A delay on the main queue can still block UI if the app is in foreground.
            // If this delay is for a background task, use a background queue.
            // Keep delays minimal to avoid blocking
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1.0) { // Reduced delay, moved to background queue
                // Complete the fetchCompletionHandler with appropriate result
                let result: UIBackgroundFetchResult = wasDataReceived ? .newData : .noData
                PreyLogger("Remote notification processing complete with result: \(result)")
                completeFetch(result)
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
    // Bridge background URLSession completion handler to HTTP client (for report uploads etc.)
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        PreyLogger("handleEventsForBackgroundURLSession: \(identifier)")
        PreyHTTPClient.sharedInstance.registerBackgroundCompletionHandler(completionHandler)
    }
