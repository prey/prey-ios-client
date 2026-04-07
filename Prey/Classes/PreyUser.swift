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

    // Request Token to Panel Prey
    class func getTokenFromPanel(_ userEmail: String, userPassword: String, onCompletion: @escaping (_ isSuccess: Bool) -> Void) {

        PreyHTTPClient.sharedInstance.sendDataToPrey(userEmail, password: userPassword, params: nil, messageId: nil, httpMethod: Method.GET.rawValue, endPoint: tokenEndpoint, onCompletion: PreyHTTPResponse.checkResponse(RequestType.getToken, preyAction: nil, onCompletion: onCompletion))
    }

    // LogIn to Panel Prey
    class func logInToPrey(_ userEmail: String, userPassword: String, onCompletion: @escaping (_ isSuccess: Bool) -> Void) {

        let language: String = Locale.preferredLanguages[0] as String
        let languageES  = (language as NSString).substring(to: 2)
        let langEndpoint = logInEndpoint + "?lang=" + languageES

        PreyHTTPClient.sharedInstance.sendDataToPrey(userEmail, password: userPassword, params: nil, messageId: nil, httpMethod: Method.GET.rawValue, endPoint: langEndpoint, onCompletion: PreyHTTPResponse.checkResponse(RequestType.logIn, preyAction: nil, onCompletion: onCompletion))
    }

}
