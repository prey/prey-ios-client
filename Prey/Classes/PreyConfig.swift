//
//  PreyConfig.swift
//  Prey
//
//  Created by Javier Cala Uribe on 15/03/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

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
    case ReportOptions
}

class PreyConfig: NSObject, UIActionSheetDelegate {
    
    // MARK: Singleton
    
    static let sharedInstance = PreyConfig()
    private override init() {
        
        let defaultConfig   = NSUserDefaults.standardUserDefaults()
        userApiKey          = defaultConfig.stringForKey(PreyConfigDevice.UserApiKey.rawValue)
        userEmail           = defaultConfig.stringForKey(PreyConfigDevice.UserEmail.rawValue)
        deviceKey           = defaultConfig.stringForKey(PreyConfigDevice.DeviceKey.rawValue)
        tokenPanel          = defaultConfig.stringForKey(PreyConfigDevice.TokenDevice.rawValue)
        hideTourWeb         = defaultConfig.boolForKey(PreyConfigDevice.HideTourWeb.rawValue)
        isRegistered        = defaultConfig.boolForKey(PreyConfigDevice.IsRegistered.rawValue)
        isPro               = defaultConfig.boolForKey(PreyConfigDevice.IsPro.rawValue)
        isMissing           = defaultConfig.boolForKey(PreyConfigDevice.IsMissing.rawValue)
        isCamouflageMode    = defaultConfig.boolForKey(PreyConfigDevice.IsCamouflageMode.rawValue)
        reportOptions       = defaultConfig.objectForKey(PreyConfigDevice.ReportOptions.rawValue) as? NSDictionary
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
    var reportOptions       : NSDictionary?
    
    // MARK: Functions
    
    // Save values on NSUserDefaults
    func saveValues() {
        
        let defaultConfig   = NSUserDefaults.standardUserDefaults()
        defaultConfig.setObject(userApiKey, forKey:PreyConfigDevice.UserApiKey.rawValue)
        defaultConfig.setObject(userEmail, forKey:PreyConfigDevice.UserEmail.rawValue)
        defaultConfig.setObject(deviceKey, forKey:PreyConfigDevice.DeviceKey.rawValue)
        defaultConfig.setObject(tokenPanel, forKey:PreyConfigDevice.TokenDevice.rawValue)
        defaultConfig.setBool(hideTourWeb, forKey:PreyConfigDevice.HideTourWeb.rawValue)
        defaultConfig.setBool(isRegistered, forKey:PreyConfigDevice.IsRegistered.rawValue)
        defaultConfig.setBool(isPro, forKey:PreyConfigDevice.IsPro.rawValue)
        defaultConfig.setBool(isMissing, forKey:PreyConfigDevice.IsMissing.rawValue)
        defaultConfig.setBool(isCamouflageMode, forKey:PreyConfigDevice.IsCamouflageMode.rawValue)
        defaultConfig.setObject(reportOptions, forKey: PreyConfigDevice.ReportOptions.rawValue)
    }
    
    // Reset values on NSUserDefaults
    func resetValues() {
        
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
    
    // Config UINavigationBar
    func configNavigationBar() {
        
        let colorTitle              = UIColor(red:0.3019, green:0.3411, blue:0.4, alpha:1.0)
        let colorItem               = UIColor(red:0, green:0.5058, blue:0.7607, alpha:1.0)
        
        let itemFontSize:CGFloat    = IS_IPAD ? 18 : 12
        let titleFontSize:CGFloat   = IS_IPAD ? 20 : 13
        
        let fontItem                = UIFont(name:fontTitilliumBold, size:itemFontSize)
        let fontTitle               = UIFont(name:fontTitilliumRegular, size:titleFontSize)
        
        UINavigationBar.appearance().titleTextAttributes    = [NSFontAttributeName:fontTitle!,NSForegroundColorAttributeName:colorTitle]
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName:fontItem!,NSForegroundColorAttributeName:colorItem],forState:.Normal)
        
        UINavigationBar.appearance().barTintColor           = UIColor.whiteColor()
        UINavigationBar.appearance().tintColor              = colorItem
    }
    
    // MARK: Message check for update on App Store
    
    // Check last version on Store
    func checkLastVersionOnStore() {

        guard isMissing else {
            return
        }
        
        guard shouldAskForUpdateApp() else {
            return
        }

        // Define bundleId
        let appId   = NSBundle.mainBundle().infoDictionary!["CFBundleIdentifier"] as! String
        let url     = NSURL(string:String(format:"http://itunes.apple.com/lookup?bundleId=%@",appId))!
        
        guard let data = NSData(contentsOfURL:url) else {
            return
        }

        // Parse info from url
        do {
            let lookup = try NSJSONSerialization.JSONObjectWithData(data, options:.MutableContainers) as! NSDictionary
            
            guard lookup["resultCount"]?.integerValue == 1 else {
                return
            }
            
            let appStoreVersion = lookup["results"]![0]["version"] as! NSString
            let currentVersion  = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
            
            // Compare versions
            if (appStoreVersion.compare(currentVersion, options:.NumericSearch) == .OrderedDescending) {
                showMessageForUpdateVersion()
            }
            
        } catch let error as NSError{
            PreyLogger("params error: \(error.localizedDescription)")
        }
    }
    
    // MARK: AlertView Message
    
    // Show alertView
    func showMessageForUpdateVersion() {
        let actionSheet = UIActionSheet(title:"There is a new version available. Do you want to update?".localized,
                                        delegate:self,
                                        cancelButtonTitle:"Remind me later".localized,
                                        destructiveButtonTitle:"Download".localized)
        if IS_IPAD {
            actionSheet.addButtonWithTitle("Remind me later".localized)
        }
        
        let appWindow = UIApplication.sharedApplication().delegate?.window!
        let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController

        actionSheet.showInView(navigationController.view)
    }
    
    // ActionSheetDelegate
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {

        switch buttonIndex {
            
        case 0: // Download
            let linkStore = "https://itunes.apple.com/us/app/apple-store/id456755037?mt=8"
            UIApplication.sharedApplication().openURL(NSURL(string:linkStore)!)

        case 1: // Remind me later
            let defaults = NSUserDefaults.standardUserDefaults()
            let nextTime = CFAbsoluteTimeGetCurrent() + 60*60*23*1
            defaults.setDouble(nextTime, forKey: PreyMessageAsk.UpdateApp.rawValue)

        default: break
        }
    }
    
    // Should ask for update app
    func shouldAskForUpdateApp() -> Bool {
        
        let defaults    = NSUserDefaults.standardUserDefaults()
        let currentTime = CFAbsoluteTimeGetCurrent()

        if (defaults.objectForKey(PreyMessageAsk.UpdateApp.rawValue) == nil) {
            let nextTime = currentTime + 60*60*23*1
            defaults.setDouble(nextTime, forKey:PreyMessageAsk.UpdateApp.rawValue)
            return false
        }
        
        let nextTime    = defaults.doubleForKey(PreyMessageAsk.UpdateApp.rawValue)
        if (currentTime < nextTime) {
            return false
        }
        
        return true
    }
}