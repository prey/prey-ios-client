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

class Alert: PreyAction, @unchecked Sendable {
    
    
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
        
        // Send start action and, upon completion, send stopped to close lifecycle in order
        let params = getParamsTo(kAction.alert.rawValue, command: kCommand.start.rawValue, status: kStatus.started.rawValue)
        if let username = PreyConfig.sharedInstance.userApiKey, PreyConfig.sharedInstance.isRegistered {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(
                username,
                password: "x",
                params: params,
                messageId: self.messageId,
                httpMethod: Method.POST.rawValue,
                endPoint: responseDeviceEndpoint,
                onCompletion: PreyHTTPResponse.checkResponse(
                    RequestType.dataSend,
                    preyAction: self,
                    onCompletion: { [weak self] (_: Bool) in
                        guard let self = self else { return }
                        let stopParams = self.getParamsTo(kAction.alert.rawValue, command: kCommand.start.rawValue, status: kStatus.stopped.rawValue)
                        PreyHTTPClient.sharedInstance.userRegisterToPrey(
                            username,
                            password: "x",
                            params: stopParams,
                            messageId: self.messageId,
                            httpMethod: Method.POST.rawValue,
                            endPoint: responseDeviceEndpoint,
                            onCompletion: PreyHTTPResponse.checkResponse(RequestType.dataSend, preyAction: self, onCompletion: { _ in PreyLogger("Alert start->stop cycle sent") })
                        )
                    }
                )
            )
        } else {
            PreyLogger("Alert: cannot send start/stop - missing API key or not registered")
        }
        
        // Only show a notification in background, otherwise show the alert view
        // Fix: Check app state on main thread to avoid Main Thread Checker warning
        var isAppInBackground = false
        if Thread.isMainThread {
            isAppInBackground = UIApplication.shared.applicationState == .background
        } else {
            DispatchQueue.main.sync {
                isAppInBackground = UIApplication.shared.applicationState == .background
            }
        }
        
        if isAppInBackground {
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
            UNUserNotificationCenter.current().add(request) { [weak self] error in
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
    }
    
    // Show AlertVC
    func showAlertVC(_ msg:String) {
        
        // Ensure we're on the main thread for UI operations
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.showAlertVC(msg)
            }
            return
        }

        // Get SharedApplication delegate
        guard let appWindow = UIApplication.shared.delegate?.window else {
            PreyLogger("error with sharedApplication")
            return
        }
        
        // Load storyboard and controller asynchronously to avoid blocking UI
        let mainStoryboard: UIStoryboard = UIStoryboard(name:StoryboardIdVC.PreyStoryBoard.rawValue, bundle: nil)
        
        if let resultController = mainStoryboard.instantiateViewController(withIdentifier: StoryboardIdVC.alert.rawValue) as? AlertVC {
            
            resultController.messageToShow = msg
            resultController.messageToShow = msg
                        let rootVC: UINavigationController = mainStoryboard.instantiateViewController(withIdentifier: StoryboardIdVC.navigation.rawValue) as! UINavigationController   
            rootVC.setViewControllers([resultController], animated: false)
            appWindow?.rootViewController = rootVC
            appWindow?.makeKeyAndVisible()
            
            PreyLogger("Alert view controller displayed")
        }else{
            PreyLogger("Failed to instantiate alert controller")
        }
    }
}
