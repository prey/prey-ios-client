//
//  Detach.swift
//  Prey
//
//  Created by Javier Cala Uribe on 28/06/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import UIKit

class Detach: PreyAction, UIActionSheetDelegate {
    
    
    // MARK: Functions
    
    // Prey command
    override func start() {
        PreyLogger("Detach device")

        DispatchQueue.main.async {
            
            self.isActive = true
            
            // Update ViewController and reset PreyConfig value
            self.detachDevice()
            
            self.isActive = false
            // Remove detach action
            PreyModule.sharedInstance.checkStatus(self)
        }
    }
    
    // Update ViewController and reset PreyConfig value
    func detachDevice() {
        
        // check when report active
        PreyConfig.sharedInstance.resetValues()

        guard UIApplication.shared.applicationState != .background else {
            PreyLogger("App in background")
            return
        }
        
        guard let delegate = UIApplication.shared.delegate else {
            PreyLogger("error with UIApplication delegate")
            return
        }
        
        guard let appWindow = delegate.window as? UIWindow else {
            PreyLogger("error with sharedApplication")
            return
        }
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name:StoryboardIdVC.PreyStoryBoard.rawValue, bundle: nil)
        if let resultController = mainStoryboard.instantiateViewController(withIdentifier: StoryboardIdVC.homeWeb.rawValue) as? HomeWebVC {
            // Set controller to rootViewController
            if let navigationController:UINavigationController = appWindow.rootViewController as? UINavigationController {
                navigationController.setViewControllers([resultController], animated: false)
            }
        }
    }
    
    // Send detachDevice to Panel
    func sendDetachDeviceToPanel() {
        
        let appWindow                                   = UIApplication.shared.delegate?.window
        let navigationController:UINavigationController = appWindow??.rootViewController as! UINavigationController
        
        // Show ActivityIndicator
        let actInd          = UIActivityIndicatorView(initInView:navigationController.view, withText:"Detaching device ...".localized)
        navigationController.view.addSubview(actInd)
        actInd.startAnimating()
        
        self.sendDeleteDevice({(isSuccess: Bool) in
            DispatchQueue.main.async {
                // Hide ActivityIndicator
                actInd.stopAnimating()
                guard isSuccess else {
                    return
                }
                self.detachDevice()}
        })
    }
    
    // MARK: AlerView Message
    
    func showDetachDeviceAction(_ view:UIView) {
        let actionSheet = UIActionSheet(title:"You're about to delete this device from the Control Panel.\n Are you sure?".localized,
                                        delegate:self,
                                        cancelButtonTitle:"No, don't delete".localized,
                                        destructiveButtonTitle:"Yes, remove from my account".localized)
        
        if IS_IPAD {
            actionSheet.addButton(withTitle: "No, don't delete".localized)
        }
        
        actionSheet.show(in: view)
    }
    
    // ActionSheetDelegate
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        if buttonIndex == 0 {
            sendDetachDeviceToPanel()
        }
    }
}
