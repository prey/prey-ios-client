//
//  PreyUser.swift
//  Prey
//
//  Created by Javier Cala Uribe on 9/1/15.
//  Copyright (c) 2015 Fork Ltd. All rights reserved.
//

import Foundation

class PreyUser {
    
    // MARK: Properties

    var name: String?
    var email: String?
    var country: String?
    var password: String?
    var repassword: String?
    var apiKey: String?
    var isPro: Bool?
    
    // MARK: Functions

    // Get country name from NSLocale
    class func getCountryName() -> String? {
        let locale          = NSLocale.currentLocale()
        let countryCode     = locale.objectForKey(NSLocaleCountryCode) as! String
        let countryName     = locale.displayNameForKey(NSLocaleCountryCode, value:countryCode)
        
        return countryName
    }

    // SignUp to Panel Prey
    class func signUpToPrey(userName: String, userEmail: String, userPassword: String, onCompletion:(isSuccess: Bool?) -> Void) {
        
        let params:[String: AnyObject] = [
            "name"                  : userName,
            "email"                 : userEmail,
            "country_name"          : getCountryName()!,
            "password"              : userPassword,
            "password_confirmation" : userPassword,
            "referer_user_id"       : ""]
        
        PreyHTTPClient.sharedInstance.userRegisterToPrey(userName, password:userPassword, params:params, httpMethod:Method.POST.rawValue, endPoint:signUpEndpoint, onCompletion:({(data, response, error) in
            
            // Check error with NSURLSession request
            guard error == nil else {
                
                let alertMessage = (error?.localizedRecoverySuggestion != nil) ? error?.localizedRecoverySuggestion : error?.localizedDescription
                
                dispatch_async(dispatch_get_main_queue()) {
                    displayErrorAlert(alertMessage!.localized, titleMessage:"User couldn't be created".localized)
                }
                onCompletion(isSuccess:false)
                
                return
            }
            
            print("PreyUser: data:\(data) \nresponse:\(response) \nerror:\(error)")
            
            let httpURLResponse = response as! NSHTTPURLResponse
            
            switch httpURLResponse.statusCode {
                
            // === Success
            case 201:
                let jsonObject: NSDictionary
                
                do {
                    jsonObject = try NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers) as! NSDictionary
                    
                    let userApiKeyStr = jsonObject.objectForKey("key") as! String
                    PreyConfig.sharedInstance.userApiKey = userApiKeyStr
                    
                    onCompletion(isSuccess:true)
                    
                } catch let error as NSError{
                    print("json error: \(error.localizedDescription)")
                }
                
            // === Client Error
            case 422:
                let alertMessage = "Did you already register?".localized
                
                dispatch_async(dispatch_get_main_queue()) {
                    displayErrorAlert(alertMessage.localized, titleMessage:"Couldn't check your password".localized)
                }
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
                let alertMessage = "Error";
                dispatch_async(dispatch_get_main_queue()) {
                    displayErrorAlert(alertMessage.localized, titleMessage:"User couldn't be created".localized)
                }
                onCompletion(isSuccess:false)
            }
        }))
    }
    
    // LogIn to Panel Prey
    class func logInToPrey(userEmail: String, userPassword: String, onCompletion:(isSuccess: Bool) -> Void) {
        
        PreyHTTPClient.sharedInstance.userRegisterToPrey(userEmail, password:userPassword, params:nil, httpMethod:Method.GET.rawValue, endPoint:logInEndpoint, onCompletion:({(data, response, error) in
            
            // Check error with NSURLSession request
            guard error == nil else {
                
                let alertMessage = (error?.localizedRecoverySuggestion != nil) ? error?.localizedRecoverySuggestion : error?.localizedDescription
                
                dispatch_async(dispatch_get_main_queue()) {
                    displayErrorAlert(alertMessage!.localized, titleMessage:"Couldn't check your password".localized)
                }
                onCompletion(isSuccess:false)
                
                return
            }
            
            print("PreyUser: data:\(data) \nresponse:\(response) \nerror:\(error)")
            
            let httpURLResponse = response as! NSHTTPURLResponse
            
            switch httpURLResponse.statusCode {
                
            // === Success
            case 200:
                let jsonObject: NSDictionary
                
                do {
                    jsonObject = try NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers) as! NSDictionary
                    
                    let userApiKeyStr = jsonObject.objectForKey("key") as! String
                    PreyConfig.sharedInstance.userApiKey = userApiKeyStr
                    
                    onCompletion(isSuccess:true)
                    
                } catch let error as NSError{
                    print("json error: \(error.localizedDescription)")
                }
                
            // === Client Error
            case 401:
                let alertMessage = (PreyConfig.sharedInstance.userEmail != nil) ? "Please make sure the password you entered is valid." : "There was a problem getting your account information. Please make sure the email address you entered is valid, as well as your password."
                
                dispatch_async(dispatch_get_main_queue()) {
                    displayErrorAlert(alertMessage.localized, titleMessage:"Couldn't check your password".localized)
                }
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
                let alertMessage = "Error";
                dispatch_async(dispatch_get_main_queue()) {
                    displayErrorAlert(alertMessage.localized, titleMessage:"Couldn't check your password".localized)
                }
                onCompletion(isSuccess:false)
            }
        }))
 }
}