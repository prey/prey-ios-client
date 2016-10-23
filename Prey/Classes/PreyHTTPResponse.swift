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
    case getToken, logIn, signUp, addDevice, deleteDevice, subscriptionReceipt, actionDevice, geofenceZones, dataSend
}

class PreyHTTPResponse {

    // MARK: Functions

    // Check Response from Server
    class func checkResponse(_ requestType:RequestType, preyAction:PreyAction?, onCompletion:@escaping (_ isSuccess: Bool) -> Void) -> (Data?, URLResponse?, Error?) -> Void {

        let completionResponse: (Data?, URLResponse?, Error?) -> Void = ({(data, response, error) in

            // Check error with URLSession request
            guard error == nil else {
                callResponseWith(requestType, isResponseSuccess:false, withAction:preyAction, withData:data, withError:error, statusCode:nil, onCompletion:onCompletion)
                return
            }

            //PreyLogger("PreyResponse: data:\(data) \nresponse:\(response) \nerror:\(error)")
            
            let httpURLResponse = response as! HTTPURLResponse
            let code            = httpURLResponse.statusCode
            let success         = (200...299 ~= code) ? true : false

            callResponseWith(requestType, isResponseSuccess:success, withAction:preyAction, withData:data, withError:error, statusCode:code, onCompletion:onCompletion)
        })
        
        return completionResponse
    }
    
    // Check Request Type
    class func callResponseWith(_ requestType:RequestType, isResponseSuccess:Bool, withAction action:PreyAction?, withData data:Data?, withError error:Error?, statusCode code:Int?, onCompletion:(_ isSuccess:Bool) -> Void) {
        
        switch requestType {
            
        case .getToken:
            checkToken(isResponseSuccess, withData:data, withError:error, statusCode:code)
            
        case .logIn:
            checkLogIn(isResponseSuccess, withData:data, withError:error, statusCode:code)
            
        case .signUp:
            checkSignUp(isResponseSuccess, withData:data, withError:error, statusCode:code)
            
        case .addDevice:
            checkAddDevice(isResponseSuccess, withData:data, withError:error, statusCode:code)
            
        case .deleteDevice:
            checkDeleteDevice(isResponseSuccess, withData:data, withError:error, statusCode:code)

        case .subscriptionReceipt:
            checkSubscriptionReceipt(isResponseSuccess, withData:data, withError:error, statusCode:code)

        case .actionDevice:
            checkActionDevice(isResponseSuccess, withData:data, withError:error, statusCode:code)

        case .geofenceZones:
            checkGeofenceZones(isResponseSuccess, withAction:action, withData:data, withError:error, statusCode:code)

        case .dataSend:
            checkDataSend(isResponseSuccess, withAction:action, withData:data, withError:error, statusCode:code)
        }

        onCompletion(isResponseSuccess)
    }
    
    // Check Get Token response
    class func checkToken(_ isSuccess:Bool, withData data:Data?, withError error:Error?, statusCode:Int?) {
        
        guard isSuccess else {
            showErrorLogIn(error, statusCode:statusCode)
            return
        }
        
        do {
            guard let dataResponse = data else {
                return
            }
            let jsonObject = try JSONSerialization.jsonObject(with: dataResponse, options:JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            if let tokenPanelStr = jsonObject.object(forKey: "token") as? String {
                PreyConfig.sharedInstance.tokenPanel = tokenPanelStr
                PreyConfig.sharedInstance.saveValues()
            }
        } catch let error {
            PreyLogger("json error: \(error.localizedDescription)")
        }
    }
    
    // Check LogIn response
    class func checkLogIn(_ isSuccess:Bool, withData data:Data?, withError error:Error?, statusCode:Int?) {
        
        guard isSuccess else {
            showErrorLogIn(error, statusCode:statusCode)
            return
        }
        
        do {
            guard let dataResponse = data else {
                return
            }
            let jsonObject = try JSONSerialization.jsonObject(with: dataResponse, options:JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            guard let userApiKeyStr = jsonObject.object(forKey: "key") as? String else {
                return
            }
            guard let userIsProStr = jsonObject.object(forKey: "pro_account") as? NSNumber else {
                return
            }
            
            PreyConfig.sharedInstance.userApiKey    = userApiKeyStr
            PreyConfig.sharedInstance.isPro         = userIsProStr.boolValue
            PreyConfig.sharedInstance.saveValues()
            
        } catch let error {
            PreyLogger("json error: \(error.localizedDescription)")
        }
    }
    
    class func showErrorLogIn(_ error:Error?, statusCode:Int?) {
        // Check error with URLSession request
        guard error == nil else {
            let alertMessage = error?.localizedDescription
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
    class func checkSignUp(_ isSuccess:Bool, withData data:Data?, withError error:Error?, statusCode:Int?) {
        
        guard isSuccess else {
            // Check error with URLSession request
            guard error == nil else {
                let alertMessage = error?.localizedDescription
                displayErrorAlert(alertMessage!.localized, titleMessage:"User couldn't be created".localized)
                return
            }
            let alertMessage = (statusCode == 422) ? "Did you already register?".localized : "Error".localized
            displayErrorAlert(alertMessage.localized, titleMessage:"User couldn't be created".localized)
            return
        }
        
        do {
            guard let dataResponse = data else {
                return
            }
            let jsonObject = try JSONSerialization.jsonObject(with: dataResponse, options:JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            if let userApiKeyStr = jsonObject.object(forKey: "key") as? String {
                PreyConfig.sharedInstance.userApiKey = userApiKeyStr
                PreyConfig.sharedInstance.saveValues()
            }
            
        } catch let error {
            PreyLogger("json error: \(error.localizedDescription)")
        }
    }
    
    // Check add device response
    class func checkAddDevice(_ isSuccess:Bool, withData data:Data?, withError error:Error?, statusCode:Int?) {

        guard isSuccess else {
            // Check error with URLSession request
            guard error == nil else {
                let alertMessage = error?.localizedDescription
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
            return
        }
        
        do {
            guard let dataResponse = data else {
                return
            }
            let jsonObject = try JSONSerialization.jsonObject(with: dataResponse, options:JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            if let deviceKeyStr = jsonObject.object(forKey: "key") as? String {
                PreyConfig.sharedInstance.deviceKey     = deviceKeyStr
                PreyConfig.sharedInstance.isRegistered  = true
                PreyConfig.sharedInstance.saveValues()
            }
            
        } catch let error {
            PreyLogger("json error: \(error.localizedDescription)")
        }
    }

    // Check delete device response
    class func checkDeleteDevice(_ isSuccess:Bool, withData data:Data?, withError error:Error?, statusCode:Int?) {
        
        if isSuccess {
            return
        }

        // Check error with URLSession request
        guard error == nil else {
            let alertMessage = error?.localizedDescription
            displayErrorAlert(alertMessage!.localized, titleMessage:"Couldn't delete your device".localized)
            return
        }
        
        let titleMsg = "Couldn't delete your device".localized
        let alertMsg = "Device not ready!".localized
        displayErrorAlert(alertMsg, titleMessage:titleMsg)
    }

    // Check subsciption receipt
    class func checkSubscriptionReceipt(_ isSuccess:Bool, withData data:Data?, withError error:Error?, statusCode:Int?) {
        
        if isSuccess {
            return
        }

        // Check error with URLSession request
        guard error == nil else {
            let alertMessage = error?.localizedDescription
            displayErrorAlert(alertMessage!.localized, titleMessage:"Error".localized)
            return
        }
        
        let titleMsg = "Error".localized
        let alertMsg = "Transaction Error".localized
        displayErrorAlert(alertMsg, titleMessage:titleMsg)
    }
    
    // Check action device response
    class func checkActionDevice(_ isSuccess:Bool, withData data:Data?, withError error:Error?, statusCode:Int?) {

        guard isSuccess else {
            // Check error with URLSession request
            guard error == nil else {
                PreyLogger("Error: \(error)")
                PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
                return
            }
            PreyLogger("Failed to check action from panel")
            PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
            return
        }
        
        guard let dataResponse = data else {
            PreyLogger("Failed to check action from panel")
            PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
            return
        }
        if let actionArray: String = String(data:dataResponse, encoding:String.Encoding.utf8) {
            DispatchQueue.main.async {
                PreyModule.sharedInstance.parseActionsFromPanel(actionArray)
            }
        } else {
            PreyLogger("Failed to check action from panel")
            PreyNotification.sharedInstance.checkRequestVerificationSucceded(false)
        }
    }

    // Check add device response
    class func checkGeofenceZones(_ isSuccess:Bool, withAction action:PreyAction?, withData data:Data?, withError error:Error?, statusCode:Int?) {
        
        guard isSuccess else {
            // Check error with URLSession request
            guard error == nil else {
                PreyLogger("PreyGeofenceZones error")
                return
            }
            PreyLogger("Failed data send")
            return
        }

        // === Success
        guard let dataResponse = data else {
            PreyLogger("Errod reading request data")
            return
        }
        guard let jsonObject: String = String(data:dataResponse, encoding:String.Encoding.utf8) else {
            PreyLogger("Error reading json data")
            return
        }
        // Convert actionsArray from String to NSData
        guard let jsonData: Data = jsonObject.data(using: String.Encoding.utf8) else {
            PreyLogger("Error jsonObject to NSData")
            return
        }
        // Convert NSData to NSArray
        do {
            let jsonArray = try JSONSerialization.jsonObject(with: jsonData, options:JSONSerialization.ReadingOptions.mutableContainers) as! NSArray
            if let geofencingAction = action as? Geofencing {
                geofencingAction.updateGeofenceZones(jsonArray)
            }
        } catch let error {
            PreyLogger("json error: \(error.localizedDescription)")
        }
    }
    
    // Check Data Send response
    class func checkDataSend(_ isSuccess:Bool, withAction action:PreyAction?, withData data:Data?, withError error:Error?, statusCode:Int?) {
        
        guard isSuccess else {
            // Check error with URLSession request
            guard error == nil else {
                PreyLogger("Error: \(error)")
                return
            }
            // === Stop report
            if statusCode == 409 {
                PreyLogger("Stop report")
                if let preyAction:Report = action as? Report {
                    preyAction.stopReport()
                }
            } else {
                PreyLogger("Failed data send")
            }
            return
        }
        
        PreyLogger("Data send: OK")

        if let preyAction = action {
            PreyModule.sharedInstance.checkStatus(preyAction)
        }
    }
}

