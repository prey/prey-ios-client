//
//  PreyRateUs.swift
//  Prey
//
//  Created by Javier Cala Uribe on 26/07/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation

enum PreyMessageAsk: String {
    case UpdateApp, RateUs, ReviewedVersion
}

class PreyRateUs: NSObject, UIAlertViewDelegate {

    // MARK: Singleton
    
    static let sharedInstance = PreyRateUs()
    private override init() {
    }
    
    // MARK: Functions
 
    // Should ask for review
    func shouldAskForReview() -> Bool {
        
        // Check if device is missing
        if PreyConfig.sharedInstance.isMissing {
            return false
        }
        
        // Check current version reviewed
        let defaults        = NSUserDefaults.standardUserDefaults()
        let version         = NSBundle.mainBundle().infoDictionary!["CFBundleVersion"] as! String
        let reviewedVersion = defaults.stringForKey(PreyMessageAsk.ReviewedVersion.rawValue)
        
        if reviewedVersion == version {
            return false
        }
        
        // Ask next time
        let currentTime     = CFAbsoluteTimeGetCurrent()
        if defaults.objectForKey(PreyMessageAsk.RateUs.rawValue) == nil {
            let nextTime    = currentTime + 60*60*23*1
            defaults.setDouble(nextTime, forKey:PreyMessageAsk.RateUs.rawValue)
            return false
        }

        let nextTime        = defaults.doubleForKey(PreyMessageAsk.RateUs.rawValue)
        if currentTime < nextTime {
            return false
        }
        
        return true
    }
    
    // Check for review
    func askForReview() {
        
        guard shouldAskForReview() else {
            return
        }
        
        let messageAlert = UIAlertView(title:"Rate us".localized,
                                       message:"Give us ★★★★★ on the App Store if you like Prey.".localized,
                                       delegate:self,
                                       cancelButtonTitle:"Remind me later".localized,
                                       otherButtonTitles:"Yes, rate Prey!".localized)
        messageAlert.show()
    }
    
    // MARK: UIAlertViewDelegate
    
    // AlertViewDismiss
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        
        let defaults        = NSUserDefaults.standardUserDefaults()
        
        switch buttonIndex {
            
        case 0: // Remind me later
            let nextTime    = CFAbsoluteTimeGetCurrent() + 60*60*23*30
            defaults.setDouble(nextTime, forKey:PreyMessageAsk.RateUs.rawValue)
            
        case 1: // Rate it now
            let version     = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as! String
            defaults.setValue(version, forKey:PreyMessageAsk.ReviewedVersion.rawValue)
            
            let iOSAppStoreURLFormat = "itms-apps://itunes.apple.com/app/id456755037"
            UIApplication.sharedApplication().openURL(NSURL(string:iOSAppStoreURLFormat)!)
            
        default: break
        }
    }
}