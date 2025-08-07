//
//  Trigger.swift
//  Prey
//
//  Created by Javier Cala Uribe on 4/07/19.
//  Copyright © 2019 Prey, Inc. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Trigger : PreyAction, @unchecked Sendable {
    
    // MARK: Properties
    
    // MARK: Functions    
    
    // Prey command
    override func start() {
        
        PreyLogger("Check triggers on panel")
        checkTriggers(self)
        
        isActive = true
    }
    
    // Update Triggers locally
    func updateTriggers(_ response:NSArray) {
        
        PreyLogger("Update triggers")
        
        // Delete all triggers on Device
        deleteAllTriggersOnDevice()
        
        // Delete all triggersOnCoreData
        deleteAllTriggersOnCoreData()
        
        // Add triggers to CoreData
        addTriggersToCoreData(response, withContext:PreyCoreData.sharedInstance.managedObjectContext)
        
        // Add triggers to Device
        addTriggersToDevice()
        
        
        isActive = false
        // Remove trigger action
        PreyModule.sharedInstance.checkStatus(self)
    }

    // Send event to panel
    func sendEventToPanel(_ triggersArray:[Triggers], withCommand cmd:kCommand, withStatus status:kStatus){
        
        // Create a triggerId array with new triggers
        let triggerArray = NSMutableArray()
        for itemAdded in triggersArray {
            let triggersId : [String: Double] = [
                "id"    : itemAdded.id!.doubleValue,
                "state" : 1]
            triggerArray.add(triggersId)
        }
        
        let data = try? JSONSerialization.data(withJSONObject: triggerArray)
        
        // Params struct
        let params:[String: String] = [
            kData.status.rawValue   : status.rawValue,
            kData.target.rawValue   : kAction.triggers.rawValue,
            kData.command.rawValue  : cmd.rawValue,
            kData.reason.rawValue   : String(data: data!, encoding: .utf8)!]

        // Send info to panel
        if let username = PreyConfig.sharedInstance.userApiKey, PreyConfig.sharedInstance.isRegistered {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:responseDeviceEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.dataSend, preyAction:nil, onCompletion:{(isSuccess: Bool) in PreyLogger("Request dataSend")}))
        } else {
            PreyLogger("Error send data auth")
        }
    }
    
    // Delete all triggers on device
    func deleteAllTriggersOnDevice() {
        UIApplication.shared.cancelAllLocalNotifications()        
    }
    
    // Delete all triggersOnCoreData
    func deleteAllTriggersOnCoreData() {
        
        let localTriggersArray  = PreyCoreData.sharedInstance.getCurrentTriggers()
        let context             = PreyCoreData.sharedInstance.managedObjectContext
        
        for localTrigger in localTriggersArray {
            context?.delete(localTrigger)
        }
    }
    
    // Add triggers to CoreData
    func addTriggersToCoreData(_ response:NSArray, withContext context:NSManagedObjectContext) {
        
        for serverTriggersArray in response {
            
            // Init NSManagedObject type Triggers
            let trigger = NSEntityDescription.insertNewObject(forEntityName: "Triggers", into: context) as! Triggers
            
            // Attributes from Triggers
            let attributes = trigger.entity.attributesByName
            
            for (attribute,description) in attributes {
                if var value = (serverTriggersArray as AnyObject).value(forKey: attribute) {
                    switch description.attributeType {
                    case .doubleAttributeType:
                        value = NSNumber(value: (value as AnyObject).doubleValue as Double)
                    default:
                        value = ((value as AnyObject) is NSNull) ? "" : value as! String
                    }
                    
                    // Save {value,key} in Trigger item
                    trigger.setValue(value, forKey: attribute)
                }
            }
            // Check events
            if let eventsArray = (serverTriggersArray as AnyObject).value(forKey: "automation_events") as? NSArray {
                for eventItem in eventsArray {
                    let eventsTrigger = NSEntityDescription.insertNewObject(forEntityName: "TriggersEvents", into: context) as! TriggersEvents

                    if let type = (eventItem as AnyObject).value(forKey: "type") as? String {
                        eventsTrigger.type = type
                    }
                    if let info = (eventItem as AnyObject).value(forKey: "info") as? NSDictionary {
                        do {
                            let data = try JSONSerialization.data(withJSONObject: info)
                            eventsTrigger.info = String(data: data, encoding: .utf8)
                        } catch let error as NSError {
                            PreyLogger("json error trigger: \(error.localizedDescription)")
                        }
                    }
                    trigger.addToEvents(eventsTrigger)
                }
            }
            // Check actions
            if let actionArray = ((serverTriggersArray) as AnyObject).value(forKey: "automation_actions") as? NSArray {
                for actionItem in actionArray {
                    let actionTrigger = NSEntityDescription.insertNewObject(forEntityName: "TriggersActions", into: context) as! TriggersActions
                    
                    if let delay = (actionItem as AnyObject).value(forKey: "delay") as? Double {
                        actionTrigger.delay = NSNumber(value:delay)
                    }
                    if let action = (actionItem as AnyObject).value(forKey: "action") as? NSDictionary {
                        let localActionArray = NSMutableArray()
                        localActionArray.add(action)
                        
                        do {
                            let data = try JSONSerialization.data(withJSONObject: localActionArray)
                            actionTrigger.action = String(data: data, encoding: .utf8)
                        } catch let error as NSError{
                            PreyLogger("json error trigger: \(error.localizedDescription)")
                        }
                        
                    }
                    trigger.addToActions(actionTrigger)
                }
            }
        }
        
        // Save CoreData
        do {
            try context.save()
        } catch {
            PreyLogger("Couldn't save trigger: \(error)")
        }
    }
    
    // Add triggers to Device
    func addTriggersToDevice() {
        
        let localTriggersArray  = PreyCoreData.sharedInstance.getCurrentTriggers()
        
        for localTrigger in localTriggersArray {

            PreyLogger("Name trigger "+String(format: "%f", (localTrigger.id?.floatValue)!))

            let timeEvent = ["exact_time", "repeat_time"]
            var onlyTimeEvents = true

            for itemTrigger in localTrigger.events!.allObjects as! [TriggersEvents] {
                guard timeEvent.contains(itemTrigger.type!) else {
                    onlyTimeEvents = false
                    break
                }
            }
            
            if onlyTimeEvents {
                TriggerManager.sharedInstance.scheduleTrigger(localTrigger)
            }
        }
        
        // Added triggers
        sendEventToPanel(localTriggersArray, withCommand:kCommand.start , withStatus:kStatus.started)
    }
}
