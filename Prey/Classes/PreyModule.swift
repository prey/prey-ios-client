//
//  PreyModule.swift
//  Prey
//
//  Created by Javier Cala Uribe on 5/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation

class PreyModule {
    
    // MARK: Properties
    
    static let sharedInstance = PreyModule()
    fileprivate init() {
    }
    
    var actionArray = [PreyAction] ()
    
    // MARK: Functions

    // Check actionArrayStatus
    func checkActionArrayStatus() {
        
        // Check device is missing
        guard PreyConfig.sharedInstance.isMissing else {
            return
        }
    
        // Check actionArray
        guard actionArray.isEmpty else {
            return
        }
        
        // Add report action
        let reportAction:Report = Report(withTarget:kAction.report, withCommand:kCommand.get, withOptions:PreyConfig.sharedInstance.reportOptions)
        actionArray.append(reportAction)
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

        for action in actionArray {
            // Check selector
            if (action.responds(to: NSSelectorFromString(action.command.rawValue)) && !action.isActive) {
                PreyLogger("Run action")
                action.performSelector(onMainThread: NSSelectorFromString(action.command.rawValue), with: nil, waitUntilDone: true)
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
