//
//  TriggerManager.swift
//  Prey
//
//  Created by Javier Cala Uribe on 9/7/19.
//  Copyright © 2019 Prey, Inc. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit

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
                guard itemTrigger.type == "low_battery" else {continue}
                var isInRangeTime = true
                for itemTrigger in localTrigger.events!.allObjects as! [TriggersEvents] {
                    switch itemTrigger.type {
                    case "range_time" :
                        isInRangeTime = checkRangeTimeInEvent(itemTrigger.info!)
                        break
                    case "repeat_range_time" :
                        isInRangeTime = checkRepeatRangeTimeInEvent(itemTrigger.info!)
                        break
                    default: continue
                    }
                }

                guard isInRangeTime else {continue}
                
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
    func scheduleTrigger(_ localTrigger:Triggers) {

        for itemTrigger in localTrigger.events!.allObjects as! [TriggersEvents] {
            
            guard let actionsEventData = localTrigger.actions else {return}

            switch itemTrigger.type {
            case "exact_time" :
                scheduleExactTimeLocalNotification(actionsEventData, info: itemTrigger.info!, triggerId: localTrigger.id!.stringValue)
            case "repeat_time" :
                scheduleRepeatTimeLocalNotification(actionsEventData, info: itemTrigger.info!, triggerId: localTrigger.id!.stringValue)
            default: return
            }
        }
    }
    
    // Add LocalNotification with action alert
    func scheduleExactTimeLocalNotification(_ actionsData:NSSet, info:String, triggerId:String) {

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
                
                guard let stringDate = infoDict["date"] as? String else {return}
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMddHHmmss"
                formatter.timeZone = TimeZone.current
                formatter.locale = Locale.current
                let dateNotif = formatter.date(from: stringDate)
                
                guard dateNotif! >= Date() else {return}
                
                // Schedule localNotification
                let userInfoLocalNotification:[String: String] =
                    [kOptions.IDLOCAL.rawValue      : message,
                     kOptions.trigger_id.rawValue   : triggerId]
                
                let content = UNMutableNotificationContent()
                content.userInfo = userInfoLocalNotification
                content.categoryIdentifier = categoryNotifPreyAlert
                content.body = message
                content.title = "Prey Alert"
                content.sound = .default
                let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: dateNotif!)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,repeats: false)
                let request = UNNotificationRequest(identifier: "exact_\(triggerId)_\(UUID().uuidString)", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        PreyLogger("Error scheduling exact time notification: \(error.localizedDescription)")
                    }
                }
                PreyLogger("DONE exact")
            }
        }
    }
    
    // Add LocalNotification with action alert
    func scheduleRepeatTimeLocalNotification(_ actionsData:NSSet, info:String, triggerId:String) {
        
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

                guard let daysWeek = infoDict[kInfoRepeatTime.days_of_week.rawValue] as? String else {return}
                guard let hour = infoDict[kInfoRepeatTime.hour.rawValue] as? String else {return}
                guard let minute = infoDict[kInfoRepeatTime.minute.rawValue] as? String else {return}
                guard let second = infoDict[kInfoRepeatTime.second.rawValue] as? String else {return}
                
                let dayArray = daysWeek.components(separatedBy: ["[", "]", ","])
                for day in dayArray {
                    if day == "" {continue}
                    let desiredWeekday = Int(day)! + 1
                    let weekDateRange = NSCalendar.current.maximumRange(of: .weekday)!
                    let daysInWeek = weekDateRange.lowerBound.distance(to: weekDateRange.upperBound)-weekDateRange.lowerBound+1
                    let currentWeekday = NSCalendar.current.dateComponents([.weekday], from: Date()).weekday
                    let differenceDays = (desiredWeekday - currentWeekday! + daysInWeek) % daysInWeek
                    
                    var fireDate = DateComponents()
                    fireDate.day = Calendar.current.component(.day, from: Date()) + differenceDays
                    fireDate.year = Calendar.current.component(.year, from: Date())
                    fireDate.month = Calendar.current.component(.month, from: Date())
                    fireDate.hour = Int(hour)
                    fireDate.minute = Int(minute)
                    fireDate.second = Int(second)
                    // Schedule localNotification
                    let userInfoLocalNotification:[String: String] =
                        [kOptions.IDLOCAL.rawValue      : message,
                         kOptions.trigger_id.rawValue   : triggerId]
                    
                    let content = UNMutableNotificationContent()
                    content.userInfo = userInfoLocalNotification
                    content.categoryIdentifier = categoryNotifPreyAlert
                    content.body = message
                    content.title = "Prey Alert"
                    content.sound = .default
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: fireDate, repeats: true)
                    let request = UNNotificationRequest(identifier: "repeat_\(triggerId)_\(day)", content: content, trigger: trigger)
                    
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            PreyLogger("Error scheduling repeat time notification: \(error.localizedDescription)")
                        }
                    }
                    PreyLogger("DONE repeat")
                }
            }
        }
    }
    

    func checkRangeTimeInEvent(_ info:String) -> Bool {
        let isInRangeTime = true
        
        // Info NSDictionary
        guard let infoData: Data = info.data(using: String.Encoding.utf8) else {
            PreyLogger("Error trigger range info to NSData")
            return false
        }
        
        guard let infoDict = try? JSONSerialization.jsonObject(with: infoData, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary else {
            PreyLogger("Error trigger range info to data")
            return false
        }
        
        guard let fromEvent = infoDict[kInfoRangetTime.from.rawValue] as? String else {return false}
        guard let untilEvent = infoDict[kInfoRangetTime.until.rawValue] as? String else {return false}
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        let fromDate = formatter.date(from: fromEvent)
        let untilDate = formatter.date(from: untilEvent)
        
        guard fromDate! <= Date() else {return false}
        guard untilDate! >= Date() else {return false}
        
        return isInRangeTime
    }

    func checkRepeatRangeTimeInEvent(_ info:String) -> Bool {
        let isInRangeTime = true
        
        // Info NSDictionary
        guard let infoData: Data = info.data(using: String.Encoding.utf8) else {
            PreyLogger("Error trigger range info to NSData")
            return false
        }
        
        guard let infoDict = try? JSONSerialization.jsonObject(with: infoData, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary else {
            PreyLogger("Error trigger range info to data")
            return false
        }
        
        guard let dayWeekEvent = infoDict[kInfoRepeatRangetTime.days_of_week.rawValue] as? String else {return false}
        guard let fromHourEvent = infoDict[kInfoRepeatRangetTime.hour_from.rawValue] as? String else {return false}
        guard let untilHourEvent = infoDict[kInfoRepeatRangetTime.hour_until.rawValue] as? String else {return false}
        
        let dayArray = dayWeekEvent.components(separatedBy: ["[", "]", ","])
        var isOnDay = false
        for day in dayArray {
            if day == "" {continue}
            let desiredWeekday = Int(day)! + 1
            if (desiredWeekday == NSCalendar.current.dateComponents([.weekday], from: Date()).weekday) {
                isOnDay = true
                break
            }
        }
        guard isOnDay else {return false}
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmmss"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        let nowtime = formatter.string(from: Date())
        
        guard Int(fromHourEvent)! <= Int(nowtime)! else {return false}
        guard Int(untilHourEvent)! >= Int(nowtime)! else {return false}
        
        if (infoDict[kInfoRepeatRangetTime.until.rawValue] != nil) {
            guard let untilEvent = infoDict[kInfoRepeatRangetTime.until.rawValue] as? String else {return false}
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd"
            formatter.timeZone = TimeZone.current
            formatter.locale = Locale.current
            let untilDate = formatter.date(from: untilEvent)
            guard untilDate! >= Date() else {return false}
        }
        
        return isInRangeTime
    }
}
