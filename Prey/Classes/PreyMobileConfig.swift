//
//  PreyMobileConfig.swift
//  Prey
//
//  Created by Javier Cala Uribe on 13/6/17.
//  Copyright © 2017 Fork Ltd. All rights reserved.
//

import Foundation

class PreyMobileConfig: NSObject, UIActionSheetDelegate {
    
    // MARK: Singleton
    
    static let sharedInstance = PreyMobileConfig()
    fileprivate override init() {

    }
    
    // Start service
    func startService(urlServer: String, accountId: Int) {
        
        let defaultSessionConfiguration = URLSessionConfiguration.default
        let defaultSession = URLSession(configuration: defaultSessionConfiguration)

        let url = URL(string: urlServer)
        var urlRequest = URLRequest(url: url!)

        let params : [String:Any] = [
            "auth_token"        : tokenApi,
            "account_id"        : accountId,
            "device_key"        : PreyConfig.sharedInstance.getDeviceKey()]

        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options:JSONSerialization.WritingOptions.prettyPrinted)
        } catch let error as NSError{
            PreyConfig.sharedInstance.reportError(error)
            PreyLogger("params error: \(error.localizedDescription)")
        }
                
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
                self.start(data: dat)
            }
        }
        
        // Fire the request
        dataTask.resume()
    }
    
    private enum ConfigState: Int {
        case Stopped, Ready, InstalledConfig, BackToApp
    }
    
    // FIXME: Change token
    internal let tokenApi = "t0k3n4p1"
    
    internal let listeningPort: in_port_t = 8080
    internal var configName: String = "Profile install"
    private var localServer: HttpServer!
    private var returnURL: String = ""
    private var configData: Data!
    
    private var serverState: ConfigState = .Stopped
    private var startTime: NSDate!
    private var registeredForNotifications = false
    private var backgroundTask = UIBackgroundTaskInvalid
    
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
                UIApplication.shared.openURL(url)
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
            notificationCenter.addObserver(self, selector: #selector(didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
            notificationCenter.addObserver(self, selector: #selector(willEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
            registeredForNotifications = true
        }
    }
    
    private func unregisterFromNotifications() {
        if registeredForNotifications {
            let notificationCenter = NotificationCenter.default
            notificationCenter.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
            notificationCenter.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
            registeredForNotifications = false
        }
    }
    
    internal func didEnterBackground(notification: NSNotification) {
        if serverState != .Stopped {
            startBackgroundTask()
        }
    }
    
    internal func willEnterForeground(notification: NSNotification) {
        if backgroundTask != UIBackgroundTaskInvalid {
            stopBackgroundTask()
            returnedToApp()
        }
    }
    
    private func startBackgroundTask() {
        let application = UIApplication.shared
        backgroundTask = application.beginBackgroundTask(expirationHandler: {
            DispatchQueue.main.async {
                self.stopBackgroundTask()
            }
        })
    }
    
    private func stopBackgroundTask() {
        if backgroundTask != UIBackgroundTaskInvalid {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            backgroundTask = UIBackgroundTaskInvalid
        }
    }
}
