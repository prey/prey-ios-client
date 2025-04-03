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
            // First ensure we have authorization
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
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
                    content.sound = UNNotificationSound.default
                    content.categoryIdentifier = categoryNotifPreyAlert
                    content.threadIdentifier = "prey.alerts"
                    
                    // Request critical alert authorization if needed
                    if #available(iOS 15.0, *) {
                        content.interruptionLevel = .timeSensitive
                    } else {
                        // Fallback on earlier versions
                    }
                    
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
        } else {
            // Legacy local notification for iOS 9
            let localNotif = UILocalNotification()
            
            // Set notification content
            localNotif.alertTitle = "Prey Alert"
            localNotif.alertBody = message
            localNotif.soundName = UILocalNotificationDefaultSoundName
            localNotif.applicationIconBadgeNumber = 1
            localNotif.hasAction = true
            localNotif.category = categoryNotifPreyAlert
            
            // Add action ID to user info
            if let triggerId = self.triggerId {
                localNotif.userInfo = [
                    kOptions.IDLOCAL.rawValue: message,
                    kOptions.trigger_id.rawValue: triggerId,
                    "alert_id": UUID().uuidString
                ]
            } else {
                localNotif.userInfo = [
                    kOptions.IDLOCAL.rawValue: message,
                    "alert_id": UUID().uuidString
                ]
            }
            
            // Present the notification immediately
            UIApplication.shared.presentLocalNotificationNow(localNotif)
            PreyLogger("Legacy alert notification scheduled")
            
            // If in background, try a second notification with delay as backup
            if UIApplication.shared.applicationState == .background {
                let backupNotif = UILocalNotification()
                backupNotif.alertTitle = "Prey Alert"
                backupNotif.alertBody = message
                backupNotif.soundName = UILocalNotificationDefaultSoundName
                backupNotif.applicationIconBadgeNumber = 1
                backupNotif.hasAction = true
                backupNotif.category = categoryNotifPreyAlert
                backupNotif.fireDate = Date(timeIntervalSinceNow: 1.0)
                
                // Add same user info
                backupNotif.userInfo = localNotif.userInfo
                
                // Schedule the backup notification
                UIApplication.shared.scheduleLocalNotification(backupNotif)
                PreyLogger("Backup legacy alert notification scheduled")
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
