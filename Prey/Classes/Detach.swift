//
//  Detach.swift
//  Prey
//
//  Created by Javier Cala Uribe on 28/06/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

class Detach: PreyAction {
    
    
    // MARK: Functions
    
    // Prey command
    override func start() {
        print("Detach device")

        dispatch_async(dispatch_get_main_queue()) {
            
            self.isActive = true
            
            FIXME()
            // check when report active
            PreyConfig.sharedInstance.resetValues()
            
            guard UIApplication.sharedApplication().applicationState != .Background else {
                print("App in background")
                return
            }
            
            // Get SharedApplication delegate
            guard let appWindow = UIApplication.sharedApplication().delegate?.window else {
                print("error with sharedApplication")
                return
            }
            
            
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "PreyStoryBoard", bundle: nil)
            if let resultController = mainStoryboard.instantiateViewControllerWithIdentifier("welcomeStrbrd") as? WelcomeVC {
                // Set controller to rootViewController
                let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController
                navigationController.setViewControllers([resultController], animated: false)
            }
            
            self.isActive = false
            // Remove geofencing action
            PreyModule.sharedInstance.checkStatus(self)
        }
    }
}