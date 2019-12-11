//
//  HomeWebVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 13/2/18.
//  Copyright © 2018 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import LocalAuthentication

class HomeWebVC: GAITrackedViewController, WKUIDelegate, WKNavigationDelegate  {

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
        let pathURL = (PreyConfig.sharedInstance.isRegistered) ? "#/\(languageES)/index\(mode)" : "#/\(languageES)/start\(mode)"
        return URLRequest(url:URL(string: pathURL, relativeTo: baseURL)!)
    }

    // MARK: Init
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        if #available(iOS 13.0, *) {
            if PreyConfig.sharedInstance.isSystemDarkMode {
                return
            }
            self.overrideUserInterfaceStyle = PreyConfig.sharedInstance.isDarkMode ? .dark : .light
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor       = UIColor.black
        
        // Config webView
        let webConfiguration            = WKWebViewConfiguration()
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
            
            // Check new version on App Store
            PreyConfig.sharedInstance.checkLastVersionOnStore()
        }
        
        // View title for GAnalytics
        self.screenName = "HomeWeb"        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool){
        // Hide navigationBar when appear this ViewController
        self.navigationController?.isNavigationBarHidden = true
        
        super.viewWillAppear(animated)
    }

    // Check TouchID/FaceID
    func checkTouchID(_ openPanelWeb: Bool) {
        
        guard PreyConfig.sharedInstance.isTouchIDEnabled == true else {
            return
        }
        
        let myContext = LAContext()
        let myLocalizedReasonString = "Would you like to use \(biometricAuth) to access the Prey settings?".localized
        var authError: NSError?
        
        guard myContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
            PreyLogger("error with biometric policy")
            return
        }
        self.showPanel = openPanelWeb
        myContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: myLocalizedReasonString) { success, evaluateError in
            
            DispatchQueue.main.async {
                guard success else {
                    PreyLogger("error with auth on touchID")
                    self.showPanel = false
                    return
                }
                
                // Show webView
                if openPanelWeb {
                    self.goToControlPanel()
                } else {
                    self.goToLocalSettings()
                }
                
                // Hide credentials webView
                self.evaluateJS(self.webView, code: "var btn = document.getElementById('cancelBtn'); btn.click();")
            }
        }
 
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
            UIApplication.shared.openURL(urlRequest)
        }
    }

    // Check password
    func checkPassword(_ pwd: String?, view: UIView, openPanelWeb: Bool) {
        
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

                // Show webView
                if openPanelWeb {
                    self.goToControlPanel()
                } else {
                    self.goToLocalSettings()
                }
                
                // Hide credentials webView
                self.evaluateJS(self.webView, code: "var btn = document.getElementById('cancelBtn'); btn.click();")
            }
        })
    }
    
    // Send GAnalytics event
    func sendEventGAnalytics() {
        if let tracker = GAI.sharedInstance().defaultTracker {
            
            let dimensionValue = PreyConfig.sharedInstance.isPro ? "Pro" : "Free"
            tracker.set(GAIFields.customDimension(for: 1), value:dimensionValue)
            
            let params:NSObject = GAIDictionaryBuilder.createEvent(withCategory: "UserActivity", action:"Log In", label:"Log In", value:nil).build()
            tracker.send(params as! [NSObject : AnyObject])
        }
    }
    
    // Add device with QRCode
    func addDeviceWithQRCode() {
        let controller:QRCodeScannerVC = QRCodeScannerVC()
        self.navigationController?.present(controller, animated:true, completion:nil)
    }
    
    // Add device
    func addDeviceWithLogin(_ email: String?, password: String?) {
        
        // Check valid email
        if isInvalidEmail(email!, withPattern:emailRegExp) {
            displayErrorAlert("Enter a valid e-mail address".localized,
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
            PreyUser.getTokenFromPanel(email!, userPassword:password!, onCompletion: {_ in })
            
            // Add Device to Panel Prey
            PreyDevice.addDeviceWith({(isSuccess: Bool) in
                
                DispatchQueue.main.async {
                    // Hide ActivityIndicator
                    actInd.stopAnimating()

                    // AddDevice isn't success
                    guard isSuccess else {
                        return
                    }
                    
                    self.loadViewOnWebView("permissions")
                }
            })
        })
    }

    // Check signUp fields
    func checkSignUpFields(_ name: String?, email: String?, password1: String?, password2: String?, term: Bool, age: Bool) {
        // Check terms and conditions
        if (!age || !term) {
            displayErrorAlert("You must accept the Terms & Conditions".localized,
                              titleMessage:"We have a situation!".localized)
            return
        }
        
        guard let nm = name else {
            displayErrorAlert("Name can't be blank".localized,
                              titleMessage:"We have a situation!".localized)
            return
        }
        
        guard let pwd1 = password1 else {
            displayErrorAlert("Password must be at least 6 characters".localized,
                              titleMessage:"We have a situation!".localized)
            return
        }

        guard let pwd2 = password2 else {
            displayErrorAlert("Password must be at least 6 characters".localized,
                              titleMessage:"We have a situation!".localized)
            return
        }

        if pwd1 != pwd2 {
            displayErrorAlert("Passwords do not match".localized,
                              titleMessage:"We have a situation!".localized)
            return
        }
        
        // Check name length
        if nm.count < 1 {
            displayErrorAlert("Name can't be blank".localized,
                              titleMessage:"We have a situation!".localized)
            return
        }

        // Check valid email
        if isInvalidEmail(email!, withPattern:emailRegExp) {
            displayErrorAlert("Enter a valid e-mail address".localized,
                              titleMessage:"We have a situation!".localized)
            return
        }

        // Check password length
        if pwd1.count < 6 {
            displayErrorAlert("Password must be at least 6 characters".localized,
                              titleMessage:"We have a situation!".localized)
            return
        }
        
        // Hide keyboard
        self.view.endEditing(true)
        
        // Show popUp to emailValidation
        self.evaluateJS(self.webView, code: "var btn = document.getElementById('btnEmailValidation'); btn.click();")
    }
    
    // Add device action
    func addDeviceWithSignUp(_ name: String?, email: String?, password1: String?, password2: String?, term: Bool, age: Bool) {

        guard let nm = name else {
            displayErrorAlert("Name can't be blank".localized,
                              titleMessage:"We have a situation!".localized)
            return
        }
        
        guard let pwd1 = password1 else {
            displayErrorAlert("Password must be at least 6 characters".localized,
                              titleMessage:"We have a situation!".localized)
            return
        }
                
        // Show ActivityIndicator
        let actInd          = UIActivityIndicatorView(initInView: self.view, withText: "Creating account...".localized)
        self.view.addSubview(actInd)
        actInd.startAnimating()
        
        // SignUp to Panel Prey
        PreyUser.signUpToPrey(nm, userEmail:email!, userPassword:pwd1, onCompletion: {(isSuccess: Bool) in
            
            // LogIn isn't Success
            guard isSuccess else {
                // Hide ActivityIndicator
                DispatchQueue.main.async {
                    actInd.stopAnimating()
                }
                return
            }
            
            // Get Token for Control Panel
            //PreyUser.getTokenFromPanel(email!, userPassword:pwd1, onCompletion: {_ in })
            
            // Add Device to Panel Prey
            PreyDevice.addDeviceWith({(isSuccess: Bool) in
                DispatchQueue.main.async {
                    // Hide ActivityIndicator
                    actInd.stopAnimating()
                    // Add Device Success
                    guard isSuccess else {
                        return
                    }
                    //self.loadViewOnWebView("permissions")
                    PreyConfig.sharedInstance.userEmail = email
                    PreyConfig.sharedInstance.saveValues()
                    self.loadViewOnWebView("emailsent")
                    self.webView.reload()
                }
            })
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
                
            // Worldpay
            case BlockHost.WORLDPAY.rawValue:
                displayErrorAlert("This service is not available from here. Please go to 'Manage Prey Settings' from the main menu in the app.".localized,
                                  titleMessage:"Information".localized)
                return decisionHandler(.cancel)
                
            // Help Prey
            case BlockHost.HELPPREY.rawValue:
                openBrowserWith(URL(string:URLHelpPrey))
                return decisionHandler(.cancel)
                
            // Panel Prey
            case BlockHost.PANELPREY.rawValue:
                evaluateJS(webView, code:"var printBtn = document.getElementById('print'); printBtn.style.display='none';")
                return decisionHandler(.allow)
                
            // Google Maps and image reports
            case BlockHost.S3AMAZON.rawValue, BlockHost.SRCGOOGLE.rawValue:
                openBrowserWith(requestUrl)
                return decisionHandler(.cancel)
                
            // Default true
            default:
                PreyLogger("Ok")
                //decisionHandler(.allow)
            }
        }
        
        // Evaluate scheme
        if let urlScheme = requestUrl.scheme {
            DispatchQueue.main.async {
                self.evaluateURLScheme(webView, scheme: urlScheme, reqUrl: requestUrl)
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
    
    func evaluateURLScheme(_ webView: WKWebView, scheme: String, reqUrl: URL) {

        switch scheme {
            
        case ReactViews.CHECKID.rawValue:
            let queryItems = URLComponents(string: reqUrl.absoluteString)?.queryItems
            guard let openPanel = queryItems?.filter({$0.name == "openPanelWeb"}).first else {return}
            self.checkTouchID(openPanel.value!.boolValue())
            
        case ReactViews.QRCODE.rawValue:
            self.addDeviceWithQRCode()
            
        case ReactViews.LOGIN.rawValue:
            let queryItems = URLComponents(string: reqUrl.absoluteString)?.queryItems
            let email = queryItems?.filter({$0.name == "preyEmailLogin"}).first
            let pwd = queryItems?.filter({$0.name == "preyPassLogin"}).first
            self.addDeviceWithLogin(email?.value, password: pwd?.value)
            
        case ReactViews.CHECKSIGNUP.rawValue:
            let queryItems = URLComponents(string: reqUrl.absoluteString)?.queryItems
            let name = queryItems?.filter({$0.name == "nameSignup"}).first
            let email = queryItems?.filter({$0.name == "emailSignup"}).first
            let pwd1 = queryItems?.filter({$0.name == "pwd1Signup"}).first
            let pwd2 = queryItems?.filter({$0.name == "pwd2Signup"}).first
            guard let term = queryItems?.filter({$0.name == "termsSignup"}).first else {return}
            guard let age  = queryItems?.filter({$0.name == "ageSignup"}).first else {return}
            self.checkSignUpFields(name?.value, email: email?.value, password1: pwd1?.value, password2: pwd2?.value, term: term.value!.boolValue(), age: age.value!.boolValue())
            
        case ReactViews.SIGNUP.rawValue:
            let queryItems = URLComponents(string: reqUrl.absoluteString)?.queryItems
            let name = queryItems?.filter({$0.name == "nameSignup"}).first
            let email = queryItems?.filter({$0.name == "emailSignup"}).first
            let pwd1 = queryItems?.filter({$0.name == "pwd1Signup"}).first
            let pwd2 = queryItems?.filter({$0.name == "pwd2Signup"}).first
            guard let term = queryItems?.filter({$0.name == "termsSignup"}).first else {return}
            guard let age  = queryItems?.filter({$0.name == "ageSignup"}).first else {return}
            self.addDeviceWithSignUp(name?.value, email: email?.value, password1: pwd1?.value, password2: pwd2?.value, term: term.value!.boolValue(), age: age.value!.boolValue())

        case ReactViews.TERMS.rawValue:
            self.showWebViewModal(URLTermsPrey, pageTitle: "Terms of Service".localized)
            
        case ReactViews.PRIVACY.rawValue:
            self.showWebViewModal(URLPrivacyPrey, pageTitle: "Privacy Policy".localized)
            
        case ReactViews.FORGOT.rawValue:
            self.showWebViewModal(URLForgotPanel, pageTitle: "Forgot Password Web")
            
        case ReactViews.AUTHLOC.rawValue:
            DeviceAuth.sharedInstance.requestAuthLocation()
            
        case ReactViews.AUTHPHOTO.rawValue:
            DeviceAuth.sharedInstance.requestAuthPhotos()
            
        case ReactViews.AUTHCONTACT.rawValue:
            DeviceAuth.sharedInstance.requestAuthContacts()
            
        case ReactViews.AUTHCAMERA.rawValue:
            DeviceAuth.sharedInstance.requestAuthCamera()
            
        case ReactViews.AUTHNOTIF.rawValue:
            DeviceAuth.sharedInstance.requestAuthNotification()
            
        case ReactViews.REPORTEXAMP.rawValue:
            self.actInd.startAnimating()
            ReportExample.sharedInstance.runReportExample(webView)

        case ReactViews.GOTOSETTING.rawValue:
            let queryItems = URLComponents(string: reqUrl.absoluteString)?.queryItems
            let pwd = queryItems?.filter({$0.name == "pwdLogin"}).first
            self.checkPassword(pwd?.value, view: self.view, openPanelWeb: false)
            
        case ReactViews.GOTOPANEL.rawValue:
            let queryItems = URLComponents(string: reqUrl.absoluteString)?.queryItems
            let pwd = queryItems?.filter({$0.name == "pwdLogin"}).first
            self.checkPassword(pwd?.value, view: self.view, openPanelWeb: true)
            
        default:
            PreyLogger("Ok")
        }
    }
}
