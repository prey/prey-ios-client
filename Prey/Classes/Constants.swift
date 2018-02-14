//
//  Constants.swift
//  Prey
//
//  Created by Javier Cala Uribe on 14/03/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

// Storyboard controllerId
enum StoryboardIdVC: String {
    case PreyStoryBoard, alert, navigation, home, welcome, signUp, signIn, deviceSetUp, currentLocation, purchases, settings, grettings, homeWeb
}

// Def type device
public let IS_IPAD          : Bool  = (UIDevice.current.userInterfaceIdiom != UIUserInterfaceIdiom.phone)
public let IS_IPHONE4S      : Bool  = (UIScreen.main.bounds.size.height-480 == 0)
public let IS_IPHONEX       : Bool  = (UIScreen.main.bounds.size.height-812 == 0)
public let IS_OS_8_OR_LATER : Bool  = ((UIDevice.current.systemVersion as NSString).floatValue >= 8.0)

// Number of Reload for Connection
public let reloadConnection: Int = 5

// Delay for Reload connection
public let delayTime: Double = 2

// Email RegExp
public let emailRegExp = "\\b([a-zA-Z0-9%_.+\\-]+)@([a-zA-Z0-9.\\-]+?\\.[a-zA-Z]{2,21})\\b"

// App Version
public let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String

// InAppPurchases
public let subscription1Year = "1year_personal_plan_non_renewing_full"

// GAI code
public let GAICode  = "UA-8743344-7"

// Font
public let fontTitilliumBold    =  "TitilliumWeb-Bold"
public let fontTitilliumRegular =  "TitilliumWeb-Regular"

// PreyLogger
public func PreyLogger(_ message:String) {
    #if DEBUG
    print(message)
    #endif
}

// Filename to alternative icon
public let alternativeIcon = "Icon2"

// Validate email expression
public func isInvalidEmail(_ userEmail: String, withPattern: String) -> Bool {

    var isInvalid = true
    let regex: NSRegularExpression

    do {
        regex = try NSRegularExpression(pattern:withPattern, options:NSRegularExpression.Options.caseInsensitive)
        let textRange  = NSMakeRange(0, userEmail.count)
        let matchRange = regex.rangeOfFirstMatch(in: userEmail, options:NSRegularExpression.MatchingOptions.reportProgress, range:textRange)
        
        if (matchRange.location != NSNotFound) {
            isInvalid = false
        }
    } catch let error as NSError {
        PreyLogger("error RegEx: \(error.localizedDescription)")
    }

    return isInvalid
}


// Display error alert
public func displayErrorAlert(_ alertMessage: String, titleMessage:String) {
    DispatchQueue.main.async {
        if #available(iOS 8.0, *) {
            let alertController = UIAlertController(title:titleMessage, message:alertMessage, preferredStyle:.alert)
            let OKAction        = UIAlertAction(title: "OK".localized, style: .default, handler:nil)
            alertController.addAction(OKAction)
            
            guard let appWindow = UIApplication.shared.delegate?.window else {
                PreyLogger("error with sharedApplication")
                return
            }
            appWindow?.rootViewController!.present(alertController, animated:true, completion:nil)
            
        } else {
            let alert       = UIAlertView()
            alert.title     = titleMessage
            alert.message   = alertMessage
            alert.addButton(withTitle: "OK".localized)
            alert.show()
        }
    }
}
