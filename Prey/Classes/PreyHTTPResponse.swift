//
//  PreyHTTPResponse.swift
//  Prey
//
//  Created by Javier Cala Uribe on 4/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation

class PreyHTTPResponse {

    // MARK: Functions
    
    // Check logIn response
    class func checkLogIn(onCompletion:(isSuccess: Bool) -> Void) -> (NSData?, NSURLResponse?, NSError?) -> Void {
        
        let logInResponse: (NSData?, NSURLResponse?, NSError?) -> Void = ({(data, response, error) in
            
            // Check error with NSURLSession request
            guard error == nil else {
                
                let alertMessage = (error?.localizedRecoverySuggestion != nil) ? error?.localizedRecoverySuggestion : error?.localizedDescription
                displayErrorAlert(alertMessage!.localized, titleMessage:"Couldn't check your password".localized)
                onCompletion(isSuccess:false)
                
                return
            }
            
            print("PreyUser: data:\(data) \nresponse:\(response) \nerror:\(error)")
            
            let httpURLResponse = response as! NSHTTPURLResponse
            
            switch httpURLResponse.statusCode {
                
            // === Success
            case 200...299:
                let jsonObject: NSDictionary
                
                do {
                    jsonObject = try NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers) as! NSDictionary
                    
                    let userApiKeyStr   = jsonObject.objectForKey("key") as! String
                    let userIsPro       = jsonObject.objectForKey("pro_account")!.boolValue as Bool
                    
                    PreyConfig.sharedInstance.userApiKey    = userApiKeyStr
                    PreyConfig.sharedInstance.isPro         = userIsPro
                    PreyConfig.sharedInstance.saveValues()
                    
                    onCompletion(isSuccess:true)
                    
                } catch let error as NSError{
                    print("json error: \(error.localizedDescription)")
                }
                
            // === Client Error
            case 401:
                let alertMessage = (PreyConfig.sharedInstance.userEmail != nil) ? "Please make sure the password you entered is valid." : "There was a problem getting your account information. Please make sure the email address you entered is valid, as well as your password."
                displayErrorAlert(alertMessage.localized, titleMessage:"Couldn't check your password".localized)
                onCompletion(isSuccess:false)
                
            // === Error
            default:
                let alertMessage = "Error";
                displayErrorAlert(alertMessage.localized, titleMessage:"Couldn't check your password".localized)
                onCompletion(isSuccess:false)
            }
        })
        
        return logInResponse
    }
    
    // Check signUp response
    class func checkSignUp(onCompletion:(isSuccess: Bool) -> Void) -> (NSData?, NSURLResponse?, NSError?) -> Void {
        
        let signUpResponse: (NSData?, NSURLResponse?, NSError?) -> Void = ({(data, response, error) in

            // Check error with NSURLSession request
            guard error == nil else {
                
                let alertMessage = (error?.localizedRecoverySuggestion != nil) ? error?.localizedRecoverySuggestion : error?.localizedDescription
                displayErrorAlert(alertMessage!.localized, titleMessage:"User couldn't be created".localized)
                onCompletion(isSuccess:false)
                
                return
            }
            
            print("PreyUser: data:\(data) \nresponse:\(response) \nerror:\(error)")
            
            let httpURLResponse = response as! NSHTTPURLResponse
            
            switch httpURLResponse.statusCode {
                
            // === Success
            case 200...299:
                let jsonObject: NSDictionary
                
                do {
                    jsonObject = try NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers) as! NSDictionary
                    
                    let userApiKeyStr = jsonObject.objectForKey("key") as! String
                    PreyConfig.sharedInstance.userApiKey = userApiKeyStr
                    PreyConfig.sharedInstance.saveValues()
                    
                    onCompletion(isSuccess:true)
                    
                } catch let error as NSError{
                    print("json error: \(error.localizedDescription)")
                }
                
            // === Client Error
            case 422:
                let alertMessage = "Did you already register?".localized
                displayErrorAlert(alertMessage, titleMessage:"Couldn't check your password".localized)
                onCompletion(isSuccess:false)
                
                // === Server Error
                /*case 503:
                 if reload > 0 {
                 // Retrying
                 let timeValue = dispatch_time(DISPATCH_TIME_NOW, Int64(delayTime * Double(NSEC_PER_SEC)))
                 //dispatch_after(timeValue, dispatch_get_main_queue(), { () -> Void in
                 //    self.userLogInToPrey(reload - 1, preyUser:preyUser, onCompletion:onCompletion)  })
                 } else {
                 
                 // Stop retrying
                 let alertMessage = (error?.localizedRecoverySuggestion != nil) ? error?.localizedRecoverySuggestion :
                 error?.localizedDescription;
                 dispatch_async(dispatch_get_main_queue()) {
                 displayErrorAlert(alertMessage!.localized, titleMessage:"Server Error".localized)
                 }
                 }*/
                
            // === Error
            default:
                let alertMessage = "Error".localized;
                displayErrorAlert(alertMessage, titleMessage:"User couldn't be created".localized)
                onCompletion(isSuccess:false)
            }
        })
        
        return signUpResponse
    }
    
    // Check add device response
    class func checkAddDevice(onCompletion:(isSuccess: Bool) -> Void) -> (NSData?, NSURLResponse?, NSError?) -> Void {
        
        let addDeviceResponse: (NSData?, NSURLResponse?, NSError?) -> Void = ({(data, response, error) in
            
            // Check error with NSURLSession request
            guard error == nil else {
                
                let alertMessage = (error?.localizedRecoverySuggestion != nil) ? error?.localizedRecoverySuggestion : error?.localizedDescription
                displayErrorAlert(alertMessage!.localized, titleMessage:"Couldn't add your device".localized)
                onCompletion(isSuccess: false)
                
                return
            }

            print("PreyDevice: data:\(data) \nresponse:\(response) \nerror:\(error)")
            
            let httpURLResponse = response as! NSHTTPURLResponse
            
            switch httpURLResponse.statusCode {
                
            // === Success
            case 200...299:
                let jsonObject: NSDictionary
                
                do {
                    jsonObject = try NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers) as! NSDictionary
                    
                    let deviceKeyStr = jsonObject.objectForKey("key") as! String
                    PreyConfig.sharedInstance.deviceKey     = deviceKeyStr
                    PreyConfig.sharedInstance.isRegistered  = true
                    PreyConfig.sharedInstance.saveValues()
                    
                    onCompletion(isSuccess:true)
                    
                } catch let error as NSError{
                    print("json error: \(error.localizedDescription)")
                }
                
            // === Client Error
            case 302, 403:
                let titleMsg = "Couldn't add your device".localized
                let alertMsg = "It seems you've reached your limit for devices on the Control Panel. Try removing this device from your account if you had already added.".localized
                displayErrorAlert(alertMsg, titleMessage:titleMsg)
                onCompletion(isSuccess:false)
                
            // === Error
            default:
                let titleMsg = "Couldn't add your device".localized
                let alertMsg = "Error".localized
                displayErrorAlert(alertMsg, titleMessage:titleMsg)
                onCompletion(isSuccess:false)
            }
        })
        
        return addDeviceResponse
    }

    // Check action device response
    class func checkActionDevice() -> (NSData?, NSURLResponse?, NSError?) -> Void {
        
        let actionDeviceResponse: (NSData?, NSURLResponse?, NSError?) -> Void = { (data, response, error) in
            
            // Check error with NSURLSession request
            guard error == nil else {
                
                let alertMessage = (error?.localizedRecoverySuggestion != nil) ? error?.localizedRecoverySuggestion : error?.localizedDescription
                print("Error: \(alertMessage)")
                PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
                
                return
            }
            
            //print("GET Devices/: data:\(data) \nresponse:\(response) \nerror:\(error)")
            
            let httpURLResponse = response as! NSHTTPURLResponse
            
            switch httpURLResponse.statusCode {
                
            // === Success
            case 200...299:

                if let actionArray: String = String(data: data!, encoding: NSUTF8StringEncoding) {
                    dispatch_async(dispatch_get_main_queue()) {
                        PreyModule.sharedInstance.parseActionsFromPanel(actionArray)
                    }
                } else {
                    print("Failed to check action from panel")
                    PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)                    
                }
                
            // === Error
            default:
                print("Failed to check action from panel")
                PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
            }
        }
        
        return actionDeviceResponse
    }
    
    // Check notificationID response
    class func checkNotificationId() -> (NSData?, NSURLResponse?, NSError?) -> Void {
        
        let notificationResponse: (NSData?, NSURLResponse?, NSError?) -> Void = { (data, response, error) in
            
            // Check error with NSURLSession request
            guard error == nil else {
                
                let alertMessage = (error?.localizedRecoverySuggestion != nil) ? error?.localizedRecoverySuggestion : error?.localizedDescription
                print("Error: \(alertMessage)")
                
                return
            }
            
            //print("Notification_id: data:\(data) \nresponse:\(response) \nerror:\(error)")
            
            let httpURLResponse = response as! NSHTTPURLResponse
            
            switch httpURLResponse.statusCode {
                
            // === Success
            case 200...299:
                print("Did register for remote notifications")
                
            // === Error
            default:
                print("Failed to register for remote notifications")
            }
        }
        
        return notificationResponse
    }
}

