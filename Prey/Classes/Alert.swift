//
//  Alert.swift
//  Prey
//
//  Created by Javier Cala Uribe on 29/06/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

class Alert: PreyAction {
    
    
    // MARK: Functions
    
    // Prey command
    override func start() {
        print("Start alert")

        // Check message
        guard let message = self.options?.objectForKey(kAlert.MESSAGE.rawValue) as? String else {
            print("Alert: error reading message")
            let parameters = getParamsTo(kAction.alert.rawValue, command: kCommand.stop.rawValue, status: kStatus.stopped.rawValue)
            self.sendData(parameters, toEndpoint: responseDeviceEndpoint)
            return
        }
        
        // Show message
        if UIApplication.sharedApplication().applicationState != .Background {
           showAlertVC(message)
            
        } else if let localNotif:UILocalNotification = UILocalNotification() {
            
            // UserInfo
            let userInfoLocalNotification:[String: AnyObject] = [kAlert.IDLOCAL.rawValue : message]
            localNotif.userInfo     = userInfoLocalNotification
            localNotif.alertBody    = message
            localNotif.hasAction    = false
            UIApplication.sharedApplication().presentLocalNotificationNow(localNotif)
        }
        
        // Send start action
        let params  = getParamsTo(kAction.alert.rawValue, command: kCommand.start.rawValue, status: kStatus.started.rawValue)
        self.sendData(params, toEndpoint: responseDeviceEndpoint)
    }
    
    // Show AlertVC
    func showAlertVC(msg:String) {
        
        // Get SharedApplication delegate
        guard let appWindow = UIApplication.sharedApplication().delegate?.window else {
            print("error with sharedApplication")
            return
        }
        
        let mainStoryboard: UIStoryboard    = UIStoryboard(name:StoryboardIdVC.PreyStoryBoard.rawValue, bundle: nil)
        
        if let resultController = mainStoryboard.instantiateViewControllerWithIdentifier(StoryboardIdVC.alert.rawValue) as? AlertVC {
            
            resultController.messageToShow  = msg
            
            // Set controller to rootViewController
            let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController
            navigationController.setViewControllers([resultController], animated: false)
        }
    }
}