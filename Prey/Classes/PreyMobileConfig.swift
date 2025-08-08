//
//  PreyMobileConfig.swift
//  Prey
//
//  Created by Javier Cala Uribe on 13/6/17.
//  Modified by Patricio Jofré on 04/08/2025.
//  Copyright © 2017 Prey, Inc. All rights reserved.
//

import Foundation
import UIKit

class PreyMobileConfig: NSObject, UIActionSheetDelegate {
    
    // MARK: Singleton
    
    static let sharedInstance = PreyMobileConfig()
    fileprivate override init() {

    }
    
    // Start service
  func startService(authToken: String, urlServer: String, accountId: Int) {
        PreyLogger("📣 PREY CONFIG: Starting service")
        let defaultSessionConfiguration = URLSessionConfiguration.default
        let defaultSession = URLSession(configuration: defaultSessionConfiguration)

        let url = URL(string: urlServer)
        var urlRequest = URLRequest(url: url!)
        urlRequest.timeoutInterval = timeoutIntervalRequest
        
        guard let userKey = PreyConfig.sharedInstance.userApiKey else {
            displayErrorAlert("Error loading web, please try again.".localized, titleMessage:"Couldn't add your device".localized)
            return
        }

        let params : [String:Any] = [
            "account_id"        : accountId,
            "user_key"          : userKey,
            "device_key"        : PreyConfig.sharedInstance.getDeviceKey()]

        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options:JSONSerialization.WritingOptions.prettyPrinted)
        } catch let error as NSError{
            PreyConfig.sharedInstance.reportError(error)
            PreyLogger("params error: \(error.localizedDescription)")
        }
        
        urlRequest.addValue("Bearer " + authToken, forHTTPHeaderField: "Authorization")
        urlRequest.httpMethod = Method.POST.rawValue
        
        let dataTask = defaultSession.dataTask(with: urlRequest) { (data, response, error) in
            PreyLogger("PreyResponse: data:\(String(describing: data)) \nresponse:\(String(describing: response)) \nerror:\(String(describing: error))")
            
            guard error == nil else {
                PreyConfig.sharedInstance.reportError(error)
                let alertMessage = error?.localizedDescription
                displayErrorAlert(alertMessage!.localized, titleMessage:"Couldn't add your device".localized)
                return
            }
            
            if let dat = data {
                DispatchQueue.main.async {
                    self.start(data: dat)
                }
            }
        }
        
        // Fire the request
        dataTask.resume()
    }
    
    private enum ConfigState: Int {
        case Stopped, Ready, InstalledConfig, BackToApp
    }
    
    internal let listeningPort: in_port_t = 8080
    internal var configName: String = "Profile install"
    private var localServer: HttpServer!
    private var returnURL: String = ""
    private var configData: Data!
    
    private var serverState: ConfigState = .Stopped
    private var startTime: NSDate!
    private var registeredForNotifications = false
    private var backgroundTask = UIBackgroundTaskIdentifier.invalid
    
    deinit {
        unregisterFromNotifications()
    }
    
    //MARK:- Control functions
    
    internal func start(data: Data) {
        self.configData = data
        self.localServer = HttpServer()
        self.setupHandlers()
        
        let page = self.baseURL(pathComponent: "install/")
        let url = URL(string: page)!
        if UIApplication.shared.canOpenURL(url as URL) {
            do {
                try localServer.start(listeningPort, forceIPv4: false, priority: .default)
                
                startTime = NSDate()
                serverState = .Ready
                registerForNotifications()
                UIApplication.shared.open(url, options: [:]) { success in
                    PreyLogger("Open URL result: \(success)")
                    if !success {
                        PreyLogger("Failed to open URL: \(url)")
                    }
                }
            } catch let error as NSError {
                PreyLogger("error: \(error.localizedDescription)")
                self.stop()
            }
        }
    }
    
    internal func stop() {
        if serverState != .Stopped {
            serverState = .Stopped
            unregisterFromNotifications()
        }
    }
    
    //MARK:- Private functions
    
    private func setupHandlers() {
        localServer["/install"] = { request in
            switch self.serverState {
            case .Stopped:
                return .notFound
            case .Ready:
                self.serverState = .InstalledConfig
                return HttpResponse.raw(200, "OK", ["Content-Type": "application/x-apple-aspen-config"], { writer in
                    do {
                        try writer.write(self.configData)
                    } catch {
                        PreyLogger("Failed to write response data")
                    }
                })
            case .InstalledConfig:
                return .movedPermanently(self.returnURL)
            case .BackToApp:
                let page = self.basePage(pathComponent: nil)
                return .ok(.html(page))
            }
        }
    }
    
    private func baseURL(pathComponent: String?) -> String {
        var page = "http://localhost:\(listeningPort)"
        if let component = pathComponent {
            page += "/\(component)"
        }
        return page
    }
    
    private func basePage(pathComponent: String?) -> String {
        var page = "<!doctype html><html>" + "<head><meta charset='utf-8'><title>\(self.configName)</title></head>"
        if let component = pathComponent {
            let script = "function load() {  window.location.href='\(self.baseURL(pathComponent: component))'; }window.setInterval(load, 800);"
            
            page += "<script>\(script)</script>"
        }
        page += "<body></body></html>"
        return page
    }
    
    private func returnedToApp() {
        if serverState != .Stopped {
            serverState = .BackToApp
            localServer.stop()
        }
    }
    
    private func registerForNotifications() {
        if !registeredForNotifications {
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
            registeredForNotifications = true
        }
    }
    
    private func unregisterFromNotifications() {
        if registeredForNotifications {
            let notificationCenter = NotificationCenter.default
            notificationCenter.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
            notificationCenter.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
            registeredForNotifications = false
        }
    }
    
    @objc internal func didEnterBackground(notification: NSNotification) {
        if serverState != .Stopped {
            startBackgroundTask()
        }
    }
    
    @objc internal func willEnterForeground(notification: NSNotification) {
        if backgroundTask != UIBackgroundTaskIdentifier.invalid {
            stopBackgroundTask()
            returnedToApp()
        }
    }
    
    private func startBackgroundTask() {
        let application = UIApplication.shared
        backgroundTask = application.beginBackgroundTask(expirationHandler: { [weak self] in
            PreyLogger("⚠️ PreyMobileConfig background task expiring")
            DispatchQueue.main.async {
                self?.stopBackgroundTask()
                // Stop the HTTP server if background task expires
                self?.stop()
            }
        })
        
        if backgroundTask != .invalid {
            PreyLogger("Started PreyMobileConfig background task: \(backgroundTask.rawValue)")
            
            // Add 25-second timeout for safety
            DispatchQueue.main.asyncAfter(deadline: .now() + 25.0) { [weak self] in
                if let self = self, self.backgroundTask != .invalid {
                    PreyLogger("PreyMobileConfig background task timeout (25s)")
                    self.stopBackgroundTask()
                    self.stop() // Stop the HTTP server
                }
            }
        }
    }
    
    private func stopBackgroundTask() {
        if backgroundTask != UIBackgroundTaskIdentifier.invalid {
            PreyLogger("Stopping PreyMobileConfig background task: \(backgroundTask.rawValue)")
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            backgroundTask = UIBackgroundTaskIdentifier.invalid
        }
    }
}
