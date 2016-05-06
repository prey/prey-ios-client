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
            
            // Run Actions
            if actionArray.count > 0 {
                runActions()
            } else {
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
        guard let actionName: String = jsonDict.objectForKey("target") as? String else {
            print("Error with ActionName")
            return
        }
        
        // Action Command
        guard let actionCmd: String = jsonDict.objectForKey("command") as? String else {
            print("Error with ActionCmd")
            return
        }
        
        // Action Options
        let actionOptions: NSDictionary? = jsonDict.objectForKey("options") as? NSDictionary
        
        // Add new Prey Action
        if let action:PreyAction = PreyAction.newAction(actionName, withCommand: actionCmd, withOptions: actionOptions) {
            actionArray.append(action)
        }
    }
    
    // Run actions
    func runActions() {
        
        print("Run all modules")
        
        for action in actionArray {
            if action.respondsToSelector(NSSelectorFromString(action.command)) {
                action.performSelectorOnMainThread(NSSelectorFromString(action.command), withObject: nil, waitUntilDone: true)
            }
        }
        
        actionArray.removeAll()
    }
}