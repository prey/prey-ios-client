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
}
