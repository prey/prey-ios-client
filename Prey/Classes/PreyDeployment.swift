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
    private init() {
    }
    
    
    // MARK: Properties
    
    // The Managed app configuration dictionary pushed down from an MDM server are stored in this key.
    let kConfigurationKey       = "com.apple.configuration.managed"
    
    // The dictionary that is sent back to the MDM server as feedback must be stored in this key.
    let kFeedbackKey            = "com.apple.feedback.managed"

    let kConfigurationApiKey    = "apiKeyPrey"
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
            let path                = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
            let publicDocoumentsDir = path.first! as NSString
            let files               = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(publicDocoumentsDir as String)

            for file:NSString in files {
                if (file.pathExtension.compare("prey", options:.CaseInsensitiveSearch, range:nil, locale:nil) == NSComparisonResult.OrderedSame) {
                    let fullPath = publicDocoumentsDir.stringByAppendingPathComponent(file as String)
                    preyFiles.addObject(fullPath)
                }
            }
            
            if preyFiles.count == 0 {
                return
            }
            
            guard let fileData = NSData(contentsOfFile: preyFiles.objectAtIndex(0) as! String) else {
                return
            }
            
            guard let apiKeyUser = NSString(data:fileData, encoding:NSUTF8StringEncoding) else {
                return
            }

            // Add device to panel
            addDeviceWith(apiKeyUser as String, fromQRCode:false)
            
        } catch let error as NSError{
            print("files error: \(error.localizedDescription)")
            return
        }
    }

    // Check defaults values
    func readDefaultsValues() -> Bool {
        
        var successValue = false
        
        guard let serverConfig = NSUserDefaults.standardUserDefaults().dictionaryForKey(kConfigurationKey) else {
            successManagedAppConfig(successValue)
            return successValue
        }
        
        guard let serverApiKey:String = serverConfig[kConfigurationApiKey] as? String else {
            successManagedAppConfig(successValue)
            return successValue
        }
        
        // Add device to panel
        addDeviceWith(serverApiKey, fromQRCode:false)
        
        successValue = true
        
        successManagedAppConfig(successValue)
        return successValue
    }
    
    // Add Device with apiKey
    func addDeviceWith(apiKey:String, fromQRCode:Bool) {
        
        PreyConfig.sharedInstance.userApiKey = apiKey
        
        // Add Device to Panel Prey
        PreyDevice.addDeviceWith({(isSuccess: Bool) in
            
            dispatch_async(dispatch_get_main_queue()) {
                // AddDevice isn't success
                guard isSuccess else {
                    // Hide ActivityIndicator
                    //actInd.stopAnimating()
                    return
                }

                PreyConfig.sharedInstance.isPro = fromQRCode ? false : true
                PreyConfig.sharedInstance.saveValues()
                
                // Show CongratVC
                self.showCongratsVC()
            }
        })

    }
    
    // Show CongratsVC
    func showCongratsVC() {
        
        // Get SharedApplication delegate
        guard let appWindow = UIApplication.sharedApplication().delegate?.window else {
            print("error with sharedApplication")
            return
        }
        
        let mainStoryboard : UIStoryboard = UIStoryboard(name:StoryboardIdVC.PreyStoryBoard.rawValue, bundle: nil)
        
        // Add Device Success
        if let resultController = mainStoryboard.instantiateViewControllerWithIdentifier(StoryboardIdVC.deviceSetUp.rawValue) as? DeviceSetUpVC {

            let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController
            resultController.messageTxt = "Congratulations! You have successfully associated this iOS device with your Prey account.".localized
            navigationController.pushViewController(resultController, animated: true)
        }        
    }
    
    // SuccessManagedAppConfig
    func successManagedAppConfig(isSuccess:Bool) {
        
        guard var feedback = NSUserDefaults.standardUserDefaults().dictionaryForKey(kFeedbackKey) else {
            let newFeedback = [kFeedbackKey : isSuccess]
            NSUserDefaults.standardUserDefaults().setObject(newFeedback, forKey:kFeedbackKey)
            return
        }
        feedback[kFeedbackKey] = isSuccess
        NSUserDefaults.standardUserDefaults().setObject(feedback, forKey:kFeedbackKey)
    }
}


