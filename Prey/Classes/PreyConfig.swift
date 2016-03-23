//
//  PreyConfig.swift
//  Prey
//
//  Created by Javier Cala Uribe on 15/03/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation

enum PreyConfigDevice: String {
    case UserApiKey
    case UserEmail
}

class PreyConfig {
    
    static let sharedInstance = PreyConfig()
    private init() {
        
        let defaultConfig = NSUserDefaults.standardUserDefaults()
        userApiKey = defaultConfig.stringForKey(PreyConfigDevice.UserApiKey.rawValue)
        userEmail  = defaultConfig.stringForKey(PreyConfigDevice.UserEmail.rawValue)
        
    }

    var userApiKey : String?
    var userEmail : String?
    
    
}