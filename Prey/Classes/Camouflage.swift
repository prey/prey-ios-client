//
//  Camouflage.swift
//  Prey
//
//  Created by Javier Cala Uribe on 29/06/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import UIKit


class Camouflage: PreyAction, @unchecked Sendable {
    
    
    // MARK: Functions
    
    // Prey command
    override func start() {
        PreyLogger("Start camouflage")
        
        // Save camouflageMode in PreyConfig
        PreyConfig.sharedInstance.isCamouflageMode = true
        PreyConfig.sharedInstance.saveValues()

        // Reload HomeView
        // Fix: Check app state on main thread to avoid Main Thread Checker warning
        var isAppInBackground = false
        if Thread.isMainThread {
            isAppInBackground = UIApplication.shared.applicationState == .background
        } else {
            DispatchQueue.main.sync {
                isAppInBackground = UIApplication.shared.applicationState == .background
            }
        }
        
        if !isAppInBackground {
            showHomeView(identifier: StoryboardIdVC.home.rawValue)
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
        // Fix: Check app state on main thread to avoid Main Thread Checker warning
        var isAppInBackground = false
        if Thread.isMainThread {
            isAppInBackground = UIApplication.shared.applicationState == .background
        } else {
            DispatchQueue.main.sync {
                isAppInBackground = UIApplication.shared.applicationState == .background
            }
        }
        
        if !isAppInBackground {
            showHomeView(identifier: StoryboardIdVC.homeWeb.rawValue)
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
