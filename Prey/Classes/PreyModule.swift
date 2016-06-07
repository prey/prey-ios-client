//
//  PreyModule.swift
//  Prey
//
//  Created by Javier Cala Uribe on 5/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation

// Prey Instructions struct
enum kInstruction: String {
    case TARGET     = "target"
    case COMMAND    = "command"
    case OPTIONS    = "options"
}

class PreyModule {
    
    // MARK: Properties
    
    static let sharedInstance = PreyModule()
    private init() {
    }
    
    var actionArray = [PreyAction] ()
    
    // MARK: Functions

    // Parse actions from panel
    func parseActionsFromPanel(actionsStr:String) {
        
        print("Parse actions from panel \(actionsStr)")
        
        // Convert actionsArray from String to NSData
        guard let jsonData: NSData = actionsStr.dataUsingEncoding(NSUTF8StringEncoding) else {
            
            print("Error actionsArray to NSData")
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
            if actionArray.count <= 0 {
                print("Notification checkRequestVerificationSucceded OK")
                PreyNotification.sharedInstance.checkRequestVerificationSucceded(true)
            }
            
        } catch let error as NSError{
            print("json error: \(error.localizedDescription)")
            PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
        }
    }
    
    // Add actions to Array
    func addAction(jsonDict:NSDictionary) {
        
        // Action Name
        guard let actionName: kAction = kAction(rawValue:jsonDict.objectForKey(kInstruction.TARGET.rawValue) as! String) else {
            print("Error with ActionName")
            return
        }
        
        // Action Command
        guard let actionCmd: kCommand = kCommand(rawValue:jsonDict.objectForKey(kInstruction.COMMAND.rawValue) as! String) else {
            print("Error with ActionCmd")
            return
        }
        
        // Action Options
        let actionOptions: NSDictionary? = jsonDict.objectForKey(kInstruction.OPTIONS.rawValue) as? NSDictionary
        
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
                print("Run \(action.target.rawValue) action")
                action.performSelectorOnMainThread(NSSelectorFromString(action.command.rawValue), withObject: nil, waitUntilDone: true)
            }
        }
    }
    
    // Check action status
    func checkStatus(action: PreyAction) {
        
        print("Check \(action.target.rawValue) action")
        
        // Check if preyAction isn't active
        if !action.isActive {
            deleteAction(action)
        }
     
        // Check ActionArray empty
        if actionArray.count <= 0 {
            print("Notification checkRequestVerificationSucceded OK")
            PreyNotification.sharedInstance.checkRequestVerificationSucceded(true)
        }
    }
    
    // Delete action
    func deleteAction(action: PreyAction) {
        
        FIXME()
        // start stop action fix
        
        print("Delete \(action.target) action")
        
        for item in actionArray {
            if ( (item.target == action.target) == (item.command == action.command) ) {
                actionArray.removeObject(action)
            }
        }
    }
}