//
//  Alert.swift
//  Prey
//
//  Created by Javier Cala Uribe on 29/06/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
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
        
        // Show message
        if UIApplication.shared.applicationState != .background {
           showAlertVC(message)
        } else {
             if #available(iOS 10.0, *) {
                let content = UNMutableNotificationContent()
                let userInfoLocalNotification:[String: String] = [kOptions.IDLOCAL.rawValue : message]
                content.userInfo = userInfoLocalNotification
                content.categoryIdentifier = categoryNotifPreyAlert
                content.body = message
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
             } else {
                // Legacy local notification
                let localNotif:UILocalNotification = UILocalNotification()
                let userInfoLocalNotification:[String: String] = [kOptions.IDLOCAL.rawValue : message]
                localNotif.userInfo     = userInfoLocalNotification
                localNotif.alertBody    = message
                localNotif.hasAction    = false
                UIApplication.shared.presentLocalNotificationNow(localNotif)
            }
        }
        
        // Send start action
        let params  = getParamsTo(kAction.alert.rawValue, command: kCommand.start.rawValue, status: kStatus.started.rawValue)
        self.sendData(params, toEndpoint: responseDeviceEndpoint)
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
