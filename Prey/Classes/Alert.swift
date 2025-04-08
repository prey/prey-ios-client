//
//  Alert.swift
//  Prey
//
//  Created by Javier Cala Uribe on 29/06/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

class Alert: PreyAction {
    
    
    // MARK: Functions
    
    // Prey command
    override func start() {
        PreyLogger("Start alert")

        // Check message
        guard let message = self.options?.object(forKey: kOptions.MESSAGE.rawValue) as? String else {
            PreyLogger("Alert: error reading message")
            let parameters = getParamsTo(kAction.alert.rawValue, command: kCommand.stop.rawValue, status: kStatus.stopped.rawValue)
            self.sendData(parameters, toEndpoint: responseDeviceEndpoint)
            return
        }
        
        PreyLogger("Alert message: \(message)")
        
        // Only show a notification in background, otherwise show the alert view
        if UIApplication.shared.applicationState == .background {
            // Send a single notification when in background
            let content = UNMutableNotificationContent()
            content.title = "Prey Alert"
            content.body = message
            content.sound = UNNotificationSound.default
            content.categoryIdentifier = categoryNotifPreyAlert
            
            // Add action ID to user info
            if let triggerId = self.triggerId {
                content.userInfo = [
                    kOptions.IDLOCAL.rawValue: message,
                    kOptions.trigger_id.rawValue: triggerId
                ]
            } else {
                content.userInfo = [kOptions.IDLOCAL.rawValue: message]
            }
            
            // Create trigger with no delay
            let request = UNNotificationRequest(
                identifier: "prey.alert.\(UUID().uuidString)",
                content: content,
                trigger: nil // Fire immediately
            )
            
            // Add the notification request
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    PreyLogger("Error displaying notification: \(error.localizedDescription)")
                } else {
                    PreyLogger("Alert notification scheduled successfully")
                }
            }
        } else {
            // In foreground, just show the alert view
            showAlertVC(message)
        }
        
        // Send start action
        let params = getParamsTo(kAction.alert.rawValue, command: kCommand.start.rawValue, status: kStatus.started.rawValue)
        self.sendData(params, toEndpoint: responseDeviceEndpoint)
        
        let action = self
        DispatchQueue.main.async {
            sleep(4)
            let paramsStopped = action.getParamsTo(kAction.alert.rawValue, command: kCommand.start.rawValue, status: kStatus.stopped.rawValue)
            action.sendData(paramsStopped, toEndpoint: responseDeviceEndpoint)
        }
    }
    
    // Show AlertVC
    func showAlertVC(_ msg:String) {
        
        // Get SharedApplication delegate
        guard let appWindow = UIApplication.shared.delegate?.window else {
            PreyLogger("error with sharedApplication")
            return
        }
        
        let mainStoryboard: UIStoryboard    = UIStoryboard(name:StoryboardIdVC.PreyStoryBoard.rawValue, bundle: nil)
        
        if let resultController = mainStoryboard.instantiateViewController(withIdentifier: StoryboardIdVC.alert.rawValue) as? AlertVC {
            
            resultController.messageToShow      = msg
            let rootVC: UINavigationController  = mainStoryboard.instantiateViewController(withIdentifier: StoryboardIdVC.navigation.rawValue) as! UINavigationController            
            rootVC.setViewControllers([resultController], animated: false)
            appWindow?.rootViewController = rootVC
        }
    }
}
