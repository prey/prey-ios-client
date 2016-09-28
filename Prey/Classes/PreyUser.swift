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
        
        let params:[String: String] = [
            "name"                  : userName,
            "email"                 : userEmail,
            "country_name"          : getCountryName(),
            "password"              : userPassword,
            "password_confirmation" : userPassword,
            "referer_user_id"       : ""]
        
        PreyHTTPClient.sharedInstance.userRegisterToPrey(userName, password:userPassword, params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:signUpEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.signUp, onCompletion:onCompletion))
    }
    
    // Request Token to Panel Prey
    class func getTokenFromPanel(_ userEmail: String, userPassword: String, onCompletion:@escaping (_ isSuccess: Bool) -> Void) {
        
        PreyHTTPClient.sharedInstance.userRegisterToPrey(userEmail, password:userPassword, params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:tokenEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.getToken, onCompletion:onCompletion))
    }
    
    // LogIn to Panel Prey
    class func logInToPrey(_ userEmail: String, userPassword: String, onCompletion:@escaping (_ isSuccess: Bool) -> Void) {
        
        PreyHTTPClient.sharedInstance.userRegisterToPrey(userEmail, password:userPassword, params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:logInEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.logIn, onCompletion:onCompletion))
    }
}
