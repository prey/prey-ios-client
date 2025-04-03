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
        
        // Always show a notification regardless of app state
        displayNotification(message)
        
        // Also show in-app alert if app is in foreground
        if UIApplication.shared.applicationState != .background {
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
    
    // Display notification regardless of app state
    private func displayNotification(_ message: String) {
        if #available(iOS 10.0, *) {
            let content = UNMutableNotificationContent()
            
            // Set notification content
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
            
            // Create immediate trigger
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            // Create the request
            let request = UNNotificationRequest(
                identifier: "prey.alert.\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            
            // Schedule the notification
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    PreyLogger("Error displaying notification: \(error.localizedDescription)")
                } else {
                    PreyLogger("Alert notification scheduled successfully")
                }
            }
            
            // Request authorization if needed
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                if settings.authorizationStatus != .authorized {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        PreyLogger("Notification authorization request result: \(granted)")
                        if let error = error {
                            PreyLogger("Notification authorization error: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } else {
            // Legacy local notification for iOS 9
            let localNotif = UILocalNotification()
            
            // Set notification content
            localNotif.alertTitle = "Prey Alert"
            localNotif.alertBody = message
            localNotif.soundName = UILocalNotificationDefaultSoundName
            localNotif.applicationIconBadgeNumber = 1
            localNotif.hasAction = true
            
            // Add action ID to user info
            if let triggerId = self.triggerId {
                localNotif.userInfo = [
                    kOptions.IDLOCAL.rawValue: message,
                    kOptions.trigger_id.rawValue: triggerId
                ]
            } else {
                localNotif.userInfo = [kOptions.IDLOCAL.rawValue: message]
            }
            
            // Present the notification immediately
            UIApplication.shared.presentLocalNotificationNow(localNotif)
            PreyLogger("Legacy alert notification scheduled")
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
