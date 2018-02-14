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

class HomeWebVC: GAITrackedViewController {

    // MARK: Properties

    var actInd      = UIActivityIndicatorView()
    let rectView    = UIScreen.main.bounds
    let request     = URLRequest(url:URL(fileURLWithPath: Bundle.main.path(forResource: "index", ofType:"html", inDirectory:"PreyInfo")!))

    // MARK: Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check device auth
        checkDeviceAuth()
        
        // Check for Rate us
        PreyRateUs.sharedInstance.askForReview()
        
        // Check new version on App Store
        PreyConfig.sharedInstance.checkLastVersionOnStore()
        
        // View title for GAnalytics
        self.screenName = "HomeWeb"
        
        // Init VC
        let controller  : UIViewController
        if #available(iOS 8.0, *) {
            controller = HomeWebiOS8VC()
        } else {
            controller = HomeWebiOS7VC()
        }
        self.present(controller, animated:false, completion:nil)
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
    func checkDeviceAuth() {
        //let isAllAuthAvailable  = DeviceAuth.sharedInstance.checkAllDeviceAuthorization()
        //titleLbl.text    = isAllAuthAvailable ? "PROTECTED".localized.uppercased() : "NOT PROTECTED".localized.uppercased()
    }
    
    // Open URL from Safari
    func openBrowserWith(_ url:URL?) {
        if let urlRequest = url {
            UIApplication.shared.openURL(urlRequest)
        }
    }

    // MARK: ViewsDelegate
    
    func startWebView() {
        PreyLogger("Start load WKWebView")
        // Show ActivityIndicator
        actInd.startAnimating()
    }
    
    func checkWebView(_ view: Any, mainRequest: URLRequest) -> Bool {
        PreyLogger("Should load request: WKWebView")
        if let host = mainRequest.url?.host {
            switch host {
                
            // Worldpay
            case BlockHost.WORLDPAY.rawValue:
                displayErrorAlert("This service is not available from here. Please go to 'Manage Prey Settings' from the main menu in the app.".localized,
                                  titleMessage:"Information".localized)
                return false
                
            // Help Prey
            case BlockHost.HELPPREY.rawValue:
                openBrowserWith(URL(string:URLHelpPrey))
                return false
                
            // Panel Prey
            case BlockHost.PANELPREY.rawValue:
                evaluateJS(view, code:"var printBtn = document.getElementById('print'); printBtn.style.display='none';")
                return true
                
            // Google Maps and image reports
            case BlockHost.S3AMAZON.rawValue, BlockHost.SRCGOOGLE.rawValue:
                openBrowserWith(mainRequest.url)
                return false
                
            // Default true
            default:
                PreyLogger("Ok")
                //decisionHandler(.allow)
            }
        }
        
        // Check scheme for PreyTourWeb
        if mainRequest.url?.scheme == "closewebview" {
            return false
        }
        return true
    }
    
    func finishWebView(_ view: Any) {
        PreyLogger("Finish load WKWebView")
        // Hide ActivityIndicator
        actInd.stopAnimating()
                
        // Hide ViewMap class
        evaluateJS(view, code:"var viewMapBtn = document.getElementsByClassName('btn btn-block btn-border')[1]; viewMapBtn.style.display='none';")
        
        // Hide addDeviceBtn
        evaluateJS(view, code:"var addDeviceBtn = document.getElementsByClassName('btn btn-success pull-right')[0]; addDeviceBtn.style.display='none';")
        
        // Hide accountPlans
        evaluateJS(view, code:"var accountPlans = document.getElementById('account-plans'); accountPlans.style.display='none';")
        
        // Hide print option
        evaluateJS(view, code:"var printBtn = document.getElementById('print'); printBtn.style.display='none';")
    }
    
    func failWebView() {
        PreyLogger("Error loading WKWebView")
        // Hide ActivityIndicator
        actInd.stopAnimating()
        displayErrorAlert("Error loading web, please try again.".localized,
                          titleMessage:"We have a situation!".localized)
    }
    
    func evaluateJS(_ view: Any, code: String) {
        if #available(iOS 8.0, *) {
            (view as! WKWebView).evaluateJavaScript(code, completionHandler:nil)
        } else {
            (view as! UIWebView).stringByEvaluatingJavaScript(from: code)
        }
    }
}
// ===================================
// MARK: HomeWebVC for iOS 8 and later
// ===================================
@available(iOS 8.0, *)
class HomeWebiOS8VC: HomeWebVC, WKUIDelegate, WKNavigationDelegate {
    
    // MARK: Properties
   
    var webView     = WKWebView()
    
    // MARK: Init
    
    override func viewDidLoad() {
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
    }
    
    // MARK: WKUIDelegate
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        startWebView()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if checkWebView(webView, mainRequest: navigationAction.request) {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finishWebView(webView)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        failWebView()
    }
}

// ===================================
// MARK: HomeWebVC for iOS 7 only
// ===================================
class HomeWebiOS7VC: HomeWebVC, UIWebViewDelegate {
    
    // MARK: Properties
    
    var webView     = UIWebView()
    
    // MARK: Init
    
    // Init customize
    override func viewDidLoad() {
        self.view.backgroundColor       = UIColor.black
        
        // Config webView
        webView                         = UIWebView(frame:rectView)
        webView.backgroundColor         = UIColor.black
        webView.delegate                = self
        webView.isMultipleTouchEnabled  = true
        webView.scalesPageToFit         = true
        
        // Load request
        webView.loadRequest(request)
        
        // Add webView to View
        self.view.addSubview(webView)
        
        self.actInd                     = UIActivityIndicatorView(initInView:self.view, withText:"Please wait".localized)
        webView.addSubview(actInd)
    }
    
    // MARK: UIWebViewDelegate
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        startWebView()
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return checkWebView(webView, mainRequest:request)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        finishWebView(webView)
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        failWebView()
    }
}

