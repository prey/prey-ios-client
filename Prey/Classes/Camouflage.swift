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
        print("Start camouflage")
        
        // Save camouflageMode in PreyConfig
        PreyConfig.sharedInstance.isCamouflageMode = true
        PreyConfig.sharedInstance.saveValues()

        // Reload HomeView
        if UIApplication.sharedApplication().applicationState != .Background {
            showHomeView()
        }
        
        // Send start action
        let params = getParamsTo(kAction.camouflage.rawValue, command: kCommand.start.rawValue, status: kStatus.started.rawValue)
        self.sendData(params, toEndpoint:responseDeviceEndpoint)
    }
    
    // Prey command
    override func stop() {
        print("Stop camouflage")
        
        // Save camouflageMode in PreyConfig
        PreyConfig.sharedInstance.isCamouflageMode = false
        PreyConfig.sharedInstance.saveValues()

        // Reload HomeView
        if UIApplication.sharedApplication().applicationState != .Background {
            showHomeView()
        }
        
        // Send stop action
        let params = getParamsTo(kAction.camouflage.rawValue, command: kCommand.stop.rawValue, status: kStatus.stopped.rawValue)
        self.sendData(params, toEndpoint:responseDeviceEndpoint)
    }
    
    // Reload HomeView
    func showHomeView() {
        
        // Get SharedApplication delegate
        guard let appWindow = UIApplication.sharedApplication().delegate?.window else {
            print("error with sharedApplication")
            return
        }
        
        let mainStoryboard: UIStoryboard    = UIStoryboard(name:StoryboardIdVC.PreyStoryBoard.rawValue, bundle: nil)
        
        if let resultController = mainStoryboard.instantiateViewControllerWithIdentifier(StoryboardIdVC.home.rawValue) as? HomeVC {
            
            // Set controller to rootViewController
            let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController
            navigationController.setViewControllers([resultController], animated: false)
        }
    }

}