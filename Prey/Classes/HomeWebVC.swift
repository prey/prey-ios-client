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

class HomeWebVC: GAITrackedViewController, WKUIDelegate, WKNavigationDelegate  {

    // MARK: Properties
    
    var webView     = WKWebView()
    var checkAuth   = true
    var actInd      = UIActivityIndicatorView()
    let rectView    = UIScreen.main.bounds
    var request     : URLRequest {
        // Set language for webView
        let language:String = Locale.preferredLanguages[0] as String
        let languageES  = (language as NSString).substring(to: 2)
        let indexPage   = (languageES == "es") ? "index-es" : "index"
        return URLRequest(url:URL(fileURLWithPath: Bundle.main.path(forResource:indexPage, ofType:"html", inDirectory:"PreyInfo")!))
    }

    // MARK: Init
    
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
        webView.allowsBackForwardNavigationGestures = true
        
        // Load request
        webView.load(request)
        
        // Add webView to View
        self.view.addSubview(webView)
        
        self.actInd                     = UIActivityIndicatorView(initInView:self.view, withText:"Please wait".localized)
        webView.addSubview(actInd)
        
        // Check for Rate us
        PreyRateUs.sharedInstance.askForReview()
        
        // Check new version on App Store
        PreyConfig.sharedInstance.checkLastVersionOnStore()
        
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
    
    // Check device auth
    func checkDeviceAuth(webView: WKWebView) {
        guard checkAuth == true else {
            return
        }
        let isAllAuthAvailable  = DeviceAuth.sharedInstance.checkAllDeviceAuthorization()
        let titleTxt            = isAllAuthAvailable ? "protected" : "unprotected"
        evaluateJS(webView, code:"document.getElementById('wrap').className = '\(titleTxt)';")
        checkAuth = false
    }
    
    // Open URL from Safari
    func openBrowserWith(_ url:URL?) {
        if let urlRequest = url {
            UIApplication.shared.openURL(urlRequest)
        }
    }

    // Check password
    func checkPassword(_ pwd: String?, view: Any) {
        
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
        
        
        // Get Token for Control Panel
        PreyUser.getTokenFromPanel(PreyConfig.sharedInstance.userApiKey!, userPassword:pwdInput, onCompletion:{(isSuccess: Bool) in
            
            // Hide ActivityIndicator
            DispatchQueue.main.async {
                actInd.stopAnimating()
                
                // Check sucess request
                guard isSuccess else {
                    return
                }
                
                // Show Settings View
                self.sendEventGAnalytics()
                
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
                
                // Hide credentials webView
                self.evaluateJS(self.webView, code:"$('.popover').removeClass(\"show\");")
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
    
    // MARK: WKUIDelegate
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        PreyLogger("Start load WKWebView")
        // Show ActivityIndicator
        DispatchQueue.main.async { self.actInd.startAnimating() }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        PreyLogger("Should load request: WKWebView")
        if let host = navigationAction.request.url?.host {
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
                openBrowserWith(navigationAction.request.url)
                return decisionHandler(.cancel)
                
            // Default true
            default:
                PreyLogger("Ok")
                //decisionHandler(.allow)
            }
        }
        
        // Check scheme for Settings View
        if navigationAction.request.url?.scheme == "iossettings" {
            DispatchQueue.main.async {
                self.checkPassword(navigationAction.request.url?.host, view:self.view)
            }
            return decisionHandler(.allow)
        }
        // Check scheme for AuthDevice
        if navigationAction.request.url?.scheme == "ioscheckauth" {
            _ = DeviceAuth.sharedInstance.checkAllDeviceAuthorization()
            return decisionHandler(.allow)
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
        checkDeviceAuth(webView: webView)
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
}
