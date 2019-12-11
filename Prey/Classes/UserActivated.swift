//
//  UserActivated.swift
//  Prey
//
//  Created by Javier Cala Uribe on 11/12/19.
//  Copyright © 2019 Fork Ltd. All rights reserved.
//

import Foundation

class UserActivated: PreyAction {
    
    // MARK: Properties
    
    // MARK: Functions
    
    // Prey command
    override func start() {
        
        isActive = true
        PreyLogger("Start user activated")
        
        PreyConfig.sharedInstance.validationUserEmail = PreyUserEmailValidation.active.rawValue
        PreyConfig.sharedInstance.isRegistered = true
        PreyConfig.sharedInstance.saveValues()
        
        DispatchQueue.main.async {
            guard let appWindow = UIApplication.shared.delegate?.window else {
                PreyLogger("error with sharedApplication")
                return
            }
            let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController
            if let homeWebVC:HomeWebVC = navigationController.topViewController as? HomeWebVC {
                homeWebVC.evaluateJS(homeWebVC.webView, code: "var btn = document.getElementById('btnIDEmailConfirm'); btn.click();")
            }
        }
        
        isActive = false
        PreyModule.sharedInstance.checkStatus(self)
    }
    
    // Prey command : Email Expired
    override func stop() {
        
        isActive = true
        PreyLogger("Stop user activated")
        
        PreyConfig.sharedInstance.validationUserEmail = PreyUserEmailValidation.inactive.rawValue
        PreyConfig.sharedInstance.isRegistered = false
        PreyConfig.sharedInstance.saveValues()
        
        DispatchQueue.main.async {
            guard let appWindow = UIApplication.shared.delegate?.window else {
                PreyLogger("error with sharedApplication")
                return
            }
            let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController
            if let homeWebVC:HomeWebVC = navigationController.topViewController as? HomeWebVC {
                homeWebVC.evaluateJS(homeWebVC.webView, code: "var btn = document.getElementById('btnIDEmailExpired'); btn.click();")
            }
        }
        
        isActive = false
        PreyModule.sharedInstance.checkStatus(self)
    }
}
