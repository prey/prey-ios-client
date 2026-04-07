//
//  PreyConfig.swift
//  Prey
//
//  Created by Javier Cala Uribe on 15/03/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import UIKit


// Prey config for legacy versions :: NSUserDefaults.standardUserDefaults()
enum PreyConfigLegacy: String {
    // Version < 1.6.0              >= 1.6.0
    case already_registered     // IsRegistered
    case api_key                // UserApiKey
    case device_key             // DeviceKey
    case email                  // UserEmail
    case pro_account            // IsPro
    case is_missing             // IsMissing
    case token_panel            // TokenDevice
}

enum PreyConfigDevice: String {
    case UserApiKey
    case UserEmail
    case DeviceKey
    case TokenDevice
    case TokenWebTimestamp
    case IsRegistered
    case IsPro
    case IsMissing
    case IsDarkMode
    case IsSystemDarkMode
    case UpdatedSettings
    case IsTouchIDEnabled
    case ExistBackup
    case NameDevice
    case IsMsp
    case LocationAccess
    case isActiveAware
}

class PreyConfig: NSObject {
    
    // MARK: Singleton
    
    static let sharedInstance = PreyConfig()
    fileprivate override init() {
        
        let defaultConfig   = UserDefaults.standard
        userApiKey          = defaultConfig.string(forKey: PreyConfigDevice.UserApiKey.rawValue)
        userEmail           = defaultConfig.string(forKey: PreyConfigDevice.UserEmail.rawValue)
        deviceKey           = defaultConfig.string(forKey: PreyConfigDevice.DeviceKey.rawValue)
        tokenPanel          = defaultConfig.string(forKey: PreyConfigDevice.TokenDevice.rawValue)
        tokenWebTimestamp   = defaultConfig.double(forKey: PreyConfigDevice.TokenWebTimestamp.rawValue) as CFAbsoluteTime
        isRegistered        = defaultConfig.bool(forKey: PreyConfigDevice.IsRegistered.rawValue)
        isPro               = defaultConfig.bool(forKey: PreyConfigDevice.IsPro.rawValue)
        isMissing           = defaultConfig.bool(forKey: PreyConfigDevice.IsMissing.rawValue)
        isDarkMode          = defaultConfig.bool(forKey: PreyConfigDevice.IsDarkMode.rawValue)
        isSystemDarkMode    = defaultConfig.bool(forKey: PreyConfigDevice.IsSystemDarkMode.rawValue)
        updatedSettings     = defaultConfig.bool(forKey: PreyConfigDevice.UpdatedSettings.rawValue)
        isTouchIDEnabled    = defaultConfig.bool(forKey: PreyConfigDevice.IsTouchIDEnabled.rawValue)
        existBackup         = defaultConfig.bool(forKey: PreyConfigDevice.ExistBackup.rawValue)
        nameDevice          = defaultConfig.string(forKey: PreyConfigDevice.NameDevice.rawValue)
        isMsp               = defaultConfig.bool(forKey: PreyConfigDevice.IsMsp.rawValue)
        locationAccess      = defaultConfig.string(forKey: PreyConfigDevice.LocationAccess.rawValue)
        isActiveAware       = defaultConfig.bool(forKey: PreyConfigDevice.isActiveAware.rawValue)
    }

    // MARK: Properties
    
    var userApiKey          : String?
    var userEmail           : String?
    var deviceKey           : String?
    var tokenPanel          : String?
    var tokenWebTimestamp   : CFAbsoluteTime
    var isRegistered        : Bool
    var isPro               : Bool
    var isMissing           : Bool
    var isDarkMode          : Bool
    var isSystemDarkMode    : Bool
    var updatedSettings     : Bool
    var isTouchIDEnabled    : Bool
    var existBackup         : Bool
    var nameDevice          : String?
    var isMsp               : Bool
    var locationAccess      : String?
    var isActiveAware       : Bool
    
    // MARK: Functions
    
    // Save values on NSUserDefaults
    func saveValues() {
        
        let defaultConfig   = UserDefaults.standard
        defaultConfig.set(userApiKey, forKey:PreyConfigDevice.UserApiKey.rawValue)
        defaultConfig.set(userEmail, forKey:PreyConfigDevice.UserEmail.rawValue)
        defaultConfig.set(deviceKey, forKey:PreyConfigDevice.DeviceKey.rawValue)
        defaultConfig.set(tokenPanel, forKey:PreyConfigDevice.TokenDevice.rawValue)
        defaultConfig.set(tokenWebTimestamp, forKey:PreyConfigDevice.TokenWebTimestamp.rawValue)
        defaultConfig.set(isRegistered, forKey:PreyConfigDevice.IsRegistered.rawValue)
        defaultConfig.set(isPro, forKey:PreyConfigDevice.IsPro.rawValue)
        defaultConfig.set(isMissing, forKey:PreyConfigDevice.IsMissing.rawValue)
        defaultConfig.set(isDarkMode, forKey:PreyConfigDevice.IsDarkMode.rawValue)
        defaultConfig.set(isSystemDarkMode, forKey:PreyConfigDevice.IsSystemDarkMode.rawValue)
        defaultConfig.set(updatedSettings, forKey:PreyConfigDevice.UpdatedSettings.rawValue)
        defaultConfig.set(isTouchIDEnabled, forKey:PreyConfigDevice.IsTouchIDEnabled.rawValue)
        defaultConfig.set(existBackup, forKey: PreyConfigDevice.ExistBackup.rawValue)
        defaultConfig.set(nameDevice, forKey: PreyConfigDevice.NameDevice.rawValue)
        defaultConfig.set(isMsp, forKey:PreyConfigDevice.IsMsp.rawValue)
        defaultConfig.set(locationAccess, forKey:PreyConfigDevice.LocationAccess.rawValue)
        defaultConfig.set(isActiveAware, forKey:PreyConfigDevice.isActiveAware.rawValue)

        // Mirror a minimal subset to the App Group so extensions can read them
        if let suite = UserDefaults(suiteName: "group.com.prey.ios") {
            suite.set(userApiKey, forKey: "UserApiKey")
            suite.set(deviceKey, forKey: "DeviceKey")
            suite.synchronize()
        }
    }
    
    // Reset values on NSUserDefaults
    func resetValues() {

        
        userApiKey       = nil
        userEmail        = nil
        deviceKey        = nil
        tokenPanel       = nil
        isRegistered     = false
        isPro            = false
        isMissing        = false
        isTouchIDEnabled = true
        nameDevice       = nil
        tokenWebTimestamp = 0
        isMsp            = false
        locationAccess   = LocationAccess.UNKNOWN.rawValue
        isActiveAware    = false
        
        saveValues()
    }
    
    // Method get deviceKey
    func getDeviceKey() -> String {
        if let key = deviceKey {
            return key
        }
        return "x"
    }

    // Method get darkMode stat
    func getDarkModeState(_ view: UIViewController) -> String {

        let darkMode  = "/?theme=dark"
        let lightMode = "/?theme=light"
        
        // If < iOS 13 set darkMode by deafult
        guard #available(iOS 13.0, *) else {
            return darkMode
        }
        
        // Check first run on app
        if !isRegistered, !isDarkMode, !isSystemDarkMode {
            isSystemDarkMode = true
            saveValues()
            return view.traitCollection.userInterfaceStyle == .dark ? darkMode : lightMode
        }
                
        // Check systemDarkMode
        if isSystemDarkMode {
            return view.traitCollection.userInterfaceStyle == .dark ? darkMode : lightMode
        }
        
        return isDarkMode ? darkMode : lightMode
    }
    
    // Check user settings
    func updateUserSettings() {
        
        // Check if settings is updated
        if updatedSettings {
            return
        }

        updatedSettings = true
        
        // User have latest version :: NSUserDefaults.standardUserDefaults()
        if isRegistered {
            saveValues()
            return
        }

        let defaultConfig = UserDefaults.standard
        
        // Check if user IsRegistered for versions < 1.6.0
        if defaultConfig.bool(forKey: PreyConfigLegacy.already_registered.rawValue) == false {
            saveValues()
            return
        }
        
        // Update new settings with old settings for registered user
        isRegistered        = defaultConfig.bool(forKey: PreyConfigLegacy.already_registered.rawValue)
        userApiKey          = defaultConfig.string(forKey: PreyConfigLegacy.api_key.rawValue)
        userEmail           = defaultConfig.string(forKey: PreyConfigLegacy.email.rawValue)
        deviceKey           = defaultConfig.string(forKey: PreyConfigLegacy.device_key.rawValue)
        tokenPanel          = defaultConfig.string(forKey: PreyConfigLegacy.token_panel.rawValue)
        isPro               = defaultConfig.bool(forKey: PreyConfigLegacy.pro_account.rawValue)
        isMissing           = defaultConfig.bool(forKey: PreyConfigLegacy.is_missing.rawValue)

        saveValues()
    }
    
    // Config UINavigationBar
    func configNavigationBar() {

        let colorTitle           = getNavBarTitleColor()
        let colorItem            = getNavBarItemColor()
        
        let itemFontSize:CGFloat    = IS_IPAD ? 18 : 12
        let titleFontSize:CGFloat   = IS_IPAD ? 20 : 13
        
        let fontItem                = UIFont(name:fontTitilliumBold, size:itemFontSize)
        let fontTitle               = UIFont(name:fontTitilliumRegular, size:titleFontSize)
        
        UINavigationBar.appearance().titleTextAttributes    = [NSAttributedString.Key.font:fontTitle!,NSAttributedString.Key.foregroundColor:colorTitle]
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font:fontItem!,NSAttributedString.Key.foregroundColor:colorItem],for:.normal)
        
        UINavigationBar.appearance().barTintColor           = getNavBarTintColor()
        UINavigationBar.appearance().tintColor              = colorItem
    }
    
    // MARK: Dark Mode colors
    
    func getNavBarTitleColor() -> UIColor {
        guard #available(iOS 13.0, *) else {
            return UIColor(red:0.3019, green:0.3411, blue:0.4, alpha:1.0)
        }
        if PreyConfig.sharedInstance.isSystemDarkMode {
            return UIColor(named: "NavBarTitle")!
        }
        return PreyConfig.sharedInstance.isDarkMode ? UIColor(red: 214/255, green: 231/255, blue: 255/255, alpha: 1.0) : UIColor(red:0.3019, green:0.3411, blue:0.4, alpha:1.0)
    }
    
    func getNavBarItemColor() -> UIColor {
        guard #available(iOS 13.0, *) else {
            return UIColor(red:0, green:0.5058, blue:0.7607, alpha:1.0)
        }
        if PreyConfig.sharedInstance.isSystemDarkMode {
            return UIColor(named: "NavBarItem")!
        }
        return PreyConfig.sharedInstance.isDarkMode ? UIColor(red: 214/255, green: 231/255, blue: 255/255, alpha: 1.0) : UIColor(red:0, green:0.5058, blue:0.7607, alpha:1.0)
    }
    
    func getNavBarTintColor() -> UIColor {
        guard #available(iOS 13.0, *) else {
            return UIColor.white
        }
        if PreyConfig.sharedInstance.isSystemDarkMode {
            return UIColor(named: "NavBarTint")!
        }
        return PreyConfig.sharedInstance.isDarkMode ? UIColor(red: 40/255, green: 54/255, blue: 74/255, alpha: 1.0) : UIColor.white
    }
    
    
    // Report Error
    func reportError(_ error: Error?) {
        if let err = error {
            // TODO: enable
//            Crashlytics.sharedInstance().recordError(err)
        }
    }

    // Report Error custom
    func reportError(_ domain: String, statusCode: Int?, errorDescription: String) {
        if let code = statusCode {
//            Crashlytics.sharedInstance().recordError(NSError(domain: domain, code: code, userInfo: [String(code) : errorDescription]))
        } else {
//            Crashlytics.sharedInstance().recordError(NSError(domain: domain, code: 1985, userInfo: ["1985" : errorDescription]))
        }
    }
}
