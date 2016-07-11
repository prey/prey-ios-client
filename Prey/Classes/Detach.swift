//
//  Detach.swift
//  Prey
//
//  Created by Javier Cala Uribe on 28/06/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

class Detach: PreyAction, UIActionSheetDelegate {
    
    
    // MARK: Functions
    
    // Prey command
    override func start() {
        print("Detach device")

        dispatch_async(dispatch_get_main_queue()) {
            
            self.isActive = true
            
            FIXME()
            
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
    }
    
    // Send detachDevice to Panel
    func sendDetachDeviceToPanel() {
        
        let appWindow                                   = UIApplication.sharedApplication().delegate?.window
        let navigationController:UINavigationController = appWindow??.rootViewController as! UINavigationController
        
        // Show ActivityIndicator
        let actInd          = UIActivityIndicatorView(initInView:navigationController.view, withText:"Detaching device ...".localized)
        navigationController.view.addSubview(actInd)
        actInd.startAnimating()
        
        self.sendDeleteDevice({(isSuccess: Bool) in
            dispatch_async(dispatch_get_main_queue()) {
                // Hide ActivityIndicator
                actInd.stopAnimating()
                guard isSuccess else {
                    return
                }
                self.detachDevice()}
        })
    }
    
    // MARK: AlerView Message
    
    func showDetachDeviceAction(view:UIView) {
        let actionSheet = UIActionSheet(title:"You're about to delete this device from the Control Panel.\n Are you sure?".localized,
                                        delegate:self,
                                        cancelButtonTitle:"No, don't delete".localized,
                                        destructiveButtonTitle:"Yes, remove from my account".localized)
        
        if IS_IPAD {
            actionSheet.addButtonWithTitle("No, don't delete".localized)
        }
        
        actionSheet.showInView(view)
    }
    
    // ActionSheetDelegate
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 {
            sendDetachDeviceToPanel()
        }
    }
}