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
    class func signUpToPrey(userName: String, userEmail: String, userPassword: String, onCompletion:(isSuccess: Bool) -> Void) {
        
        let params:[String: AnyObject] = [
            "name"                  : userName,
            "email"                 : userEmail,
            "country_name"          : getCountryName()!,
            "password"              : userPassword,
            "password_confirmation" : userPassword,
            "referer_user_id"       : ""]
        
        PreyHTTPClient.sharedInstance.userRegisterToPrey(userName, password:userPassword, params:params, messageId:nil, httpMethod:Method.POST.rawValue, endPoint:signUpEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.SignUp, onCompletion:onCompletion))
    }
    
    // Request Token to Panel Prey
    class func getTokenFromPanel(userEmail: String, userPassword: String, onCompletion:(isSuccess: Bool) -> Void) {
        
        PreyHTTPClient.sharedInstance.userRegisterToPrey(userEmail, password:userPassword, params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:tokenEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.GetToken, onCompletion:onCompletion))
    }
    
    // LogIn to Panel Prey
    class func logInToPrey(userEmail: String, userPassword: String, onCompletion:(isSuccess: Bool) -> Void) {
        
        PreyHTTPClient.sharedInstance.userRegisterToPrey(userEmail, password:userPassword, params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:logInEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.LogIn, onCompletion:onCompletion))
    }
}