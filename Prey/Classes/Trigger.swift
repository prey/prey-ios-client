//
//  Trigger.swift
//  Prey
//
//  Created by Javier Cala Uribe on 4/07/19.
//  Copyright © 2019 Prey, Inc. All rights reserved.
//

import Foundation

class Trigger : PreyAction {
    
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
        
        isActive = false
        // Remove geofencing action
        PreyModule.sharedInstance.checkStatus(self)
    }

}
