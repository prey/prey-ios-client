//
//  PreyHTTPResponse.swift
//  Prey
//
//  Created by Javier Cala Uribe on 4/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation

// Prey Request Tpype
enum RequestType {
    case GetToken, LogIn, SignUp, AddDevice, DeleteDevice, SubscriptionReceipt
}


class PreyHTTPResponse {

    // MARK: Functions

    // Check Response from Server
    class func checkResponse(requestType:RequestType, onCompletion:(isSuccess: Bool) -> Void) -> (NSData?, NSURLResponse?, NSError?) -> Void {
    

        let completionResponse: (NSData?, NSURLResponse?, NSError?) -> Void = ({(data, response, error) in

            // Check error with NSURLSession request
            guard error == nil else {
                callResponseWith(requestType, isResponseSuccess:false, withData:data, withError:error, statusCode:nil, onCompletion:onCompletion)
                return
            }

            //PreyLogger("PreyResponse: data:\(data) \nresponse:\(response) \nerror:\(error)")
            
            let httpURLResponse = response as! NSHTTPURLResponse
            let code            = httpURLResponse.statusCode
            let success         = (200...299 ~= code) ? true : false

            callResponseWith(requestType, isResponseSuccess:success, withData:data, withError:error, statusCode:code, onCompletion:onCompletion)
        })
        
        return completionResponse
    }
    
    // Check Request Type
    class func callResponseWith(requestType:RequestType, isResponseSuccess:Bool, withData data:NSData?, withError error:NSError?, statusCode code:Int?, onCompletion:(isSuccess:Bool) -> Void) {
        
        switch requestType {
            
        case .GetToken:
            checkToken(isResponseSuccess, withData:data, withError:error, statusCode:code)
            
        case .LogIn:
            checkLogIn(isResponseSuccess, withData:data, withError:error, statusCode:code)
            
        case .SignUp:
            checkSignUp(isResponseSuccess, withData:data, withError:error, statusCode:code)
            
        case .AddDevice:
            checkAddDevice(isResponseSuccess, withData:data, withError:error, statusCode:code)
            
        case .DeleteDevice:
            checkDeleteDevice(isResponseSuccess, withData:data, withError:error, statusCode:code)

        case .SubscriptionReceipt:
            checkSubscriptionReceipt(isResponseSuccess, withData:data, withError:error, statusCode:code)
        }

        onCompletion(isSuccess:isResponseSuccess)
    }
    
    // Check Get Token response
    class func checkToken(isSuccess:Bool, withData data:NSData?, withError error:NSError?, statusCode:Int?) {
        
        if isSuccess {
            let jsonObject: NSDictionary
            
            do {
                guard let dataResponse = data else {
                    return
                }
                jsonObject = try NSJSONSerialization.JSONObjectWithData(dataResponse, options:NSJSONReadingOptions.MutableContainers) as! NSDictionary
                
                if let tokenPanelStr = jsonObject.objectForKey("token") as? String {
                    PreyConfig.sharedInstance.tokenPanel = tokenPanelStr
                    PreyConfig.sharedInstance.saveValues()
                }
            } catch let error as NSError{
                PreyLogger("json error: \(error.localizedDescription)")
            }
            
        } else {
            showErrorLogIn(error, statusCode:statusCode)
        }
    }
    
    // Check LogIn response
    class func checkLogIn(isSuccess:Bool, withData data:NSData?, withError error:NSError?, statusCode:Int?) {
        
        if isSuccess {
            let jsonObject: NSDictionary
            
            do {
                guard let dataResponse = data else {
                    return
                }
                jsonObject = try NSJSONSerialization.JSONObjectWithData(dataResponse, options:NSJSONReadingOptions.MutableContainers) as! NSDictionary
                
                guard let userApiKeyStr = jsonObject.objectForKey("key") as? String else {
                    return
                }
                guard let userIsProStr = jsonObject.objectForKey("pro_account") as? NSString else {
                    return
                }
                
                PreyConfig.sharedInstance.userApiKey    = userApiKeyStr
                PreyConfig.sharedInstance.isPro         = userIsProStr.boolValue
                PreyConfig.sharedInstance.saveValues()
                
            } catch let error as NSError{
                PreyLogger("json error: \(error.localizedDescription)")
            }
        } else {
            showErrorLogIn(error, statusCode:statusCode)
        }
    }
    
    class func showErrorLogIn(error:NSError?, statusCode:Int?) {
        // Check error with NSURLSession request
        guard error == nil else {
            let alertMessage = (error?.localizedRecoverySuggestion != nil) ? error?.localizedRecoverySuggestion : error?.localizedDescription
            displayErrorAlert(alertMessage!.localized, titleMessage:"Couldn't check your password".localized)
            return
        }
        
        let alertMessage: String
        
        if statusCode == 401 {
            alertMessage = (PreyConfig.sharedInstance.userEmail != nil) ? "Please make sure the password you entered is valid." : "There was a problem getting your account information. Please make sure the email address you entered is valid, as well as your password."
        } else {
            alertMessage = "Error"
        }
        
        displayErrorAlert(alertMessage.localized, titleMessage:"Couldn't check your password".localized)
    }
    
    // Check signUp response
    class func checkSignUp(isSuccess:Bool, withData data:NSData?, withError error:NSError?, statusCode:Int?) {
        
        if isSuccess {
            let jsonObject: NSDictionary
            
            do {
                guard let dataResponse = data else {
                    return
                }
                jsonObject = try NSJSONSerialization.JSONObjectWithData(dataResponse, options:NSJSONReadingOptions.MutableContainers) as! NSDictionary
                
                if let userApiKeyStr = jsonObject.objectForKey("key") as? String {
                    PreyConfig.sharedInstance.userApiKey = userApiKeyStr
                    PreyConfig.sharedInstance.saveValues()
                }
                
            } catch let error as NSError{
                PreyLogger("json error: \(error.localizedDescription)")
            }
        } else {
            // Check error with NSURLSession request
            guard error == nil else {
                let alertMessage = (error?.localizedRecoverySuggestion != nil) ? error?.localizedRecoverySuggestion : error?.localizedDescription
                displayErrorAlert(alertMessage!.localized, titleMessage:"User couldn't be created".localized)
                return
            }

            let alertMessage = (statusCode == 422) ? "Did you already register?".localized : "Error".localized
            displayErrorAlert(alertMessage.localized, titleMessage:"User couldn't be created".localized)
        }
    }
    
    // Check add device response
    class func checkAddDevice(isSuccess:Bool, withData data:NSData?, withError error:NSError?, statusCode:Int?) {

        if isSuccess {
            let jsonObject: NSDictionary
            
            do {
                guard let dataResponse = data else {
                    return
                }
                jsonObject = try NSJSONSerialization.JSONObjectWithData(dataResponse, options:NSJSONReadingOptions.MutableContainers) as! NSDictionary
                
                if let deviceKeyStr = jsonObject.objectForKey("key") as? String {
                    PreyConfig.sharedInstance.deviceKey     = deviceKeyStr
                    PreyConfig.sharedInstance.isRegistered  = true
                    PreyConfig.sharedInstance.saveValues()
                }
                
            } catch let error as NSError{
                PreyLogger("json error: \(error.localizedDescription)")
            }
        } else {
            // Check error with NSURLSession request
            guard error == nil else {
                let alertMessage = (error?.localizedRecoverySuggestion != nil) ? error?.localizedRecoverySuggestion : error?.localizedDescription
                displayErrorAlert(alertMessage!.localized, titleMessage:"Couldn't add your device".localized)
                return
            }

            let alertMessage: String
            
            if ( (statusCode == 302) || (statusCode == 403) ) {
                alertMessage = "It seems you've reached your limit for devices on the Control Panel. Try removing this device from your account if you had already added.".localized
            } else {
                alertMessage = "Error".localized
            }

            displayErrorAlert(alertMessage.localized, titleMessage:"Couldn't add your device".localized)
        }
    }

    // Check delete device response
    class func checkDeleteDevice(isSuccess:Bool, withData data:NSData?, withError error:NSError?, statusCode:Int?) {
        
        if !isSuccess {
            // Check error with NSURLSession request
            guard error == nil else {
                let alertMessage = (error?.localizedRecoverySuggestion != nil) ? error?.localizedRecoverySuggestion : error?.localizedDescription
                displayErrorAlert(alertMessage!.localized, titleMessage:"Couldn't delete your device".localized)
                return
            }
            
            let titleMsg = "Couldn't delete your device".localized
            let alertMsg = "Device not ready!".localized
            displayErrorAlert(alertMsg, titleMessage:titleMsg)
        }
    }

    // Check subsciption receipt
    class func checkSubscriptionReceipt(isSuccess:Bool, withData data:NSData?, withError error:NSError?, statusCode:Int?) {
        
        if !isSuccess {
            // Check error with NSURLSession request
            guard error == nil else {
                let alertMessage = (error?.localizedRecoverySuggestion != nil) ? error?.localizedRecoverySuggestion : error?.localizedDescription
                displayErrorAlert(alertMessage!.localized, titleMessage:"Error".localized)
                return
            }
            
            let titleMsg = "Error".localized
            let alertMsg = "Transaction Error".localized
            displayErrorAlert(alertMsg, titleMessage:titleMsg)
        }
    }
    
    // Check action device response
    class func checkActionDevice() -> (NSData?, NSURLResponse?, NSError?) -> Void {
        
        let actionDeviceResponse: (NSData?, NSURLResponse?, NSError?) -> Void = { (data, response, error) in
            
            // Check error with NSURLSession request
            guard error == nil else {
                
                let alertMessage = (error?.localizedRecoverySuggestion != nil) ? error?.localizedRecoverySuggestion : error?.localizedDescription
                PreyLogger("Error: \(alertMessage)")
                PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
                
                return
            }
            
            //PreyLogger("GET Devices/: data:\(data) \nresponse:\(response) \nerror:\(error)")
            
            let httpURLResponse = response as! NSHTTPURLResponse
            
            switch httpURLResponse.statusCode {
                
            // === Success
            case 200...299:
                guard let dataResponse = data else {
                    PreyLogger("Failed to check action from panel")
                    PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
                    return
                }
                if let actionArray: String = String(data:dataResponse, encoding:NSUTF8StringEncoding) {
                    dispatch_async(dispatch_get_main_queue()) {
                        PreyModule.sharedInstance.parseActionsFromPanel(actionArray)
                    }
                } else {
                    PreyLogger("Failed to check action from panel")
                    PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)                    
                }
                
            // === Error
            default:
                PreyLogger("Failed to check action from panel")
                PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
            }
        }
        
        return actionDeviceResponse
    }    

    // Check add device response
    class func checkGeofenceZones(action:Geofencing) -> (NSData?, NSURLResponse?, NSError?) -> Void {
        
        let geofenceZonesResponse: (NSData?, NSURLResponse?, NSError?) -> Void = ({(data, response, error) in
            
            // Check error with NSURLSession request
            guard error == nil else {
                PreyLogger("PreyGeofenceZones error")
                return
            }
            
            //PreyLogger("PreyGeofence: data:\(data) \nresponse:\(response) \nerror:\(error)")
            
            let httpURLResponse = response as! NSHTTPURLResponse
            
            switch httpURLResponse.statusCode {
                
            // === Success
            case 200...299:
                
                guard let dataResponse = data else {
                    PreyLogger("Errod reading request data")
                    return
                }
                
                guard let jsonObject: String = String(data:dataResponse, encoding:NSUTF8StringEncoding) else {
                    PreyLogger("Error reading json data")
                    return
                }
                
                // Convert actionsArray from String to NSData
                guard let jsonData: NSData = jsonObject.dataUsingEncoding(NSUTF8StringEncoding) else {
                    PreyLogger("Error jsonObject to NSData")
                    return
                }
                
                // Convert NSData to NSArray
                let jsonArray: NSArray
                
                do {
                    jsonArray = try NSJSONSerialization.JSONObjectWithData(jsonData, options:NSJSONReadingOptions.MutableContainers) as! NSArray
                    action.updateGeofenceZones(jsonArray)
                    
                } catch let error as NSError{
                    PreyLogger("json error: \(error.localizedDescription)")
                }
                
            // === Error
            default:
                PreyLogger("Failed data send")
            }
        })
        
        return geofenceZonesResponse
    }
    
    // Check Data Send response
    class func checkDataSend(action:PreyAction?) -> (NSData?, NSURLResponse?, NSError?) -> Void {
        
        let dataResponse: (NSData?, NSURLResponse?, NSError?) -> Void = { (data, response, error) in
            
            // Check error with NSURLSession request
            guard error == nil else {
                
                let alertMessage = (error?.localizedRecoverySuggestion != nil) ? error?.localizedRecoverySuggestion : error?.localizedDescription
                PreyLogger("Error: \(alertMessage)")
                
                return
            }
            
            let httpURLResponse = response as! NSHTTPURLResponse
            
            switch httpURLResponse.statusCode {
                
            // === Success
            case 200...299:
                PreyLogger("Data send: OK")
                if let preyAction = action {
                    PreyModule.sharedInstance.checkStatus(preyAction)
                }
                
            // === Stop report
            case 409:
                PreyLogger("Stop report")
                if let preyAction:Report = action as? Report {
                    preyAction.stopReport()
                }                
                
            // === Error
            default:
                PreyLogger("Failed data send")
            }
        }
        
        return dataResponse
    }
}

