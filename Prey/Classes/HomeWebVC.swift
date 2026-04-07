//
//  HomeWebVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 13/2/18.
//  Copyright © 2018 Prey, Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import LocalAuthentication

class HomeWebVC: UIViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler  {

    // MARK: Properties
    
    var webView     = WKWebView()
    var showPanel   = false
    var checkAuth   = true
    var actInd      = UIActivityIndicatorView()
    let rectView    = UIScreen.main.bounds
    var request     : URLRequest {
        
        let mode = PreyConfig.sharedInstance.getDarkModeState(self)
        
        // Set language for webView
        let language:String = Locale.preferredLanguages[0] as String
        var languageES  = (language as NSString).substring(to: 2)
        if (languageES != "es") {languageES = "en"}
        let indexPage   = "index"
        let baseURL = URL(fileURLWithPath: Bundle.main.path(forResource:indexPage, ofType:"html", inDirectory:"ReactViews")!)
        let startState = "start"
        let pathURL = (PreyConfig.sharedInstance.isRegistered) ? "#/\(languageES)/index\(mode)" : "#/\(languageES)/\(startState)\(mode)"
        return URLRequest(url:URL(string: pathURL, relativeTo: baseURL)!)
    }

    // MARK: Init
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        if PreyConfig.sharedInstance.isSystemDarkMode {
            return
        }
        self.overrideUserInterfaceStyle = PreyConfig.sharedInstance.isDarkMode ? .dark : .light
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor       = UIColor.black
        
        // Config webView
        let webConfiguration            = WKWebViewConfiguration()
        webConfiguration.userContentController.add(self, name: "prey")
        webView                         = WKWebView(frame:rectView, configuration:webConfiguration)
        webView.backgroundColor         = UIColor.black
        webView.uiDelegate              = self
        webView.navigationDelegate      = self
        webView.isMultipleTouchEnabled  = true
        webView.allowsBackForwardNavigationGestures = false
        
        // Load request
        webView.load(request)
        
        // Add webView to View
        self.view.addSubview(webView)
        
        self.actInd                     = UIActivityIndicatorView(initInView:self.view, withText:"Please wait".localized)
        webView.addSubview(actInd)
        
        if (PreyConfig.sharedInstance.isRegistered) {
            // Check for Rate us
            PreyRateUs.sharedInstance.askForReview()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool){
        // Hide navigationBar when appear this ViewController
        self.navigationController?.isNavigationBarHidden = true
        
        super.viewWillAppear(animated)
    }

    
    // Check device auth
    func checkDeviceAuth(webView: WKWebView) {
        guard checkAuth == true else {
            return
        }
        DeviceAuth.sharedInstance.checkAllDeviceAuthorization { granted in
            DispatchQueue.main.async {
                let titleTxt            = granted ? "protected".localized : "unprotected".localized
                self.evaluateJS(webView, code:"document.getElementById('txtStatusDevice').innerHTML = '\(titleTxt)';")
                self.checkAuth = false
            }
        }
    }
    
    // Open URL from Safari
    func openBrowserWith(_ url:URL?) {
        if let urlRequest = url {
            UIApplication.shared.open(urlRequest, options: [:], completionHandler: nil)
        }
    }

    // Navigate to destination after successful auth
    func navigateAfterAuth(_ back: String) {
        self.evaluateJS(self.webView, code: "var btn = document.getElementById('cancelBtn'); if(btn) btn.click();")
        switch back {
        case "panel":
            self.goToControlPanel()
        case "setting", "settings":
            self.goToLocalSettings()
        case "close":
            self.goToCloseAccount()
        default:
            self.goToRename()
        }
    }

    // Authenticate with biometrics, fallback to password
    func authenticateWithBiometrics(back: String) {
        PreyLogger("authenticateWithBiometrics back: \(back)")

        guard PreyConfig.sharedInstance.isTouchIDEnabled else {
            PreyLogger("Biometric auth disabled by user")
            notifyAuthFallback(back)
            return
        }

        let context = LAContext()
        var authError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
            PreyLogger("Biometrics not available: \(String(describing: authError))")
            notifyAuthFallback(back)
            return
        }

        let reason = "Authenticate to access Prey settings".localized
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                guard success else {
                    PreyLogger("Biometric auth failed: \(String(describing: error))")
                    return
                }
                PreyLogger("Biometric auth success, navigating to: \(back)")
                self.sendEventGAnalytics()
                self.navigateAfterAuth(back)
            }
        }
    }

    // Notify React to show password fallback
    func notifyAuthFallback(_ back: String) {
        let js = "window.dispatchEvent(new CustomEvent('preyAuthFallback', {detail: {back: '\(back)'}}));"
        evaluateJS(webView, code: js)
    }

    // Check password
    func checkPassword(_ pwd: String?, view: UIView, back: String) {

        // Check password length
        guard let pwdInput = pwd else {
            displayErrorAlert("Password must be at least 6 characters".localized,
                              titleMessage:"We have a situation!".localized)
            return
        }
        if pwdInput.count < 6 {
            displayErrorAlert("Password must be at least 6 characters".localized,
                              titleMessage:"We have a situation!".localized)
            return
        }

        // Hide keyboard
        self.view.endEditing(true)

        // Show ActivityIndicator
        let actInd          = UIActivityIndicatorView(initInView: self.view, withText:"Please wait".localized)
        self.view.addSubview(actInd)
        actInd.startAnimating()

        // Check userApiKey length
        guard let userApiKey = PreyConfig.sharedInstance.userApiKey else {
            displayErrorAlert("Wrong password. Try again.".localized,
                              titleMessage:"We have a situation!".localized)
            return
        }

        // Get Token for Control Panel
        PreyUser.getTokenFromPanel(userApiKey, userPassword:pwdInput, onCompletion:{(isSuccess: Bool) in

            // Hide ActivityIndicator
            DispatchQueue.main.async {
                actInd.stopAnimating()

                // Check sucess request
                guard isSuccess else {
                    return
                }

                // Show Settings View
                self.sendEventGAnalytics()

                self.navigateAfterAuth(back)
            }
        })
    }
    
    // Send GAnalytics event
    func sendEventGAnalytics() {
//        if let tracker = GAI.sharedInstance().defaultTracker {
//            
//            let dimensionValue = PreyConfig.sharedInstance.isPro ? "Pro" : "Free"
//            tracker.set(GAIFields.customDimension(for: 1), value:dimensionValue)
//            
//            let params:NSObject = GAIDictionaryBuilder.createEvent(withCategory: "UserActivity", action:"Log In", label:"Log In", value:nil).build()
//            tracker.send(params as! [NSObject : AnyObject])
//        }
    }
    
    // Add device with QRCode
    func addDeviceWithQRCode() {
        let controller:QRCodeScannerVC = QRCodeScannerVC()
        if #available(iOS 13, *) {controller.modalPresentationStyle = .fullScreen}
        self.navigationController?.present(controller, animated:true, completion:nil)
    }
    
    // Add device
    func addDeviceWithLogin(_ email: String?, password: String?) {
        
        // Check valid email
        if isInvalidEmail(email!, withPattern:emailRegExp) {
            displayErrorAlert("Enter a valid email address".localized,
                              titleMessage:"We have a situation!".localized)
            return
        }
        
        // Check password length
        if password!.count < 6 {
            displayErrorAlert("Password must be at least 6 characters".localized,
                              titleMessage:"We have a situation!".localized)
            return
        }
        
        // Hide keyboard
        self.view.endEditing(true)
        
        // Show ActivityIndicator
        let actInd          = UIActivityIndicatorView(initInView: self.view, withText: "Attaching device...".localized)
        self.view.addSubview(actInd)
        actInd.startAnimating()
        
        // LogIn to Panel Prey
        PreyUser.logInToPrey(email!, userPassword: password!, onCompletion: {(isSuccess: Bool) in
            
            // LogIn isn't Success
            guard isSuccess else {
                // Hide ActivityIndicator
                DispatchQueue.main.async {
                    actInd.stopAnimating()
                }
                return
            }
            
            // Get Token for Control Panel
            //PreyUser.getTokenFromPanel(email!, userPassword:password!, onCompletion: {_ in })
            
            // Add Device to Panel Prey
            PreyDevice.addDeviceWith({(isSuccess: Bool) in

                // AddDevice isn't success
                guard isSuccess else {
                    DispatchQueue.main.async {
                        actInd.stopAnimating()
                    }
                    return
                }

                // Fetch device info to get the name assigned by the backend
                PreyDevice.infoDevice({(infoSuccess: Bool) in
                    PreyLogger("infoDevice after addDevice isSuccess:\(infoSuccess)")
                    DispatchQueue.main.async {
                        actInd.stopAnimating()
                        self.loadViewOnWebView("activation")
                    }
                })
            })
        })
    }
    
    func renameDevice(_ newName: String?){
        PreyDevice.renameDevice(newName! ,onCompletion: {(isSuccess: Bool) in
            if(isSuccess){
                PreyConfig.sharedInstance.nameDevice = newName
                PreyConfig.sharedInstance.saveValues()
            }
            self.loadViewOnWebView("index")
            self.webView.reload()
        })
    }

    // Show webView on modal
    func showWebViewModal(_ urlString: String, pageTitle: String) {
        let controller : UIViewController
        if #available(iOS 10.0, *) {
            controller       = WebKitVC(withURL:URL(string:urlString)!, withParameters:nil, withTitle:pageTitle)
        } else {
            controller       = WebVC(withURL:URL(string:urlString)!, withParameters:nil, withTitle:pageTitle)
        }
        if #available(iOS 13, *) {controller.modalPresentationStyle = .fullScreen}
        self.present(controller, animated:true, completion:nil)
    }

    
    // Load view on webView
    func loadViewOnWebView(_ view:String) {
        let mode = PreyConfig.sharedInstance.getDarkModeState(self)
        var request     : URLRequest
        let language:String = Locale.preferredLanguages[0] as String
        var languageES  = (language as NSString).substring(to: 2)
        if (languageES != "es") {languageES = "en"}
        let indexPage   = "index"
        let baseURL = URL(fileURLWithPath: Bundle.main.path(forResource:indexPage, ofType:"html", inDirectory:"ReactViews")!)
        let pathURL = "#/\(languageES)/\(view)\(mode)"
        request = URLRequest(url:URL(string: pathURL, relativeTo: baseURL)!)

        webView.load(request)
    }
    
    // Go to Control Panel
    func goToControlPanel() {
        if let token = PreyConfig.sharedInstance.tokenPanel {
            let params           = String(format:"token=%@", token)
            let controller : UIViewController
            
            if #available(iOS 10.0, *) {
                controller       = WebKitVC(withURL:URL(string:URLSessionPanel)!, withParameters:params, withTitle:"Control Panel Web")
            } else {
                controller       = WebVC(withURL:URL(string:URLSessionPanel)!, withParameters:params, withTitle:"Control Panel Web")
            }
            if #available(iOS 13, *) {controller.modalPresentationStyle = .fullScreen}
            self.present(controller, animated:true, completion:nil)            
        } else {
            displayErrorAlert("Error, retry later.".localized,
                              titleMessage:"We have a situation!".localized)
        }
    }

    // Go to Close Account
    func goToCloseAccount() {
        if let token = PreyConfig.sharedInstance.tokenPanel {
            let params           = String(format:"token=%@", token)
            let controller : UIViewController
            if #available(iOS 10.0, *) {
                controller       = WebKitVC(withURL:URL(string:URLCloseAccount)!, withParameters:params, withTitle:"Control Panel Web")
            } else {
                controller       = WebVC(withURL:URL(string:URLCloseAccount)!, withParameters:params, withTitle:"Control Panel Web")
            }
            if #available(iOS 13, *) {controller.modalPresentationStyle = .fullScreen}
            self.present(controller, animated:true, completion:nil)
        } else {
            displayErrorAlert("Error, retry later.".localized,
                                  titleMessage:"We have a situation!".localized)
        }
    }
    
    // Go to Local Settings
    func goToLocalSettings() {
        guard let appWindow = UIApplication.shared.delegate?.window else {
            PreyLogger("error with sharedApplication")
            return
        }
        guard let rootVC = appWindow?.rootViewController else {
            PreyLogger("error with rootVC")
            return
        }
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name:StoryboardIdVC.PreyStoryBoard.rawValue, bundle: nil)
        let resultController = mainStoryboard.instantiateViewController(withIdentifier: StoryboardIdVC.settings.rawValue)
        (rootVC as! UINavigationController).pushViewController(resultController, animated: true)
    }
    
    func goToRename(){
        self.loadViewOnWebView("rename")
        self.webView.reload()
    }
    
    // MARK: WKUIDelegate
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        PreyLogger("Start load WKWebView")
        // Show ActivityIndicator
        DispatchQueue.main.async { self.actInd.startAnimating() }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        PreyLogger("Should load request: WKWebView")
        
        guard let requestUrl = navigationAction.request.url else {
            return decisionHandler(.allow)
        }
        
        if let host = requestUrl.host {
            switch host {
            // Help Prey
            case BlockHost.HELPPREY.rawValue:
                openBrowserWith(URL(string:URLHelpPrey))
                return decisionHandler(.cancel)
                
            // Panel Prey
            case BlockHost.PANELPREY.rawValue:
                evaluateJS(webView, code:"var printBtn = document.getElementById('print'); printBtn.style.display='none';")
                return decisionHandler(.allow)
                
            // Google Maps and image reports
            case BlockHost.S3AMAZON.rawValue:
                openBrowserWith(requestUrl)
                return decisionHandler(.cancel)
                
            // Default true
            default:
                PreyLogger("Ok")
                //decisionHandler(.allow)
            }
        }
        
        return decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        PreyLogger("Finish load WKWebView")
        // Hide ActivityIndicator
        DispatchQueue.main.async { self.actInd.stopAnimating() }
        
        // Hide ViewMap class
        evaluateJS(webView, code:"var viewMapBtn = document.getElementsByClassName('btn btn-block btn-border')[1]; viewMapBtn.style.display='none';")
        
        // Hide addDeviceBtn
        evaluateJS(webView, code:"var addDeviceBtn = document.getElementsByClassName('btn btn-success pull-right')[0]; addDeviceBtn.style.display='none';")
        
        // Hide accountPlans
        evaluateJS(webView, code:"var accountPlans = document.getElementById('account-plans'); accountPlans.style.display='none';")
        
        // Hide print option
        evaluateJS(webView, code:"var printBtn = document.getElementById('print'); printBtn.style.display='none';")
        
        // Check device auth
        if (PreyConfig.sharedInstance.isRegistered) {
            checkDeviceAuth(webView: webView)
        }
        
        // Email validation reactView
        if let email = PreyConfig.sharedInstance.userEmail {
            evaluateJS(webView, code:"document.getElementById('userEmail').value='\(email)';")
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        PreyLogger("Error loading WKWebView")
        // Hide ActivityIndicator
        DispatchQueue.main.async { self.actInd.stopAnimating() }
        displayErrorAlert("Error loading web, please try again.".localized,
                          titleMessage:"We have a situation!".localized)
    }

    func evaluateJS(_ view: WKWebView, code: String) {
        DispatchQueue.main.async {
            view.evaluateJavaScript(code, completionHandler:nil)
        }
    }
    
    // MARK: WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "prey",
              let body = message.body as? [String: Any],
              let action = body["action"] as? String else {
            return
        }
        PreyLogger("postMessage action: \(action) body: \(body)")
        let rawParams = body["params"] as? [String: Any] ?? [:]
        var params = [String: String]()
        for (key, value) in rawParams {
            let str = "\(value)"
            params[key] = str.removingPercentEncoding ?? str
        }

        DispatchQueue.main.async {
            switch action {
            case ReactViews.AUTHLOC.rawValue:
                DeviceAuth.sharedInstance.requestAuthLocation()
            case ReactViews.LOGIN.rawValue:
                self.addDeviceWithLogin(params["preyEmailLogin"], password: params["preyPassLogin"])
            case ReactViews.QRCODE.rawValue:
                self.addDeviceWithQRCode()
            case ReactViews.CHECKID.rawValue:
                let back = params["openPanelWeb"] ?? "setting"
                self.authenticateWithBiometrics(back: back)
            case ReactViews.RENAME.rawValue:
                self.renameDevice(params["newName"])
            case ReactViews.TERMS.rawValue:
                self.showWebViewModal(URLTermsPrey, pageTitle: "Terms of Service".localized)
            case ReactViews.PRIVACY.rawValue:
                self.showWebViewModal(URLPrivacyPrey, pageTitle: "Privacy Policy".localized)
            case ReactViews.CREATEACCOUNT.rawValue:
                self.showWebViewModal(URLCreateAccountPanel, pageTitle: "Create Account Web")
            case ReactViews.FORGOT.rawValue:
                self.showWebViewModal(URLForgotPanel, pageTitle: "Forgot Password Web")
            case ReactViews.BIOAUTH.rawValue:
                let back = params["back"] ?? "setting"
                self.authenticateWithBiometrics(back: back)
            case ReactViews.GOTOSETTING.rawValue:
                self.checkPassword(params["pwdLogin"], view: self.view, back: "setting")
            case ReactViews.GOTOPANEL.rawValue:
                self.checkPassword(params["pwdLogin"], view: self.view, back: "panel")
            case ReactViews.GOTORENAME.rawValue:
                self.checkPassword(params["pwdLogin"], view: self.view, back: "rename")
            case ReactViews.GOTOCLOSE.rawValue:
                self.checkPassword(params["pwdLogin"], view: self.view, back: "close")
            case ReactViews.NAMEDEVICE.rawValue:
                let nameDevice = PreyConfig.sharedInstance.nameDevice ?? UIDevice.current.name
                self.evaluateJS(self.webView, code: "document.getElementById('currentName').value = '\(nameDevice)';")
                self.evaluateJS(self.webView, code: "document.getElementById('name_device_1').innerText = '\(nameDevice)';")
                if PreyConfig.sharedInstance.isMsp {
                    self.evaluateJS(self.webView, code: "document.getElementById('name_device_0').innerText = '\(nameDevice)';")
                    self.evaluateJS(self.webView, code: "var div2 = document.getElementById('ctas'); div2.remove();")
                }
            case ReactViews.INDEX.rawValue:
                self.loadViewOnWebView("index")
                self.webView.reload()
            default:
                PreyLogger("Unknown postMessage action: \(action)")
            }
        }
    }

}
