//
//  PreyHTTPResponse.swift
//  Prey
//
//  Created by Javier Cala Uribe on 4/05/16.
//  Modified by Patricio Jofré on 04/08/2025.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation

// Prey Request Tpype
enum RequestType {
    case getToken, logIn, signUp, addDevice, deleteDevice, subscriptionReceipt, actionDevice, dataSend, statusDevice, trigger, emailValidation, resendEmailValidation, infoDevice
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
            //PreyLogger("PreyData:"+String(decoding: data!, as: UTF8.self))
            
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

        case .trigger:
            checkTrigger(isResponseSuccess, withAction:action, withData:data, withError:error, statusCode:code)

        case .emailValidation:
            checkEmailValidation(isResponseSuccess, withAction:action, withData:data, withError:error, statusCode:code)

        case .resendEmailValidation:
            checkResendEmailValidation(isResponseSuccess, withAction:action, withData:data, withError:error, statusCode:code)

        case .dataSend:
            checkDataSend(isResponseSuccess, withAction:action, withData:data, withError:error, statusCode:code)

        case .statusDevice:
            checkStatusDevice(isResponseSuccess, withAction:action, withData:data, withError:error, statusCode:code)

        case .infoDevice:
            let out=checkInfoDevice(isResponseSuccess, withAction:action, withData:data, withError:error, statusCode:code)
            onCompletion(out)
            return
        }
        
        onCompletion(isResponseSuccess)
    }
    
    // Check Get Token response
    class func checkToken(_ isSuccess:Bool, withData data:Data?, withError error:Error?, statusCode:Int?) {
        
        guard isSuccess else {
            showErrorLogIn(error, statusCode:statusCode, data:data)
            return
        }
        
        do {
            guard let dataResponse = data else {
                return
            }
            let jsonObject = try JSONSerialization.jsonObject(with: dataResponse, options:JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            if let tokenPanelStr = jsonObject.object(forKey: "token") as? String {
                PreyConfig.sharedInstance.tokenPanel = tokenPanelStr
                PreyConfig.sharedInstance.tokenWebTimestamp = CFAbsoluteTimeGetCurrent()
                PreyConfig.sharedInstance.saveValues()
            }
        } catch let error {
            PreyConfig.sharedInstance.reportError(error)
            PreyLogger("json error: \(error.localizedDescription)")
        }
    }
    
    // Check LogIn response
    class func checkLogIn(_ isSuccess:Bool, withData data:Data?, withError error:Error?, statusCode:Int?) {
        
        guard isSuccess else {
            showErrorLogIn(error, statusCode:statusCode, data:data)
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
            guard let mspAccount = jsonObject.object(forKey: "msp_account") as? NSNumber else {
                return
            }
            
            PreyConfig.sharedInstance.userApiKey    = userApiKeyStr
            PreyConfig.sharedInstance.isPro         = userIsProStr.boolValue
            PreyConfig.sharedInstance.isMsp         = mspAccount.boolValue
            PreyConfig.sharedInstance.saveValues()
            // After API key is saved, perform a consolidated sync (tokens + status + info)
            SyncCoordinator.performPostAuthOrUpgradeSync(reason: .postLogin)
            
        } catch let error {
            PreyConfig.sharedInstance.reportError(error)
            PreyLogger("json error: \(error.localizedDescription)")
        }
    }
    
    class func getErrorFromData(data:Data?) -> String {
        var errorFromServer = "Error"
        do {
            guard let dataResponse = data else {
                return errorFromServer
            }
            let jsonObject = try JSONSerialization.jsonObject(with: dataResponse, options:JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            for (_, value) in jsonObject {
                guard let errorArray = value as? Array<Any> else {
                    return errorFromServer
                }
                if let errorMsg = errorArray[0] as? String {
                    errorFromServer = errorMsg
                }
                break
            }
        } catch let error {
            PreyConfig.sharedInstance.reportError(error)
        }
        return errorFromServer
    }
    
    class func showErrorLogIn(_ error:Error?, statusCode:Int?, data:Data?) {
        // Check error with URLSession request
        guard error == nil else {
            PreyConfig.sharedInstance.reportError(error)
            let alertMessage = error?.localizedDescription
            displayErrorAlert(alertMessage!.localized, titleMessage:"Couldn't check your password".localized)
            return
        }
        
        var alertMessage: String = "Error"
        
        if statusCode == 401 {
            alertMessage = getErrorFromData(data:data)
            //alertMessage = (PreyConfig.sharedInstance.userEmail != nil) ? "Please make sure the password you entered is valid." : "There was a problem getting your account information. Please make sure the email address you entered is valid, as well as your password."
        } else {
            if ( (statusCode == 502) || (statusCode == 503) ) {
                alertMessage = "We couldn't reach our servers due to a connection error. please ensure you have a stable connection".localized
            }else{
                PreyConfig.sharedInstance.reportError("LogIn", statusCode: statusCode, errorDescription: "LogIn error")
            }
        }
        
        displayErrorAlert(alertMessage.localized, titleMessage:"Couldn't check your password".localized)
    }
    
    // Check signUp response
    class func checkSignUp(_ isSuccess:Bool, withData data:Data?, withError error:Error?, statusCode:Int?) {
        
        guard isSuccess else {
            // Check error with URLSession request
            guard error == nil else {
                PreyConfig.sharedInstance.reportError(error)
                let alertMessage = error?.localizedDescription
                displayErrorAlert(alertMessage!.localized, titleMessage:"User couldn't be created".localized)
                return
            }
            let alertMessage = (statusCode == 422) ? getErrorFromData(data:data) : "Error".localized
            //let alertMessage = (statusCode == 422) ? "Did you already register?".localized : "Error".localized
            displayErrorAlert(alertMessage.localized, titleMessage:"User couldn't be created".localized)
            
            if statusCode != 422 {
                PreyConfig.sharedInstance.reportError("SignUp", statusCode: statusCode, errorDescription: "SignUp error")
            }
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
                // After API key is saved, perform a consolidated sync (tokens + status + info)
                SyncCoordinator.performPostAuthOrUpgradeSync(reason: .postSignup)
            }
            
        } catch let error {
            PreyConfig.sharedInstance.reportError(error)
            PreyLogger("json error: \(error.localizedDescription)")
        }
    }
    
    // Check add device response
    class func checkAddDevice(_ isSuccess:Bool, withData data:Data?, withError error:Error?, statusCode:Int?) {

        guard isSuccess else {
            // Check error with URLSession request
            guard error == nil else {
                PreyConfig.sharedInstance.reportError(error)
                let alertMessage = error?.localizedDescription
                displayErrorAlert(alertMessage!.localized, titleMessage:"Couldn't add your device".localized)
                return
            }
            
            let alertMessage: String
            
            if ( (statusCode == 302) || (statusCode == 403) ) {
                alertMessage = "It seems you've reached your limit for devices on the Control Panel. Try removing this device from your account if you had already added.".localized
            } else {
                alertMessage = String(format:"Error code: %d",statusCode!)
                PreyConfig.sharedInstance.reportError("AddDevice", statusCode: statusCode, errorDescription: "AddDevice error")
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
                PreyConfig.sharedInstance.validationUserEmail = PreyUserEmailValidation.active.rawValue
                PreyConfig.sharedInstance.isTouchIDEnabled = true
                PreyConfig.sharedInstance.saveValues()
            }
            
            DispatchQueue.main.async {
                sleep(2)
                PreyDevice.infoDevice({(isSuccess: Bool) in
                    PreyLogger("infoDevice isSuccess:\(isSuccess)")
                })
            }
            
        } catch let error {
            PreyConfig.sharedInstance.reportError(error)
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
            PreyConfig.sharedInstance.reportError(error)
            let alertMessage = error?.localizedDescription
            displayErrorAlert(alertMessage!.localized, titleMessage:"Couldn't delete your device".localized)
            return
        }
        
        let titleMsg = "Couldn't delete your device".localized
        let alertMsg = "Device not ready!".localized
        displayErrorAlert(alertMsg, titleMessage:titleMsg)
        PreyConfig.sharedInstance.reportError("DeleteDevice", statusCode: statusCode, errorDescription: "DeleteDevice error")
    }

    // Check subsciption receipt
    class func checkSubscriptionReceipt(_ isSuccess:Bool, withData data:Data?, withError error:Error?, statusCode:Int?) {
        
        if isSuccess {
            return
        }

        // Check error with URLSession request
        guard error == nil else {
            PreyConfig.sharedInstance.reportError(error)
            let alertMessage = error?.localizedDescription
            displayErrorAlert(alertMessage!.localized, titleMessage:"Error".localized)
            return
        }
        
        let titleMsg = "Error".localized
        let alertMsg = "Transaction Error".localized
        displayErrorAlert(alertMsg, titleMessage:titleMsg)
        PreyConfig.sharedInstance.reportError("SubscriptionReceipt", statusCode: statusCode, errorDescription: "SubscriptionReceipt error")
    }
    
    // Check Action Devices response
    class func checkActionDevice(_ isSuccess:Bool, withData data:Data?, withError error:Error?, statusCode:Int?) {

        guard isSuccess else {
            // Check error with URLSession request
            guard error == nil else {
                PreyConfig.sharedInstance.reportError(error)
                PreyLogger("Error in actionDevice: \(String(describing: error))")
                PreyNotification.sharedInstance.handlePushError("Error processing action device request")
                return
            }

            if statusCode == 406 {
                PreyLogger("Deleted device?")
                let detachModule = Detach(withTarget:kAction.detach, withCommand:kCommand.start, withOptions:nil)
                detachModule.detachDevice()
            } else {
                PreyConfig.sharedInstance.reportError("ActionDevice", statusCode: statusCode, errorDescription: "ActionDevice error")
                PreyLogger("Failed to check action from panel")
            }
            PreyNotification.sharedInstance.handlePushError("Failed to check action from panel")
            return
        }
        
        guard let dataResponse = data else {
            PreyConfig.sharedInstance.reportError("ActionDeviceData", statusCode: statusCode, errorDescription: "ActionDeviceData error")

            PreyNotification.sharedInstance.handlePushError("Failed to check action from panel - no data")
            return
        }
        
        // Log the response for debugging
        let responseStr = String(decoding: dataResponse, as: UTF8.self)
        PreyLogger("Action device response: \(responseStr)")
        
        // First, try to parse as JSON to check for 'command' nodes
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: dataResponse, options: .mutableContainers)
            
            // Try to extract commands from different structures
            if let dict = jsonObject as? [String: Any] {
                
                // Look for device status
                if let deviceStatus = dict["status"] as? String {
                    // Check string for status
                    let isMissingDevice = deviceStatus == "missing" ? true : false
                    
                    PreyLogger("Device missing status: \(isMissingDevice)")
                    
                    // Save isMissing value
                    if PreyConfig.sharedInstance.isMissing != isMissingDevice {
                        PreyConfig.sharedInstance.isMissing = isMissingDevice
                        PreyConfig.sharedInstance.saveValues()
                        PreyLogger("Updated device missing status to: \(isMissingDevice)")
                    }
                }
                
                // Try to find instructions or commands
                var foundCommands = false
                
                // Check for instructions array
                if let instructions = dict["instruction"] as? NSArray, instructions.count > 0 {
                    PreyLogger("Found instruction array with \(instructions.count) items")
                    
                    let jsonData = try JSONSerialization.data(withJSONObject: instructions, options: .prettyPrinted)
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        PreyLogger("Parsing instructions from response: \(jsonString)")
                        PreyModule.sharedInstance.parseActionsFromPanel(jsonString)
                        foundCommands = true
                    }
                }
                
                // Check for command array
                if let commands = dict["command"] as? NSArray, commands.count > 0 {
                    PreyLogger("Found command array with \(commands.count) items")
                    
                    let jsonData = try JSONSerialization.data(withJSONObject: commands, options: .prettyPrinted)
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        PreyLogger("Parsing commands from response: \(jsonString)")
                        PreyModule.sharedInstance.parseActionsFromPanel(jsonString)
                        foundCommands = true
                    }
                }
                
                // If no commands were found, try parsing the whole response as an array
                if !foundCommands {
                    PreyLogger("No commands found in object structure, trying raw response")
                }
            } else if let array = jsonObject as? NSArray, array.count > 0 {
                let jsonData = try JSONSerialization.data(withJSONObject: array, options: .prettyPrinted)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    PreyModule.sharedInstance.parseActionsFromPanel(jsonString)
                }
            }
        } catch {
            // If JSON parsing fails, try the traditional approach
            PreyLogger("JSON parsing failed, trying raw string approach: \(error.localizedDescription)")
            
            // Only use fallback if JSON parsing actually failed
            if let actionArray: String = String(data:dataResponse, encoding:String.Encoding.utf8) {
                DispatchQueue.main.async {
                    PreyLogger("Parsing actions from raw string response")
                    PreyModule.sharedInstance.parseActionsFromPanel(actionArray)
                }
            } else {
                PreyConfig.sharedInstance.reportError("ActionDeviceDecode", statusCode: statusCode, errorDescription: "ActionDeviceDecode error")
                PreyLogger("Failed to check action from panel - string decoding failed")
                PreyNotification.sharedInstance.handlePushError("Failed to check action from panel - string decoding failed")
            }
        }
        
        // Mark verification as succeeded
        // No need to call any verification method here as the action was successful
    }
    
    // Check trigger response
    class func checkTrigger(_ isSuccess:Bool, withAction action:PreyAction?, withData data:Data?, withError error:Error?, statusCode:Int?) {
        
        guard isSuccess else {
            // Check error with URLSession request
            guard error == nil else {
                PreyConfig.sharedInstance.reportError(error)
                PreyLogger("Triggers error")
                return
            }
            PreyConfig.sharedInstance.reportError("Triggers", statusCode: statusCode, errorDescription: "Trigger error")
            PreyLogger("Failed get data")
            return
        }
        
        // === Success
        guard let dataResponse = data else {
            PreyConfig.sharedInstance.reportError("TriggerRequest", statusCode: statusCode, errorDescription: "TriggerRequest error")
            PreyLogger("Errod reading request trigger data")
            return
        }
        guard let jsonObject: String = String(data:dataResponse, encoding:String.Encoding.utf8) else {
            PreyConfig.sharedInstance.reportError("TriggerJson", statusCode: statusCode, errorDescription: "TriggerJson error")
            PreyLogger("Error reading json trigger data")
            return
        }
        // Convert actionsArray from String to NSData
        guard let jsonData: Data = jsonObject.data(using: String.Encoding.utf8) else {
            PreyConfig.sharedInstance.reportError("TriggerObject", statusCode: statusCode, errorDescription: "TriggerObject error")
            PreyLogger("Error jsonObject trigger to NSData")
            return
        }
        // Convert NSData to NSArray
        do {
            let jsonArray = try JSONSerialization.jsonObject(with: jsonData, options:JSONSerialization.ReadingOptions.mutableContainers) as! NSArray
            if let triggerAction = action as? Trigger {
                triggerAction.updateTriggers(jsonArray)
            }
        } catch let error {
            PreyConfig.sharedInstance.reportError(error)
            PreyLogger("json error: \(error.localizedDescription)")
        }
    }
    
    // Check Email Validation response
    class func checkEmailValidation(_ isSuccess:Bool, withAction action:PreyAction?, withData data:Data?, withError error:Error?, statusCode:Int?) {
        
        guard isSuccess else {
            // Check error with URLSession request
            guard error == nil else {
                PreyConfig.sharedInstance.reportError(error)
                PreyLogger("Error: \(String(describing: error))")
                return
            }
            // === Check status code
            if statusCode == 401 {
                let userActivatedAction:UserActivated = UserActivated(withTarget:kAction.user_activated, withCommand:kCommand.stop, withOptions:nil)
                PreyModule.sharedInstance.actionArray.append(userActivatedAction)
                PreyModule.sharedInstance.runAction()
                PreyLogger("Unauthorized: email expired")
            } else if statusCode == 422 {
                PreyLogger("User pending")
            } else {
                PreyConfig.sharedInstance.reportError("EmailValidation", statusCode: statusCode, errorDescription: "EmailValidation error")
                PreyLogger("Failed EmailValidation")
            }
            return
        }
        
        // Check response panel to email validation
        if statusCode == 200 {
            let userActivatedAction:UserActivated = UserActivated(withTarget:kAction.user_activated, withCommand:kCommand.start, withOptions:nil)
            PreyModule.sharedInstance.actionArray.append(userActivatedAction)
            PreyModule.sharedInstance.runAction()
        }
        
        PreyLogger("Email validation: OK")
    }
    
    
    // Check Resend Email Validation response
    class func checkResendEmailValidation(_ isSuccess:Bool, withAction action:PreyAction?, withData data:Data?, withError error:Error?, statusCode:Int?) {
        
        guard isSuccess else {
            // Check error with URLSession request
            guard error == nil else {
                PreyConfig.sharedInstance.reportError(error)
                PreyLogger("Error: \(String(describing: error))")
                return
            }
            let alertMessage = (statusCode == 409) ? "Did you already register?".localized : "Error".localized
            displayErrorAlert(alertMessage.localized, titleMessage:"User couldn't be created".localized)

            if (statusCode != 409) {
                PreyConfig.sharedInstance.reportError("ResendEmailValidation", statusCode: statusCode, errorDescription: "ResendEmailValidation error")
            }
            PreyLogger("Failed ResendEmailValidation")
            return
        }
        PreyLogger("Resend Email validation: OK")
    }
    
    // Check Data Send response
    class func checkDataSend(_ isSuccess:Bool, withAction action:PreyAction?, withData data:Data?, withError error:Error?, statusCode:Int?) {
        
        guard isSuccess else {
            // Check error with URLSession request
            guard error == nil else {
                PreyConfig.sharedInstance.reportError(error)
                PreyLogger("Error: \(String(describing: error))")
                return
            }
            // === Stop report
            if statusCode == 409 {
                PreyLogger("Stop report")
                if let preyAction:Report = action as? Report {
                    preyAction.stopReport()
                }
            } else if statusCode == 406 {
                PreyLogger("Deleted device?")
                let detachModule = Detach(withTarget:kAction.detach, withCommand:kCommand.start, withOptions:nil)
                detachModule.detachDevice()
            } else {
                PreyConfig.sharedInstance.reportError("DataSend", statusCode: statusCode, errorDescription: "DataSend error")
                PreyLogger("Failed data send: status code \(String(describing: statusCode))")
            }
            return
        }
        
        // Check response panel to stop location aware
        if statusCode == 201 {
            if action == nil || action is Location {
                PreyLogger("TODO: remove location aware?")
            }
        }
        
        PreyLogger("Data send: OK")

        if let preyAction = action {
            PreyModule.sharedInstance.checkStatus(preyAction)
        }
    }
    
    // Check Status Devices response
    class func checkStatusDevice(_ isSuccess:Bool, withAction action:PreyAction?, withData data:Data?, withError error:Error?, statusCode:Int?) {
        
        guard isSuccess else {
            // Check error with URLSession request
            guard error == nil else {
                PreyConfig.sharedInstance.reportError(error)
                PreyLogger("Error: \(String(describing: error))")
                return
            }
            PreyConfig.sharedInstance.reportError("StatusDevice", statusCode: statusCode, errorDescription: "StatusDevice error")
            PreyLogger("Failed check status device")
            return
        }
        
        do {
            guard let dataResponse = data else {
                PreyLogger("No data in status device response")
                return
            }
            
            // Log the response for debugging
            let responseStr = String(decoding: dataResponse, as: UTF8.self)
            PreyLogger("Status device response: \(responseStr)")
            
            let jsonObject = try JSONSerialization.jsonObject(with: dataResponse, options:JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            // Check for commands in the response
            if let commands = jsonObject["command"] as? NSArray, commands.count > 0 {
                PreyLogger("Found commands in status device response: \(commands.count) commands")
                
                // Process commands from the response
                let jsonData = try JSONSerialization.data(withJSONObject: commands, options: .prettyPrinted)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    PreyLogger("Parsing commands from status response: \(jsonString)")
                    PreyModule.sharedInstance.parseActionsFromPanel(jsonString)
                }
            }
            
            // Also check for settings/location_aware
            if let dict = jsonObject as? [String: Any],
               let settings = dict["settings"] as? [String: Any],
               let localSettings = settings["local"] as? [String: Any],
               let isActiveLocationAware = localSettings["location_aware"] as? Bool {
                
                PreyLogger("Location aware setting found: \(isActiveLocationAware)")
                
                if isActiveLocationAware == true {
                    // Active location aware action
                    let locationAction = Location(withTarget: kAction.location, withCommand: kCommand.start_location_aware, withOptions: nil)
                    
                    // Check if this action already exists
                    var hasLocationAwareAction = false
                    for action in PreyModule.sharedInstance.actionArray {
                        if action.target == kAction.location && action.command == kCommand.start_location_aware {
                            hasLocationAwareAction = true
                            break
                        }
                    }
                    
                    if !hasLocationAwareAction {
                        PreyLogger("Adding location_aware action from status device")
                        PreyModule.sharedInstance.actionArray.append(locationAction)
                        PreyModule.sharedInstance.runAction()
                    }
                }
            }
        } catch let error {
            PreyConfig.sharedInstance.reportError(error)
            PreyLogger("JSON error in status device: \(error.localizedDescription)")
        }
    }
    
    class func checkInfoDevice(_ isSuccess:Bool, withAction action:PreyAction?, withData data:Data?, withError error:Error?, statusCode:Int?) ->Bool{
        do {
            guard let dataResponse = data else {
                return true
            }
            
            let jsonObject = try JSONSerialization.jsonObject(with: dataResponse, options:JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                        
            if let nameDevice = jsonObject.object(forKey: "name") as? String {
                PreyConfig.sharedInstance.nameDevice = nameDevice
                PreyConfig.sharedInstance.saveValues()
            }
            return true
        } catch let error {
            PreyLogger("json error: \(error.localizedDescription)")
            return false
        }
    }
}
