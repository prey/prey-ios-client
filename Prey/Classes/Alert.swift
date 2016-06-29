//
//  Alert.swift
//  Prey
//
//  Created by Javier Cala Uribe on 29/06/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation


class Alert: PreyAction {
    
    
    // MARK: Functions
    
    // Prey command
    override func start() {
        print("Start alert")

        // Send start action
        isActive = true
        var params = getParamsTo(kAction.ALERT.rawValue, command: kCommand.START.rawValue, status: kStatus.STARTED.rawValue)
        self.sendData(params, toEndpoint: responseDeviceEndpoint)

        
        FIXME()
        // Add viewController alert
        
        // Send stop action
        isActive = false
        params = getParamsTo(kAction.ALERT.rawValue, command: kCommand.STOP.rawValue, status: kStatus.STOPPED.rawValue)
        self.sendData(params, toEndpoint: responseDeviceEndpoint)
        
    }
}