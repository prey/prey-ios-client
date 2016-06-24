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
    case DeviceKey
    case TokenDevice
    case IsRegistered
    case IsPro
    case IsMissing
}

class PreyConfig {
    
    // MARK: Singleton
    
    static let sharedInstance = PreyConfig()
    private init() {
        
        let defaultConfig   = NSUserDefaults.standardUserDefaults()
        userApiKey          = defaultConfig.stringForKey(PreyConfigDevice.UserApiKey.rawValue)
        userEmail           = defaultConfig.stringForKey(PreyConfigDevice.UserEmail.rawValue)
        deviceKey           = defaultConfig.stringForKey(PreyConfigDevice.DeviceKey.rawValue)
        tokenPanel          = defaultConfig.stringForKey(PreyConfigDevice.TokenDevice.rawValue)
        isRegistered        = defaultConfig.boolForKey(PreyConfigDevice.IsRegistered.rawValue)
        isPro               = defaultConfig.boolForKey(PreyConfigDevice.IsPro.rawValue)
        isMissing           = defaultConfig.boolForKey(PreyConfigDevice.IsMissing.rawValue)
    }

    // MARK: Properties
    
    var userApiKey  : String?
    var userEmail   : String?
    var deviceKey   : String?
    var tokenPanel  : String?
    var isRegistered: Bool
    var isPro       : Bool
    var isMissing   : Bool
    
    // MARK: Functions
    
    // Save values on NSUserDefaults
    func saveValues() {
        
        let defaultConfig   = NSUserDefaults.standardUserDefaults()
        defaultConfig.setObject(userApiKey, forKey:PreyConfigDevice.UserApiKey.rawValue)
        defaultConfig.setObject(userEmail, forKey:PreyConfigDevice.UserEmail.rawValue)
        defaultConfig.setObject(deviceKey, forKey:PreyConfigDevice.DeviceKey.rawValue)
        defaultConfig.setObject(tokenPanel, forKey:PreyConfigDevice.TokenDevice.rawValue)
        defaultConfig.setBool(isRegistered, forKey:PreyConfigDevice.IsRegistered.rawValue)
        defaultConfig.setBool(isPro, forKey:PreyConfigDevice.IsPro.rawValue)
        defaultConfig.setBool(isMissing, forKey: PreyConfigDevice.IsMissing.rawValue)
    }
    
    // Reset values on NSUserDefaults
    func resetValues() {
        
        userApiKey      = nil
        userEmail       = nil
        deviceKey       = nil
        tokenPanel      = nil
        isRegistered    = false
        isPro           = false
        isMissing       = false
        
        saveValues()
    }
}