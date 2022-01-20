//
//  PreyUser.swift
//  Prey
//
//  Created by Javier Cala Uribe on 9/1/15.
//  Copyright (c) 2015 Prey, Inc. All rights reserved.
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
    class func getCountryName() -> String {
        let locale = Locale.current
        guard let countryCode = (locale as NSLocale).object(forKey: NSLocale.Key.countryCode) as? String else {
            return ""
        }
        guard let countryName = (locale as NSLocale).displayName(forKey: NSLocale.Key.countryCode, value:countryCode) else {
            return ""
        }        
        return countryName
    }

    // SignUp to Panel Prey
    class func signUpToPrey(_ userName: String, userEmail: String, userPassword: String, onCompletion:@escaping (_ isSuccess: Bool) -> Void) {
        
        let language:String = Locale.preferredLanguages[0] as String
        let languageES  = (language as NSString).substring(to: 2)
        
        let params:[String: Any] = [
            "name"                      : userName,
            "email"                     : userEmail,
            "country_name"              : getCountryName(),
            "password"                  : userPassword,
            "password_confirmation"     : userPassword,
            "policy_rule_age"           : true,
            "policy_rule_privacy_terms" : true,
            "referer_user_id"           : "",
            "lang"                      : languageES]
        
        PreyHTTPClient.sharedInstance.userRegisterToPrey(userName, password:userPassword, params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:signUpEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.signUp, preyAction:nil, onCompletion:onCompletion))
    }
    
    // Request Token to Panel Prey
    class func getTokenFromPanel(_ userEmail: String, userPassword: String, onCompletion:@escaping (_ isSuccess: Bool) -> Void) {
        
        PreyHTTPClient.sharedInstance.userRegisterToPrey(userEmail, password:userPassword, params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:tokenEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.getToken, preyAction:nil, onCompletion:onCompletion))
    }
    
    // LogIn to Panel Prey
    class func logInToPrey(_ userEmail: String, userPassword: String, onCompletion:@escaping (_ isSuccess: Bool) -> Void) {
        
        let language:String = Locale.preferredLanguages[0] as String
        let languageES  = (language as NSString).substring(to: 2)
        let langEndpoint = logInEndpoint + "?lang=" + languageES
        
        PreyHTTPClient.sharedInstance.userRegisterToPrey(userEmail, password:userPassword, params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:langEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.logIn, preyAction:nil, onCompletion:onCompletion))
    }
    
    // Resend email validation to Panel Prey
    class func resendEmailValidation(_ userEmail: String, onCompletion:@escaping (_ isSuccess: Bool) -> Void) {
        
        let language:String = Locale.preferredLanguages[0] as String
        let languageES  = (language as NSString).substring(to: 2)
        
        let params:[String: Any] = [
            "email" : userEmail,
            "lang"  : languageES]
        
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:params, messageId:nil, httpMethod:Method.PUT.rawValue, endPoint:resendEmailValidationEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.resendEmailValidation, preyAction:nil, onCompletion:onCompletion))
        } else {
            let titleMsg = "Couldn't add your device".localized
            let alertMsg = "Error user ID".localized
            displayErrorAlert(alertMsg, titleMessage:titleMsg)
            onCompletion(false)
        }
    }

}
