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
        
        // Check device is missing
        guard PreyConfig.sharedInstance.isMissing else {
            PreyLogger("Device is not missing, skipping actions")
            return
        }
    
        // Check actionArray
        guard actionArray.isEmpty else {
            PreyLogger("Action array already has \(actionArray.count) actions")
            // Make sure actions are running
            runAction()
            return
        }
        
        // Add report action
        let reportAction:Report = Report(withTarget:kAction.report, withCommand:kCommand.get, withOptions:PreyConfig.sharedInstance.reportOptions)
        actionArray.append(reportAction)
        PreyLogger("Added report action to action array")
        runAction()
    }
    
    // Parse actions from panel
    func parseActionsFromPanel(_ actionsStr:String) {

        PreyLogger("Parse actions from panel")
        
        // Convert actionsArray from String to NSData
        guard let jsonData: Data = actionsStr.data(using: String.Encoding.utf8) else {
            
            PreyLogger("Error actionsArray to NSData")
            PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
            
            return
        }
        
        // Convert NSData to NSArray
        let jsonObjects: NSArray
        
        do {
            jsonObjects = try JSONSerialization.jsonObject(with: jsonData, options:JSONSerialization.ReadingOptions.mutableContainers) as! NSArray
            
            // Add Actions in ActionArray
            for dict in jsonObjects {
                addAction(dict as! NSDictionary)
            }
            
            // Run actions
            runAction()
            
            // Check ActionArray empty
            if actionArray.isEmpty {
                PreyLogger("Notification checkRequestVerificationSucceded OK")
                PreyNotification.sharedInstance.checkRequestVerificationSucceded(true)
                if let app = UIApplication.shared.delegate as? AppDelegate {app.stopBackgroundTask()}
            }
            
        } catch let error as NSError{
            PreyLogger("json error: \(error.localizedDescription)")
            PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
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
    
    // Run action
    func runAction() {
        PreyLogger("Running actions - count: \(actionArray.count)")
        
        // Create a background task to ensure we have time to process actions
        var bgTask = UIBackgroundTaskIdentifier.invalid
        bgTask = UIApplication.shared.beginBackgroundTask {
            if bgTask != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(bgTask)
                bgTask = UIBackgroundTaskIdentifier.invalid
                PreyLogger("Background task for actions ended due to expiration")
            }
        }
        
        PreyLogger("Started background task for actions: \(bgTask.rawValue)")

        for action in actionArray {
            // Check selector
            if (action.responds(to: NSSelectorFromString(action.command.rawValue)) && !action.isActive) {
                PreyLogger("Running action: \(action.target.rawValue) with command: \(action.command.rawValue)")
                action.performSelector(onMainThread: NSSelectorFromString(action.command.rawValue), with: nil, waitUntilDone: true)
            } else if action.isActive {
                PreyLogger("Action already active: \(action.target.rawValue)")
            } else {
                PreyLogger("Action doesn't respond to selector: \(action.command.rawValue)")
            }
        }
        
        // If we're in the background, make sure location services are running
        if UIApplication.shared.applicationState == .background {
            PreyLogger("App is in background, ensuring location services are configured")
            DeviceAuth.sharedInstance.ensureBackgroundLocationIsConfigured()
        }
        
        // End the background task after a delay to ensure actions have time to start
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if bgTask != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(bgTask)
                bgTask = UIBackgroundTaskIdentifier.invalid
                PreyLogger("Background task for actions completed normally")
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
            PreyLogger("Notification checkRequestVerificationSucceded OK")
            PreyNotification.sharedInstance.checkRequestVerificationSucceded(true)
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
