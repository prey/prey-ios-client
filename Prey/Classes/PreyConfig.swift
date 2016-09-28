//
//  PreyConfig.swift
//  Prey
//
//  Created by Javier Cala Uribe on 15/03/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
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
    case camouflage_mode        // IsCamouflageMode
    case pro_account            // IsPro
    case tour_web               // HideTourWeb
    case is_missing             // IsMissing
    case token_panel            // TokenDevice
}

enum PreyConfigDevice: String {
    case UserApiKey
    case UserEmail
    case DeviceKey
    case TokenDevice
    case HideTourWeb
    case IsRegistered
    case IsPro
    case IsMissing
    case IsCamouflageMode
    case UpdatedSettings
    case ReportOptions
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
        hideTourWeb         = defaultConfig.bool(forKey: PreyConfigDevice.HideTourWeb.rawValue)
        isRegistered        = defaultConfig.bool(forKey: PreyConfigDevice.IsRegistered.rawValue)
        isPro               = defaultConfig.bool(forKey: PreyConfigDevice.IsPro.rawValue)
        isMissing           = defaultConfig.bool(forKey: PreyConfigDevice.IsMissing.rawValue)
        isCamouflageMode    = defaultConfig.bool(forKey: PreyConfigDevice.IsCamouflageMode.rawValue)
        updatedSettings     = defaultConfig.bool(forKey: PreyConfigDevice.UpdatedSettings.rawValue)
        reportOptions       = defaultConfig.object(forKey: PreyConfigDevice.ReportOptions.rawValue) as? NSDictionary
    }

    // MARK: Properties
    
    var userApiKey          : String?
    var userEmail           : String?
    var deviceKey           : String?
    var tokenPanel          : String?
    var hideTourWeb         : Bool
    var isRegistered        : Bool
    var isPro               : Bool
    var isMissing           : Bool
    var isCamouflageMode    : Bool
    var updatedSettings     : Bool
    var reportOptions       : NSDictionary?
    
    // MARK: Functions
    
    // Save values on NSUserDefaults
    func saveValues() {
        
        let defaultConfig   = UserDefaults.standard
        defaultConfig.set(userApiKey, forKey:PreyConfigDevice.UserApiKey.rawValue)
        defaultConfig.set(userEmail, forKey:PreyConfigDevice.UserEmail.rawValue)
        defaultConfig.set(deviceKey, forKey:PreyConfigDevice.DeviceKey.rawValue)
        defaultConfig.set(tokenPanel, forKey:PreyConfigDevice.TokenDevice.rawValue)
        defaultConfig.set(hideTourWeb, forKey:PreyConfigDevice.HideTourWeb.rawValue)
        defaultConfig.set(isRegistered, forKey:PreyConfigDevice.IsRegistered.rawValue)
        defaultConfig.set(isPro, forKey:PreyConfigDevice.IsPro.rawValue)
        defaultConfig.set(isMissing, forKey:PreyConfigDevice.IsMissing.rawValue)
        defaultConfig.set(isCamouflageMode, forKey:PreyConfigDevice.IsCamouflageMode.rawValue)
        defaultConfig.set(updatedSettings, forKey:PreyConfigDevice.UpdatedSettings.rawValue)
        defaultConfig.set(reportOptions, forKey:PreyConfigDevice.ReportOptions.rawValue)
    }
    
    // Reset values on NSUserDefaults
    func resetValues() {

        // Stop reports
        for item in PreyModule.sharedInstance.actionArray {
            if ( item.target == kAction.report ) {
                (item as? Report)!.stopReport()
            }
        }
        
        userApiKey       = nil
        userEmail        = nil
        deviceKey        = nil
        tokenPanel       = nil
        hideTourWeb      = false
        isRegistered     = false
        isPro            = false
        isMissing        = false
        isCamouflageMode = false
        reportOptions    = nil
        
        saveValues()
    }
    
    // Method get deviceKey
    func getDeviceKey() -> String {
        if let key = deviceKey {
            return key
        }
        return "x"
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
        hideTourWeb         = defaultConfig.bool(forKey: PreyConfigLegacy.tour_web.rawValue)
        isPro               = defaultConfig.bool(forKey: PreyConfigLegacy.pro_account.rawValue)
        isMissing           = defaultConfig.bool(forKey: PreyConfigLegacy.is_missing.rawValue)
        isCamouflageMode    = defaultConfig.bool(forKey: PreyConfigLegacy.camouflage_mode.rawValue)

        saveValues()
    }
    
    // Config UINavigationBar
    func configNavigationBar() {
        
        let colorTitle              = UIColor(red:0.3019, green:0.3411, blue:0.4, alpha:1.0)
        let colorItem               = UIColor(red:0, green:0.5058, blue:0.7607, alpha:1.0)
        
        let itemFontSize:CGFloat    = IS_IPAD ? 18 : 12
        let titleFontSize:CGFloat   = IS_IPAD ? 20 : 13
        
        let fontItem                = UIFont(name:fontTitilliumBold, size:itemFontSize)
        let fontTitle               = UIFont(name:fontTitilliumRegular, size:titleFontSize)
        
        UINavigationBar.appearance().titleTextAttributes    = [NSFontAttributeName:fontTitle!,NSForegroundColorAttributeName:colorTitle]
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName:fontItem!,NSForegroundColorAttributeName:colorItem],for:.normal)
        
        UINavigationBar.appearance().barTintColor           = UIColor.white
        UINavigationBar.appearance().tintColor              = colorItem
    }
    
    // MARK: Message check for update on App Store
    
    // Check last version on Store
    func checkLastVersionOnStore() {

        FIXME()
        /*

        guard isMissing else {
            return
        }
        
        guard shouldAskForUpdateApp() else {
            return
        }

        // Define bundleId
        let appId   = Bundle.main.infoDictionary!["CFBundleIdentifier"] as! String
        let url     = URL(string:String(format:"http://itunes.apple.com/lookup?bundleId=%@",appId))!
        
        guard let data = try? Data(contentsOf: url) else {
            return
        }

        // Parse info from url
        do {
            let lookup = try JSONSerialization.jsonObject(with: data, options:.mutableContainers) as! [String : AnyObject]
            
            guard (lookup["resultCount"] as AnyObject).intValue == 1 else {
                return
            }
            
            let appStoreVersion = lookup["results"]![0]["version"] as! NSString
            let currentVersion  = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
            
            // Compare versions
            if (appStoreVersion.compare(currentVersion, options:.numeric) == .orderedDescending) {
                showMessageForUpdateVersion()
            }
        } catch let error as NSError{
            PreyLogger("params error: \(error.localizedDescription)")
        }
        */
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
        
        let nextTime    = defaults.double(forKey: PreyMessageAsk.UpdateApp.rawValue)
        if (currentTime < nextTime) {
            return false
        }
        
        return true
    }
}
