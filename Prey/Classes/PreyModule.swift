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
    private init() {
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
        if let reportAction:Report = Report(withTarget:kAction.report, withCommand:kCommand.get, withOptions:PreyConfig.sharedInstance.reportOptions) {
            actionArray.append(reportAction)
            runAction()
        }
    }
    
    // Parse actions from panel
    func parseActionsFromPanel(actionsStr:String) {
        
        PreyLogger("Parse actions from panel \(actionsStr)")
        
        // Convert actionsArray from String to NSData
        guard let jsonData: NSData = actionsStr.dataUsingEncoding(NSUTF8StringEncoding) else {
            
            PreyLogger("Error actionsArray to NSData")
            PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
            
            return
        }
        
        // Convert NSData to NSArray
        let jsonObjects: NSArray
        
        do {
            jsonObjects = try NSJSONSerialization.JSONObjectWithData(jsonData, options:NSJSONReadingOptions.MutableContainers) as! NSArray
            
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
            }
            
        } catch let error as NSError{
            PreyLogger("json error: \(error.localizedDescription)")
            PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
        }
    }
    
    // Add actions to Array
    func addAction(jsonDict:NSDictionary) {
        
        // Check cmd command
        if let jsonCMD = jsonDict.objectForKey(kInstruction.cmd.rawValue) as? NSDictionary {
            // Recursive Function
            addAction(jsonCMD)
            return
        }
        
        // Action Name
        guard let jsonName = jsonDict.objectForKey(kInstruction.target.rawValue) as? String else {
            PreyLogger("Error with ActionName")
            return
        }
        guard let actionName: kAction = kAction(rawValue: jsonName) else {
            PreyLogger("Error with ActionName:rawValue")
            return
        }
        
        // Action Command
        guard let jsonCmd = jsonDict.objectForKey(kInstruction.command.rawValue) as? String else {
            PreyLogger("Error with ActionCmd")
            return
        }
        guard let actionCmd: kCommand = kCommand(rawValue: jsonCmd) else {
            PreyLogger("Error with ActionCmd:rawvalue")
            return
        }
        
        // Action Options
        let actionOptions: NSDictionary? = jsonDict.objectForKey(kInstruction.options.rawValue) as? NSDictionary
        
        // Add new Prey Action
        if let action:PreyAction = PreyAction.newAction(withName: actionName, withCommand: actionCmd, withOptions: actionOptions) {
            actionArray.append(action)
        }
    }
    
    // Run action
    func runAction() {

        for action in actionArray {
            // Check selector
            if (action.respondsToSelector(NSSelectorFromString(action.command.rawValue)) && !action.isActive) {
                PreyLogger("Run \(action.target.rawValue) action")
                action.performSelectorOnMainThread(NSSelectorFromString(action.command.rawValue), withObject: nil, waitUntilDone: true)
            }
        }
    }
    
    // Check action status
    func checkStatus(action: PreyAction) {
        
        PreyLogger("Check \(action.target.rawValue) action")
        
        // Check if preyAction isn't active
        if !action.isActive {
            deleteAction(action)
        }
     
        // Check ActionArray empty
        if actionArray.isEmpty {
            PreyLogger("Notification checkRequestVerificationSucceded OK")
            PreyNotification.sharedInstance.checkRequestVerificationSucceded(true)
        }
    }
    
    // Delete action
    func deleteAction(action: PreyAction) {
        
        PreyLogger("Delete \(action.target) action")
        
        for item in actionArray {
            if ( item.target == action.target ) {
                actionArray.removeObject(action)
            }
        }
    }
}