//
//  Constants.swift
//  Prey
//
//  Created by Javier Cala Uribe on 14/03/16.
//  Modified by Patricio Jofré on 04/08/2025.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import UIKit
import LocalAuthentication
import OSLog

// Storyboard controllerId
enum StoryboardIdVC: String {
    case PreyStoryBoard, alert, navigation, home, currentLocation, purchases, settings, grettings, homeWeb, rename
}

// Def type device
public let IS_IPAD          : Bool  = (UIDevice.current.userInterfaceIdiom != UIUserInterfaceIdiom.phone)
public let IS_IPHONE4S      : Bool  = (UIScreen.main.bounds.size.height-480 == 0)
public let IS_IPHONEX       : Bool  = (UIScreen.main.bounds.size.height-812 == 0)
public let IS_OS_8_OR_LATER : Bool  = ((UIDevice.current.systemVersion as NSString).floatValue >= 8.0)
public let IS_OS_12         : Bool  = ((UIDevice.current.systemVersion as NSString).intValue == 12)

// Number of Reload for Connection
public let reloadConnection: Int = 5

// Delay for Reload connection
public let delayTime: Double = 2

// TimeoutInterval for URLRequest
public let timeoutIntervalRequest: Double = 30.0

// Email RegExp
public let emailRegExp = "\\b([a-zA-Z0-9%_.+\\-]+)@([a-zA-Z0-9.\\-]+?\\.[a-zA-Z]{2,21})\\b"

// App Version
public let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String

// InAppPurchases
public let subscription1Year = "1year_starter_plan_non_renewing_full"

// GAI code
public let GAICode  = "UA-8743344-7"

// Font
public let fontTitilliumBold    =  "TitilliumWeb-Bold"
public let fontTitilliumRegular =  "TitilliumWeb-Regular"

// MARK: - Logging

public enum PreyLogLevel {
    case debug
    case info
    case notice
    case warning
    case error
    case critical
}

/// Centralized logger: uses print in DEBUG; uses os.Logger in Release
/// falling back to NSLog on older OS versions. Defaults to debug level and
/// auto-classifies some common prefixes/emojis to reduce noise in Release.
public func PreyLogger(_ message: String, file: String = #file) {
    let fileName: String = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")

    // Heuristic level classification to keep release logs meaningful
    let level: PreyLogLevel
    if message.contains("❌") || message.range(of: "\\b(Error|Failed)\\b", options: [.regularExpression, .caseInsensitive]) != nil {
        level = .error
    } else if message.contains("🛑") || message.range(of: "\\b(Critical)\\b", options: [.regularExpression, .caseInsensitive]) != nil {
        level = .critical
    } else if message.range(of: "\\b(Notice)\\b", options: [.regularExpression, .caseInsensitive]) != nil {
        level = .notice
    } else if message.contains("⚠️") {
        level = .warning
    } else if message.contains("✅") {
        level = .info
    } else {
        level = .debug
    }

    PreyLog(message, level: level, category: fileName)
}

/// Explicit logging API with level and category
public func PreyLog(_ message: String, level: PreyLogLevel = .debug, category: String? = nil) {
    #if DEBUG
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] [\(level)] \(message)")
        return
    #else
        let logger = Logger(subsystem: "com.prey", category: "General")
        switch level {
        case .debug:
            // Drop debug in Release to reduce verbosity
            return
        case .info:
            logger.info("\(message, privacy: .public)")
        case .notice:
            logger.notice("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        case .critical:
            logger.critical("\(message, privacy: .public)")
        }
    #endif
}

// Convenience explicit level helpers for future use
public func PreyLoggerInfo(_ message: String, file: String = #file) {
    let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    PreyLog(message, level: .info, category: fileName)
}

public func PreyLoggerWarn(_ message: String, file: String = #file) {
    let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    PreyLog(message, level: .warning, category: fileName)
}

public func PreyLoggerError(_ message: String, file: String = #file) {
    let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    PreyLog(message, level: .error, category: fileName)
}

public func PreyLoggerDebug(_ message: String, file: String = #file) {
    let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    PreyLog(message, level: .debug, category: fileName)
}

public func PreyLoggerNotice(_ message: String, file: String = #file) {
    let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    PreyLog(message, level: .notice, category: fileName)
}

public func PreyLoggerCritical(_ message: String, file: String = #file) {
    let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    PreyLog(message, level: .critical, category: fileName)
}

// Biometric authentication
public let biometricAuth : String = {
    let textID : String
    let context = LAContext()
    if #available(iOS 11, *) {
        let _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch(context.biometryType) {
        case .none:
            textID = ""
        case .touchID:
            textID = "Touch ID"
        case .faceID:
            textID = "Face ID"
        case .opticID:
            textID = ""
        @unknown default:
            textID = ""
        }
    } else {
        textID = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? "Touch ID" : ""
    }
    return textID
}()

// Category notification
public let categoryNotifPreyAlert = "PreyAlert"

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
        let alertController = UIAlertController(title:titleMessage, message:alertMessage, preferredStyle:.alert)
        let OKAction        = UIAlertAction(title: "OK".localized, style: .default, handler:nil)
        alertController.addAction(OKAction)
        
        guard let appWindow = UIApplication.shared.delegate?.window else {
            PreyLogger("error with sharedApplication")
            return
        }
        guard let rootVC = appWindow?.rootViewController else {
            PreyLogger("error with rootVC")
            return
        }
        
        if let presentedVC = rootVC.presentedViewController {
            presentedVC.present(alertController, animated:true, completion:nil)
        } else {
            rootVC.present(alertController, animated:true, completion:nil)
        }
    }
}

// ReactViews actions
enum ReactViews: String {
    case CHECKID     = "ioschecktouchid"
    case QRCODE      = "iosqrcode"
    case LOGIN       = "ioslogin"
    case EMAILRESEND = "iosemailresend"
    case CHECKSIGNUP = "ioschecksignup"
    case SIGNUP      = "iossignup"
    case TERMS       = "iosterms"
    case PRIVACY     = "iosprivacy"
    case FORGOT      = "iosforgot"
    case AUTHLOC     = "iosauthlocation"
    case AUTHPHOTO   = "iosauthphotos"
    case AUTHCAMERA  = "iosauthcamera"
    case AUTHNOTIF   = "iosauthnotification"
    case REPORTEXAMP = "iosreportexample"
    case GOTOSETTING = "iossettingspwd"
    case GOTOPANEL   = "iospanelpwd"
    case GOTORENAME  = "iosrenamepwd"
    case GOTOCLOSE   = "iosclosepwd"
    case RENAME      = "iosrename"
    case NAMEDEVICE  = "iosnamedevice"
    case INDEX       = "iosindex"
}
