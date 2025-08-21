//
//  PreyRateUs.swift
//  Prey
//
//  Created by Javier Cala Uribe on 26/07/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import StoreKit
import UIKit

enum PreyMessageAsk: String {
    case UpdateApp, RateUs, ReviewedVersion
}

class PreyRateUs: NSObject {

    // MARK: Singleton
    
    static let sharedInstance = PreyRateUs()
    fileprivate override init() {
    }
    
    // MARK: Functions
 
    // Should ask for review
    func shouldAskForReview() -> Bool {
        
        // Check if device is missing
        if PreyConfig.sharedInstance.isMissing {
            return false
        }
        
        // Check current version reviewed
        let defaults        = UserDefaults.standard
        let version         = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        let reviewedVersion = defaults.string(forKey: PreyMessageAsk.ReviewedVersion.rawValue)
        
        if reviewedVersion == version {
            return false
        }
        
        // Ask next time
        let currentTime     = CFAbsoluteTimeGetCurrent()
        if defaults.object(forKey: PreyMessageAsk.RateUs.rawValue) == nil {
            let nextTime    = currentTime + 60*60*23*1
            defaults.set(nextTime, forKey:PreyMessageAsk.RateUs.rawValue)
            return false
        }

        let nextTime        = defaults.double(forKey: PreyMessageAsk.RateUs.rawValue)
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
        
        // Use modern StoreKit review API
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
            return
        }
        
        // Fallback to alert controller for older iOS versions or if scene is not available
        showRateUsAlert()
    }
    
    // Show rate us alert using UIAlertController
    private func showRateUsAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let viewController = window.rootViewController else {
            return
        }
        
        let alertController = UIAlertController(
            title: "Rate us".localized,
            message: "Give us ★★★★★ on the App Store if you like Prey.".localized,
            preferredStyle: .alert
        )
        
        let remindLaterAction = UIAlertAction(
            title: "Remind me later".localized,
            style: .cancel
        ) { _ in
            self.handleRemindLater()
        }
        
        let rateAction = UIAlertAction(
            title: "Yes, rate Prey!".localized,
            style: .default
        ) { _ in
            self.handleRateNow()
        }
        
        alertController.addAction(remindLaterAction)
        alertController.addAction(rateAction)
        
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Alert Actions
    
    // Handle remind me later
    private func handleRemindLater() {
        let defaults = UserDefaults.standard
        let nextTime = CFAbsoluteTimeGetCurrent() + 60*60*23*15
        defaults.set(nextTime, forKey: PreyMessageAsk.RateUs.rawValue)
    }
    
    // Handle rate now
    private func handleRateNow() {
        let defaults = UserDefaults.standard
        let version = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
        defaults.setValue(version, forKey: PreyMessageAsk.ReviewedVersion.rawValue)
        
        let iOSAppStoreURLFormat = "itms-apps://itunes.apple.com/app/id456755037?action=write-review"
        if let url = URL(string: iOSAppStoreURLFormat) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
