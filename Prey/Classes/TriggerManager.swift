//
//  TriggerManager.swift
//  Prey
//
//  Created by Javier Cala Uribe on 9/7/19.
//  Copyright © 2019 Prey, Inc. All rights reserved.
//

import Foundation

class TriggerManager : NSObject {
    
    // MARK: Properties
    
    static let sharedInstance = TriggerManager()
    override fileprivate init() {}
    
    // MARK: Functions
    
    func checkTriggers() {
        
        // Check Battery Event
        if (Battery.sharedInstance.sendStatusToPanel()) {
            checkLowBatteryEvent()
        }
    }
    
    // Check low_battery on saved triggers
    func checkLowBatteryEvent() {
        
        let localTriggersArray  = PreyCoreData.sharedInstance.getCurrentTriggers()
        
        for localTrigger in localTriggersArray {
            for itemTrigger in localTrigger.events!.allObjects as! [TriggersEvents] {
                guard itemTrigger.type == "low_battery" else {return}
                
                guard let actionsEventData = localTrigger.actions else {return}
                
                for itemAction in actionsEventData.allObjects as! [TriggersActions] {
                    
                    var delay : Double = 0
                    if let delayData = itemAction.delay {
                        delay = delayData.doubleValue
                    }
                    
                    guard let actionData = itemAction.action else {return}
                    
                    let when = DispatchTime.now() + delay
                    DispatchQueue.main.asyncAfter(deadline: when, execute: {
                        PreyModule.sharedInstance.parseActionsFromPanel(actionData)
                    })
                }
            }
        }
    }
    
    // Event Time
    func scheduleTrigger() {
        
        let localTriggersArray  = PreyCoreData.sharedInstance.getCurrentTriggers()
        
        for localTrigger in localTriggersArray {
            for itemTrigger in localTrigger.events!.allObjects as! [TriggersEvents] {

                guard let actionsEventData = localTrigger.actions else {return}

                switch itemTrigger.type {
                case "exact_time" :
                    scheduleExactTimeLocalNotification(actionsEventData, info: itemTrigger.info!)
                //case "repeat_time" :
                //case "range_time" :
                //case "repeat_range_time" :
                default: return
                }
            }
        }
    }
    
    // Add LocalNotification with action alert
    func scheduleExactTimeLocalNotification(_ actionsData:NSSet, info:String) {

        for itemAction in actionsData.allObjects as! [TriggersActions] {
            
            guard let actionData = itemAction.action else {return}

            guard let jsonData: Data = actionData.data(using: String.Encoding.utf8) else {
                PreyLogger("Error trigger actionsArray to NSData")
                return
            }
            
            guard let jsonDict = try? JSONSerialization.jsonObject(with: jsonData, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSArray else {
                PreyLogger("json trigger error:")
                return
            }
            
            for itemJsonDict in jsonDict {
                
                guard let jsonTarget = (itemJsonDict as! NSDictionary).object(forKey: kInstruction.target.rawValue) as? String else {
                    PreyLogger("Error trigger with ActionName")
                    return
                }
                
                // Check if action target is Alert
                guard jsonTarget == kAction.alert.rawValue else {return}
                
                // Action Options
                let actionOptions: NSDictionary? = (itemJsonDict as! NSDictionary).object(forKey: kInstruction.options.rawValue) as? NSDictionary
                guard let message = actionOptions?.object(forKey: kOptions.MESSAGE.rawValue) as? String else {
                    PreyLogger("Alert trigger: error reading message")
                    return
                }
                
                // Info NSDictionary
                guard let infoData: Data = info.data(using: String.Encoding.utf8) else {
                    PreyLogger("Error trigger info to NSData")
                    return
                }
                
                guard let infoDict = try? JSONSerialization.jsonObject(with: infoData, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary else {
                    PreyLogger("Error trigger info to data")
                    return
                }
                
                guard let stringDate = infoDict["Date"] as? String else {return}
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMddHHmmss"
                formatter.timeZone = TimeZone.current
                formatter.locale = Locale.current
                let dateNotif = formatter.date(from: stringDate)
                
                // Schedule localNotification
                let localNotif:UILocalNotification = UILocalNotification()
                let userInfoLocalNotification:[String: String] = [kOptions.IDLOCAL.rawValue : message]
                localNotif.userInfo     = userInfoLocalNotification
                localNotif.alertBody    = message
                localNotif.hasAction    = false
                localNotif.fireDate     = dateNotif;
                localNotif.timeZone     = NSTimeZone.default;
                
                UIApplication.shared.scheduleLocalNotification(localNotif)
            }
        }
    }
}
