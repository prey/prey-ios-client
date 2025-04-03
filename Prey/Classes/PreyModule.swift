//
//  PreyModule.swift
//  Prey
//
//  Created by Javier Cala Uribe on 5/05/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import UIKit

class PreyModule {
    
    // MARK: Properties
    
    static let sharedInstance = PreyModule()
    fileprivate init() {
    }
    
    var actionArray = [PreyAction] ()
    
    // MARK: Functions

    // Check actionArrayStatus
    func checkActionArrayStatus() {
        PreyLogger("Check actionArrayStatus - App State: \(UIApplication.shared.applicationState == .background ? "Background" : "Foreground")")
        
        // Always check for pending actions from server
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyLogger("Checking for pending actions from server")
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
                        PreyLogger("Request check status: \(isSuccess)") 
                    }
                )
            )
        }
        
        // If device is missing, add report action
        if PreyConfig.sharedInstance.isMissing {
            // Check actionArray
            if actionArray.isEmpty {
                // Add report action
                let reportAction = Report(withTarget: kAction.report, withCommand: kCommand.get, withOptions: PreyConfig.sharedInstance.reportOptions)
                actionArray.append(reportAction)
                PreyLogger("Added report action to action array")
            } else {
                PreyLogger("Action array already has \(actionArray.count) actions")
            }
            
            // Make sure actions are running
            runAction()
        } else {
            PreyLogger("Device is not missing, checking for location actions only")
            
            // Even if not missing, check for location actions
            var hasLocationAction = false
            for action in actionArray {
                if action.target == kAction.location {
                    hasLocationAction = true
                    break
                }
            }
            
            // If no location action exists, add one for background updates
            if !hasLocationAction && UIApplication.shared.applicationState == .background {
                let locationAction = Location(withTarget: kAction.location, withCommand: kCommand.get, withOptions: nil)
                actionArray.append(locationAction)
                PreyLogger("Added background location action")
                runAction()
            } else if !actionArray.isEmpty {
                // Run existing actions
                runAction()
            }
        }
    }
    
    // Parse actions from panel
    func parseActionsFromPanel(_ actionsStr:String) {

        PreyLogger("Parse actions from panel: \(actionsStr)")
        
        // Track whether we've added any critical actions that should always run
        var addedCriticalActions = false
        let criticalActions = [kAction.alert.rawValue, kAction.alarm.rawValue]
        
        // Convert actionsArray from String to NSData
        guard let jsonData: Data = actionsStr.data(using: String.Encoding.utf8) else {
            
            PreyLogger("Error converting actions array to data")
            PreyNotification.sharedInstance.handlePushError("Failed to parse actions from panel")
            
            return
        }
        
        // Convert NSData to NSArray
        let jsonObjects: NSArray
        
        do {
            jsonObjects = try JSONSerialization.jsonObject(with: jsonData, options:JSONSerialization.ReadingOptions.mutableContainers) as! NSArray
            
            // Add Actions in ActionArray
            for dict in jsonObjects {
                guard let actionDict = dict as? NSDictionary,
                      let targetName = actionDict.object(forKey: kInstruction.target.rawValue) as? String else {
                    continue
                }
                
                // If this is a critical action, mark that we should process it
                if criticalActions.contains(targetName) {
                    addedCriticalActions = true
                    PreyLogger("Critical action found: \(targetName)")
                }
                
                addAction(actionDict)
            }
            
            // Run actions
            if addedCriticalActions {
                PreyLogger("Critical actions added, running immediately...")
            }
            runAction()
            
            // Check ActionArray empty
            if actionArray.isEmpty {
                PreyLogger("All actions processed successfully")
                if let app = UIApplication.shared.delegate as? AppDelegate {app.stopBackgroundTask()}
            }
            
        } catch let error as NSError {
            PreyLogger("JSON parsing error: \(error.localizedDescription)")
            PreyNotification.sharedInstance.handlePushError("Failed to parse actions: \(error.localizedDescription)")
        }
    }
    
    // Add actions to Array
    func addAction(_ jsonDict:NSDictionary) {
        
        // Check cmd command
        if let jsonCMD = jsonDict.object(forKey: kInstruction.cmd.rawValue) as? NSDictionary {
            // Recursive Function
            addAction(jsonCMD)
            return
        }
        
        // Action Name
        guard let jsonName = jsonDict.object(forKey: kInstruction.target.rawValue) as? String else {
            PreyLogger("Error with ActionName")
            return
        }
        guard let actionName: kAction = kAction(rawValue: jsonName) else {
            PreyLogger("Error with ActionName:rawValue")
            return
        }
        
        // Action Command
        guard let jsonCmd = jsonDict.object(forKey: kInstruction.command.rawValue) as? String else {
            PreyLogger("Error with ActionCmd")
            return
        }
        guard let actionCmd: kCommand = kCommand(rawValue: jsonCmd) else {
            PreyLogger("Error with ActionCmd:rawvalue")
            return
        }
        
        // Action Options
        let actionOptions: NSDictionary? = jsonDict.object(forKey: kInstruction.options.rawValue) as? NSDictionary

        // Add new Prey Action
        if let action:PreyAction = PreyAction.newAction(withName: actionName, withCommand: actionCmd, withOptions: actionOptions) {
            PreyLogger("Action added")

            // Actions MessageId
            if let actionMessageId = actionOptions?.object(forKey: kOptions.messageID.rawValue) as? String {
                action.messageId = actionMessageId
            }

            // Actions deviceJobId
            if let actionDeviceJobId = actionOptions?.object(forKey: kOptions.device_job_id.rawValue) as? String {
                action.deviceJobId = actionDeviceJobId
            }
            
            actionArray.append(action)
        }
    }
    
    // Static variable to track if runAction is already in progress
    private static var isRunningActions = false
    private static var lastActionRunTime: Date?
    
    // Run action
    func runAction() {
        // Skip if already running actions or ran too recently (within 10 seconds)
        let shouldRunActions = !PreyModule.isRunningActions && 
                              (PreyModule.lastActionRunTime == nil || 
                              Date().timeIntervalSince(PreyModule.lastActionRunTime!) > 10)
        
        if !shouldRunActions {
            // Don't log anything here to reduce spam
            return
        }
        
        // Set flag to prevent multiple simultaneous calls
        PreyModule.isRunningActions = true
        PreyModule.lastActionRunTime = Date()
        
        PreyLogger("Running actions - count: \(actionArray.count)")
        
        // Create a background task to ensure we have time to process actions
        var bgTask = UIBackgroundTaskIdentifier.invalid
        bgTask = UIApplication.shared.beginBackgroundTask {
            if bgTask != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(bgTask)
                bgTask = UIBackgroundTaskIdentifier.invalid
                PreyLogger("Background task for actions ended due to expiration")
                PreyModule.isRunningActions = false
            }
        }
        
        PreyLogger("Started background task for actions: \(bgTask.rawValue)")

        // Create a dispatch group to track completion of all actions
        let actionGroup = DispatchGroup()
        
        for action in actionArray {
            // Check selector
            if (action.responds(to: NSSelectorFromString(action.command.rawValue)) && !action.isActive) {
                PreyLogger("Running action: \(action.target.rawValue) with command: \(action.command.rawValue)")
                
                // Enter dispatch group
                actionGroup.enter()
                
                // Run action on main thread but don't block
                DispatchQueue.main.async {
                    action.performSelector(onMainThread: NSSelectorFromString(action.command.rawValue), with: nil, waitUntilDone: false)
                    
                    // Use a short delay to allow action to start
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        actionGroup.leave()
                    }
                }
            } else if action.isActive {
                PreyLogger("Action already active: \(action.target.rawValue)")
            } else {
                PreyLogger("Action doesn't respond to selector: \(action.command.rawValue)")
            }
        }
        
        // If we're in the background, make sure location services are running but only if we have actions
        if UIApplication.shared.applicationState == .background && !actionArray.isEmpty {
            // Only configure location services if needed
            var needsLocationServices = false
            for action in actionArray {
                if action.target == kAction.location {
                    needsLocationServices = true
                    break
                }
            }
            
            if needsLocationServices {
                PreyLogger("App is in background, ensuring location services are configured")
                DeviceAuth.sharedInstance.ensureBackgroundLocationIsConfigured()
            }
        }
        
        // When all actions have been initiated
        actionGroup.notify(queue: .main) {
            // End the background task after a delay to ensure actions have time to start
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if bgTask != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(bgTask)
                    bgTask = UIBackgroundTaskIdentifier.invalid
                    PreyLogger("Background task for actions completed normally")
                }
                
                // Reset flag after a delay to prevent rapid consecutive calls
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    PreyModule.isRunningActions = false
                }
            }
        }
    }
    
    // Run only a specific action
    func runSingleAction(_ action: PreyAction) {
        // Create a background task to ensure we have time to process the action
        var bgTask = UIBackgroundTaskIdentifier.invalid
        bgTask = UIApplication.shared.beginBackgroundTask {
            if bgTask != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(bgTask)
                bgTask = UIBackgroundTaskIdentifier.invalid
                PreyLogger("Background task for single action ended due to expiration")
            }
        }
        
        PreyLogger("Started background task for single action: \(bgTask.rawValue)")
        
        // Check selector
        if (action.responds(to: NSSelectorFromString(action.command.rawValue)) && !action.isActive) {
            PreyLogger("Running single action: \(action.target.rawValue) with command: \(action.command.rawValue)")
            action.performSelector(onMainThread: NSSelectorFromString(action.command.rawValue), with: nil, waitUntilDone: true)
        } else if action.isActive {
            PreyLogger("Single action already active: \(action.target.rawValue)")
        } else {
            PreyLogger("Single action doesn't respond to selector: \(action.command.rawValue)")
        }
        
        // End the background task after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if bgTask != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(bgTask)
                bgTask = UIBackgroundTaskIdentifier.invalid
                PreyLogger("Background task for single action completed normally")
            }
        }
    }
    
    // Check action status
    func checkStatus(_ action: PreyAction) {
        
        PreyLogger("Check action")
        
        // Check if preyAction isn't active
        if !action.isActive {
            deleteAction(action)
        }
     
        // Check ActionArray empty
        if actionArray.isEmpty {
            PreyLogger("All actions completed")
            if let app = UIApplication.shared.delegate as? AppDelegate {app.stopBackgroundTask()}
        }
    }
    
    // Delete action
    func deleteAction(_ action: PreyAction) {
        PreyLogger("Start Delete action")
        // Search for preyAction
        for item in actionArray {
            // Compare target
            if item.target == action.target {
                // Get index
                if let indexItem = actionArray.firstIndex(of: item) {
                    // Remove element
                    actionArray.remove(at:indexItem)
                    PreyLogger("Deleted action")
                }
            }
        }
    }
}
