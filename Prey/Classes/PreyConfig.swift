//
//  PreyConfig.swift
//  Prey
//
//  Created by Javier Cala Uribe on 15/03/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit
import Crashlytics

// Prey config for legacy versions :: NSUserDefaults.standardUserDefaults()
enum PreyConfigLegacy: String {
    // Version < 1.6.0              >= 1.6.0
    case already_registered     // IsRegistered
    case api_key                // UserApiKey
    case device_key             // DeviceKey
    case email                  // UserEmail
    case camouflage_mode        // IsCamouflageMode
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
    case IsCamouflageMode
    case IsDarkMode
    case IsSystemDarkMode
    case UpdatedSettings
    case ReportOptions
    case NeedChangeIcon
    case IsTouchIDEnabled
    case ValidationUserEmail
}

enum PreyUserEmailValidation: String {
    case inactive, pending, active
}

class PreyConfig: NSObject, UIActionSheetDelegate {
    
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
        isCamouflageMode    = defaultConfig.bool(forKey: PreyConfigDevice.IsCamouflageMode.rawValue)
        isDarkMode          = defaultConfig.bool(forKey: PreyConfigDevice.IsDarkMode.rawValue)
        isSystemDarkMode    = defaultConfig.bool(forKey: PreyConfigDevice.IsSystemDarkMode.rawValue)
        updatedSettings     = defaultConfig.bool(forKey: PreyConfigDevice.UpdatedSettings.rawValue)
        needChangeIcon      = defaultConfig.bool(forKey: PreyConfigDevice.NeedChangeIcon.rawValue)
        isTouchIDEnabled    = defaultConfig.bool(forKey: PreyConfigDevice.IsTouchIDEnabled.rawValue)
        reportOptions       = defaultConfig.object(forKey: PreyConfigDevice.ReportOptions.rawValue) as? NSDictionary
        validationUserEmail = defaultConfig.string(forKey: PreyConfigDevice.ValidationUserEmail.rawValue)
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
    var isCamouflageMode    : Bool
    var isDarkMode          : Bool
    var isSystemDarkMode    : Bool
    var updatedSettings     : Bool
    var needChangeIcon      : Bool
    var isTouchIDEnabled    : Bool
    var reportOptions       : NSDictionary?
    var validationUserEmail : String?
    
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
        defaultConfig.set(isCamouflageMode, forKey:PreyConfigDevice.IsCamouflageMode.rawValue)
        defaultConfig.set(isDarkMode, forKey:PreyConfigDevice.IsDarkMode.rawValue)
        defaultConfig.set(isSystemDarkMode, forKey:PreyConfigDevice.IsSystemDarkMode.rawValue)
        defaultConfig.set(updatedSettings, forKey:PreyConfigDevice.UpdatedSettings.rawValue)
        defaultConfig.set(needChangeIcon, forKey:PreyConfigDevice.NeedChangeIcon.rawValue)
        defaultConfig.set(isTouchIDEnabled, forKey:PreyConfigDevice.IsTouchIDEnabled.rawValue)
        defaultConfig.set(reportOptions, forKey:PreyConfigDevice.ReportOptions.rawValue)
        defaultConfig.set(validationUserEmail, forKey:PreyConfigDevice.ValidationUserEmail.rawValue)
    }
    
    // Reset values on NSUserDefaults
    func resetValues() {

        // Stop reports
        for item in PreyModule.sharedInstance.actionArray {
            if ( item.target == kAction.report ) {
                (item as? Report)!.stopReport()
            }
        }
        
        // Stop location aware
        GeofencingManager.sharedInstance.stopLocationAwareManager()
        
        userApiKey       = nil
        userEmail        = nil
        deviceKey        = nil
        tokenPanel       = nil
        isRegistered     = false
        isPro            = false
        isMissing        = false
        isCamouflageMode = false
        needChangeIcon   = false
        isTouchIDEnabled = true
        reportOptions    = nil
        validationUserEmail = PreyUserEmailValidation.inactive.rawValue
        tokenWebTimestamp = 0
        
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
        isCamouflageMode    = defaultConfig.bool(forKey: PreyConfigLegacy.camouflage_mode.rawValue)

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
    
    // MARK: Message check for update on App Store
    
    // Check last version on Store
    func checkLastVersionOnStore() {

        // Check if devices is missing
        if isMissing {
            return
        }
        // Check timer
        guard shouldAskForUpdateApp() else {
            return
        }
        // Get app information
        guard let appInfo = Bundle.main.infoDictionary else {
            return
        }
        // Define bundleId
        guard let appId   = appInfo["CFBundleIdentifier"] as? String else {
            return
        }
        // Define app store url
        guard let url     = URL(string:String(format:"http://itunes.apple.com/lookup?bundleId=%@",appId)) else {
            return
        }
        // Get data from store url
        URLSession.shared.dataTask(with: url, completionHandler: {(data, response, error) in
            // Check error
            guard error == nil else{
                return
            }
            // Check data info
            guard let data = data else {
                return
            }            
            // Parse info from url
            do {
                // Json to String:any
                guard let lookup = try JSONSerialization.jsonObject(with: data, options:.mutableContainers) as? [String : Any] else {
                    return
                }
                // Convert to Int value
                guard let resultCount = lookup["resultCount"] as? Int else {
                    return
                }
                // Check result count
                guard resultCount == 1 else {
                    return
                }
                // Get array from results
                guard let resultStore = lookup["results"] as? NSArray else {
                    return
                }
                // Get first element from array
                guard let resultData = resultStore[0] as? [String:Any] else {
                    return
                }
                // Get Store version
                guard let appStoreVersion = resultData["version"] as? NSString else {
                    return
                }
                // Get local version
                guard let currentVersion  = appInfo["CFBundleShortVersionString"] as? String else {
                    return
                }
                // Compare versions
                if (appStoreVersion.compare(currentVersion, options:.numeric) == .orderedDescending) {
                    DispatchQueue.main.async {
                        self.showMessageForUpdateVersion()
                    }
                }
                
            } catch let error as NSError{
                PreyLogger("params error: \(error.localizedDescription)")
            }
            
        }).resume()
    }
    
    // MARK: AlertView Message
    
    // Show alertView
    func showMessageForUpdateVersion() {
        let actionSheet = UIActionSheet(title:"There is a new version available. Do you want to update?".localized,
                                        delegate:self,
                                        cancelButtonTitle:"Remind me later".localized,
                                        destructiveButtonTitle:"Download".localized)
        if IS_IPAD {
            actionSheet.addButton(withTitle: "Remind me later".localized)
        }
        
        let appWindow = UIApplication.shared.delegate?.window!
        let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController

        actionSheet.show(in: navigationController.view)
    }
    
    // ActionSheetDelegate
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {

        switch buttonIndex {
            
        case 0: // Download
            let linkStore = "https://itunes.apple.com/us/app/apple-store/id456755037?mt=8"
            UIApplication.shared.openURL(URL(string:linkStore)!)

        case 1: // Remind me later
            let defaults = UserDefaults.standard
            let nextTime = CFAbsoluteTimeGetCurrent() + 60*60*23*1
            defaults.set(nextTime, forKey: PreyMessageAsk.UpdateApp.rawValue)

        default: break
        }
    }
    
    // Should ask for update app
    func shouldAskForUpdateApp() -> Bool {
        
        let defaults    = UserDefaults.standard
        let currentTime = CFAbsoluteTimeGetCurrent()

        if (defaults.object(forKey: PreyMessageAsk.UpdateApp.rawValue) == nil) {
            let nextTime = currentTime + 60*60*23*1
            defaults.set(nextTime, forKey:PreyMessageAsk.UpdateApp.rawValue)
            return false
        }

        var nextTime    = defaults.double(forKey: PreyMessageAsk.UpdateApp.rawValue)
        if (currentTime < nextTime) {
            return false
        }
        
        // Ask again in 24 hours
        nextTime = currentTime + 60*60*23*1
        defaults.set(nextTime, forKey:PreyMessageAsk.UpdateApp.rawValue)
        
        return true
    }
    
    // Report Error
    func reportError(_ error: Error?) {
        if let err = error {
            Crashlytics.sharedInstance().recordError(err)
        }
    }

    // Report Error custom
    func reportError(_ domain: String, statusCode: Int?, errorDescription: String) {
        if let code = statusCode {
            Crashlytics.sharedInstance().recordError(NSError(domain: domain, code: code, userInfo: [String(code) : errorDescription]))
        } else {
            Crashlytics.sharedInstance().recordError(NSError(domain: domain, code: 1985, userInfo: ["1985" : errorDescription]))
        }
    }
}
