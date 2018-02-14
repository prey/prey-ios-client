//
//  Camouflage.swift
//  Prey
//
//  Created by Javier Cala Uribe on 29/06/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit


class Camouflage: PreyAction {
    
    
    // MARK: Functions
    
    // Prey command
    override func start() {
        PreyLogger("Start camouflage")
        
        // Save camouflageMode in PreyConfig
        PreyConfig.sharedInstance.isCamouflageMode = true
        PreyConfig.sharedInstance.saveValues()

        // Reload HomeView
        if UIApplication.shared.applicationState != .background {
            showHomeView(identifier: StoryboardIdVC.home.rawValue)
        }
        
        // Change icon image
        if #available(iOS 10.3, *) {
            if UIApplication.shared.supportsAlternateIcons {
                UIApplication.shared.setAlternateIconName(alternativeIcon, completionHandler:{(error) in
                    if (error != nil) {
                        PreyConfig.sharedInstance.needChangeIcon = true
                    } else {
                        PreyConfig.sharedInstance.needChangeIcon = false
                    }
                    PreyConfig.sharedInstance.saveValues()
                })
            }
        }
        
        // Send start action
        let params = getParamsTo(kAction.camouflage.rawValue, command: kCommand.start.rawValue, status: kStatus.started.rawValue)
        self.sendData(params, toEndpoint:responseDeviceEndpoint)
    }
    
    // Prey command
    override func stop() {
        PreyLogger("Stop camouflage")
        
        // Save camouflageMode in PreyConfig
        PreyConfig.sharedInstance.isCamouflageMode = false
        PreyConfig.sharedInstance.saveValues()

        // Reload HomeView
        if UIApplication.shared.applicationState != .background {
            showHomeView(identifier: StoryboardIdVC.homeWeb.rawValue)
        }
        
        // Change icon image
        if #available(iOS 10.3, *) {
            if UIApplication.shared.supportsAlternateIcons {
                UIApplication.shared.setAlternateIconName(nil, completionHandler:{(error) in
                    if (error != nil) {
                        PreyConfig.sharedInstance.needChangeIcon = true
                    } else {
                        PreyConfig.sharedInstance.needChangeIcon = false
                    }
                    PreyConfig.sharedInstance.saveValues()
                })
            }
        }
        
        // Send stop action
        let params = getParamsTo(kAction.camouflage.rawValue, command: kCommand.stop.rawValue, status: kStatus.stopped.rawValue)
        self.sendData(params, toEndpoint:responseDeviceEndpoint)
    }
    
    // Reload HomeView
    func showHomeView(identifier: String) {
        
        // Get SharedApplication delegate
        guard let appWindow = UIApplication.shared.delegate?.window else {
            PreyLogger("error with sharedApplication")
            return
        }
        
        let mainStoryboard: UIStoryboard    = UIStoryboard(name:StoryboardIdVC.PreyStoryBoard.rawValue, bundle: nil)
        let resultController = mainStoryboard.instantiateViewController(withIdentifier: identifier)
        // Set controller to rootViewController
        let rootVC: UINavigationController  = mainStoryboard.instantiateViewController(withIdentifier: StoryboardIdVC.navigation.rawValue) as! UINavigationController
        rootVC.setViewControllers([resultController], animated: false)
        appWindow?.rootViewController = rootVC
    }

}
