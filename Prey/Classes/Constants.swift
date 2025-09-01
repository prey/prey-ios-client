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

// MARK: - File Logging
private class PreyFileLogger {
    static let shared = PreyFileLogger()
    private let logQueue = DispatchQueue(label: "com.prey.filelogger", qos: .utility)
    private let maxLogFileSize: Int = 5 * 1024 * 1024 // 5MB
    private let maxLogFiles: Int = 3
    
    private var logFileURL: URL {
        // Usar Documents directory - se elimina al desinstalar la app
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("prey.log")
    }
    
    private init() {
        createLogFileIfNeeded()
    }
    
    private func createLogFileIfNeeded() {
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            let success = FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
            print("[PreyLogger] Creating log file at: \(logFileURL.path) - Success: \(success)")
        } else {
            print("[PreyLogger] Log file already exists at: \(logFileURL.path)")
        }
    }
    
    func writeLog(_ message: String, level: PreyLogLevel) {
        logQueue.async { [weak self] in
            guard let self = self else { return }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            let timestamp = dateFormatter.string(from: Date())
            let logEntry = "[\(timestamp)] [\(level)] \(message)\n"
            
            // Rotar logs si es necesario
            self.rotateLogsIfNeeded()
            
            // Escribir al archivo
            if let data = logEntry.data(using: .utf8) {
                if let fileHandle = FileHandle(forWritingAtPath: self.logFileURL.path) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                } else {
                    // Si falla FileHandle, intentar escribir directamente
                    try? data.write(to: self.logFileURL, options: .atomic)
                }
            }
        }
    }
    
    private func rotateLogsIfNeeded() {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: logFileURL.path),
              let fileSize = attributes[.size] as? Int,
              fileSize > maxLogFileSize else { return }
        
        // Rotar archivos: prey.log -> prey.log.1 -> prey.log.2 -> eliminado
        let baseURL = logFileURL.deletingPathExtension()
        let ext = logFileURL.pathExtension
        
        // Eliminar el archivo más antiguo
        let oldestFile = baseURL.appendingPathExtension("\(ext).\(maxLogFiles - 1)")
        try? FileManager.default.removeItem(at: oldestFile)
        
        // Rotar archivos existentes
        for i in stride(from: maxLogFiles - 2, through: 1, by: -1) {
            let oldFile = baseURL.appendingPathExtension("\(ext).\(i)")
            let newFile = baseURL.appendingPathExtension("\(ext).\(i + 1)")
            try? FileManager.default.moveItem(at: oldFile, to: newFile)
        }
        
        // Mover archivo actual
        let newFile = baseURL.appendingPathExtension("\(ext).1")
        try? FileManager.default.moveItem(at: logFileURL, to: newFile)
        
        // Crear nuevo archivo
        createLogFileIfNeeded()
    }
    
    func getLogFileURL() -> URL {
        return logFileURL
    }
}

/// Explicit logging API with level and category
public func PreyLogger(_ message: String, level: PreyLogLevel = .debug) {
    // Siempre escribir al archivo de log
    PreyFileLogger.shared.writeLog(message, level: level)
    
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
    PreyLogger(message, level: .info)
}

public func PreyLoggerWarn(_ message: String, file: String = #file) {
    let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    PreyLogger(message, level: .warning)
}

public func PreyLoggerError(_ message: String, file: String = #file) {
    let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    PreyLogger(message, level: .error)
}

public func PreyLoggerDebug(_ message: String, file: String = #file) {
    let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    PreyLogger(message, level: .debug)
}

public func PreyLoggerNotice(_ message: String, file: String = #file) {
    let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    PreyLogger(message, level: .notice)
}

public func PreyLoggerCritical(_ message: String, file: String = #file) {
    let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    PreyLogger(message, level: .critical)
}

// MARK: - Log File Access
public func getPreyLogFileURL() -> URL {
    return PreyFileLogger.shared.getLogFileURL()
}

public func getPreyLogFilePath() -> String {
    return PreyFileLogger.shared.getLogFileURL().path
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
