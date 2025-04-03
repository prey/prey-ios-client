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
        // First ensure we have authorization
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            PreyLogger("Notification authorization request result: \(granted)")
            if let error = error {
                PreyLogger("Notification authorization error: \(error.localizedDescription)")
                return
            }
            
            guard granted else {
                PreyLogger("Notification permission not granted")
                return
            }
            
            DispatchQueue.main.async {
                let content = UNMutableNotificationContent()
                
                // Set notification content with higher priority
                content.title = "Prey Alert"
                content.body = message
                content.sound = UNNotificationSound.defaultCritical
                content.categoryIdentifier = categoryNotifPreyAlert
                content.threadIdentifier = "prey.alerts"
                
                // Set to critical to ensure delivery (iOS 15+)
                content.interruptionLevel = .critical
                
                // Add action ID to user info
                if let triggerId = self.triggerId {
                    content.userInfo = [
                        kOptions.IDLOCAL.rawValue: message,
                        kOptions.trigger_id.rawValue: triggerId,
                        "alert_id": UUID().uuidString // Add unique ID for tracking
                    ]
                } else {
                    content.userInfo = [
                        kOptions.IDLOCAL.rawValue: message,
                        "alert_id": UUID().uuidString
                    ]
                }
                
                // Create immediate trigger
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                
                // Create the request with a unique identifier
                let requestId = "prey.alert.\(UUID().uuidString)"
                let request = UNNotificationRequest(
                    identifier: requestId,
                    content: content,
                    trigger: trigger
                )
                
                // Schedule the notification
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        PreyLogger("Error displaying notification: \(error.localizedDescription)")
                    } else {
                        PreyLogger("Alert notification scheduled successfully with ID: \(requestId)")
                    }
                }
                
                // For critical alerts, try a second notification with a slight delay as backup
                if UIApplication.shared.applicationState == .background {
                    // Create a second trigger with a slight delay
                    let backupTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
                    let backupRequest = UNNotificationRequest(
                        identifier: "prey.alert.backup.\(UUID().uuidString)",
                        content: content,
                        trigger: backupTrigger
                    )
                    
                    UNUserNotificationCenter.current().add(backupRequest) { error in
                        if let error = error {
                            PreyLogger("Error displaying backup notification: \(error.localizedDescription)")
                        }
                    }
                }
            }
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
