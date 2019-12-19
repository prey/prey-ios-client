//
//  PreyDeployment.swift
//  Prey
//
//  Created by Javier Cala Uribe on 19/07/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

class PreyDeployment {
    
    
    // MARK: Singleton
    
    static let sharedInstance   = PreyDeployment()
    fileprivate init() {
    }
    
    
    // MARK: Properties
    
    // The Managed app configuration dictionary pushed down from an MDM server are stored in this key.
    let kConfigurationKey       = "com.apple.configuration.managed"
    
    // The dictionary that is sent back to the MDM server as feedback must be stored in this key.
    let kFeedbackKey            = "com.apple.feedback.managed"

    let kConfigurationApiKey    = "apiKeyPrey"
    let kConfigurationDeviceKey = "deviceKeyPrey"
    let kFeedbackSuccessKey     = "success"

    
    // MARK: Methods
    
    // Run deployment
    func runPreyDeployment() {
        
        // Check read defaults values
        guard !readDefaultsValues() else {
            return
        }

        do {
            // Check if config prey file exist
            let preyFiles           = NSMutableArray()
            let path                = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let publicDocoumentsDir = path.first! as NSString
            let files               = try FileManager.default.contentsOfDirectory(atPath: publicDocoumentsDir as String) as [NSString]

            for file in files {
                if (file.pathExtension.compare("prey", options:.caseInsensitive, range:nil, locale:nil) == ComparisonResult.orderedSame) {
                    let fullPath = publicDocoumentsDir.appendingPathComponent(file as String)
                    preyFiles.add(fullPath)
                }
            }
            
            if preyFiles.count == 0 {
                return
            }
            
            guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: preyFiles.object(at: 0) as! String)) else {
                return
            }
            
            guard let apiKeyUser = NSString(data:fileData, encoding:String.Encoding.utf8.rawValue) else {
                return
            }

            // Add device to panel
            addDeviceWith(apiKeyUser as String, fromQRCode:false)
            
        } catch let error as NSError{
            PreyLogger("files error: \(error.localizedDescription)")
            return
        }
    }

    // Check defaults values
    func readDefaultsValues() -> Bool {
        
        var successValue = false
        
        guard let serverConfig = UserDefaults.standard.dictionary(forKey: kConfigurationKey) else {
            successManagedAppConfig(successValue)
            return successValue
        }
        
        guard let serverApiKey:String = serverConfig[kConfigurationApiKey] as? String else {
            successManagedAppConfig(successValue)
            return successValue
        }
        
        // Check if file configuration has deviceKey
        if let serverDeviceKey:String = serverConfig[kConfigurationDeviceKey] as? String, serverDeviceKey != "" {
            addDeviceWith(serverApiKey, deviceKey:serverDeviceKey)
        } else {
            // Add device to panel
            addDeviceWith(serverApiKey, fromQRCode:false)
        }        
        
        successValue = true
        
        successManagedAppConfig(successValue)
        return successValue
    }
    
    // Add Device with userApiKey and deviceKey
    func addDeviceWith(_ apiKey:String, deviceKey:String) {
        PreyConfig.sharedInstance.userApiKey    = apiKey
        PreyConfig.sharedInstance.deviceKey     = deviceKey
        PreyConfig.sharedInstance.isRegistered  = true
        PreyConfig.sharedInstance.validationUserEmail = PreyUserEmailValidation.active.rawValue
        PreyConfig.sharedInstance.isTouchIDEnabled = true
        PreyConfig.sharedInstance.saveValues()
        // Show CongratVC
        self.showCongratsVC()
    }
    
    // Add Device with apiKey
    func addDeviceWith(_ apiKey:String, fromQRCode:Bool) {

        var actInd = UIActivityIndicatorView()
        
        if fromQRCode {
            let appWindow   = UIApplication.shared.delegate?.window
            let navigationController:UINavigationController = appWindow!!.rootViewController as! UINavigationController
            // Show ActivityIndicator
            actInd          = UIActivityIndicatorView(initInView: navigationController.view, withText: "Attaching device...".localized)
            navigationController.view.addSubview(actInd)
            actInd.startAnimating()
        }
        
        PreyConfig.sharedInstance.userApiKey = apiKey
        
        // Add Device to Panel Prey
        PreyDevice.addDeviceWith({(isSuccess: Bool) in
            
            DispatchQueue.main.async {

                // Hide ActivityIndicator
                if fromQRCode {
                    actInd.stopAnimating()
                }

                // AddDevice isn't success
                guard isSuccess else {
                    return
                }
                
                PreyConfig.sharedInstance.isPro = true
                PreyConfig.sharedInstance.saveValues()
                
                // Show CongratVC
                self.showCongratsVC()
            }
        })

    }
    
    // Show CongratsVC
    func showCongratsVC() {
        
        // Get SharedApplication delegate
        guard let appWindow = UIApplication.shared.delegate?.window else {
            PreyLogger("error with sharedApplication")
            return
        }
        
        let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController
        if let homeWebVC:HomeWebVC = navigationController.topViewController as? HomeWebVC {
            homeWebVC.loadViewOnWebView("permissions")
        }
    }
    
    // SuccessManagedAppConfig
    func successManagedAppConfig(_ isSuccess:Bool) {
        
        guard var feedback = UserDefaults.standard.dictionary(forKey: kFeedbackKey) else {
            let newFeedback = [kFeedbackKey : isSuccess]
            UserDefaults.standard.set(newFeedback, forKey:kFeedbackKey)
            return
        }
        feedback[kFeedbackKey] = isSuccess
        UserDefaults.standard.set(feedback, forKey:kFeedbackKey)
    }
}


