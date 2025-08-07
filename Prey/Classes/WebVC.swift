//
//  WebViewVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 28/06/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

// Block host for Apple
enum BlockHost: String {
    case WORLDPAY   = "secure.worldpay.com"
    case HELPPREY   = "help.preyproject.com"
    case PANELPREY  = "panel.preyproject.com"
    case S3AMAZON   = "s3.amazonaws.com"
    case SRCGOOGLE  = "www.google.com"
}

class WebVC: UIViewController, WKNavigationDelegate {

    // MARK: Properties

    var webView     = WKWebView()

    var actInd      = UIActivityIndicatorView()
    
    var titleView   = String()
    
    // MARK: Init

    // Init customize
    convenience init(withURL url: URL, withParameters:String?, withTitle:String) {
        
        self.init(nibName:nil, bundle:nil)
        
        self.titleView                  = withTitle

        self.view.backgroundColor       = UIColor.black
        
        let rectView                    = UIScreen.main.bounds
        
        // Config webView
        webView                         = WKWebView(frame:rectView)
        webView.backgroundColor         = UIColor.black
        webView.navigationDelegate      = self
        webView.isMultipleTouchEnabled  = true
        
        let request                     = NSMutableURLRequest(url:url)
        request.timeoutInterval         = timeoutIntervalRequest
        
        // Set params to request
        if let params = withParameters {
            request.httpMethod          = Method.POST.rawValue
            request.httpBody            = params.data(using: String.Encoding.utf8)
        }
        
        // Load request
        DispatchQueue.main.async {
            self.webView.load(request as URLRequest)
        }
        
        // Add webView to View
        self.view.addSubview(webView)

        self.actInd                     = UIActivityIndicatorView(initInView:self.view, withText:"Please wait".localized)
        webView.addSubview(actInd)
        
        // Config cancel button
        let ipadFc: CGFloat             = (IS_IPAD) ? 2 : 1
        let posX                        = rectView.size.width - 50*ipadFc
        let rectBtn                     = CGRect(x: posX, y: 7*ipadFc, width: 38*ipadFc, height: 34*ipadFc)
        let cancelButton                = UIButton(frame: rectBtn)
        cancelButton.backgroundColor    = UIColor.clear
        cancelButton.setBackgroundImage(UIImage(named:"BtCloseOff"), for:.normal)
        cancelButton.setBackgroundImage(UIImage(named:"BtCloseOn"),  for:.highlighted)
        cancelButton.addTarget(self, action: #selector(cancel), for:.touchUpInside)
        self.view.addSubview(cancelButton)
    }
    
    // Close viewController
    @objc func cancel() {
        self.dismiss(animated: true, completion:nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // View title for GAnalytics
        //self.screenName = titleView
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
        
    // Open URL from Safari
    func openBrowserWith(_ url:URL?) {
        if let urlRequest = url {
            UIApplication.shared.open(urlRequest, options: [:], completionHandler: nil)
        }
    }
    
    // MARK: WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        PreyLogger("Start load web")
        
        // Show ActivityIndicator
        DispatchQueue.main.async { self.actInd.startAnimating() }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let request = navigationAction.request
        PreyLogger("Should load request")
        
        if let host = request.url?.host {
            
            switch host {
         
                // Worldpay
            case BlockHost.WORLDPAY.rawValue:
                displayErrorAlert("This service is not available from here. Please go to 'Manage Prey Settings' from the main menu in the app.".localized,
                                  titleMessage:"Information".localized)
                decisionHandler(.cancel)
                return
                
                // Help Prey
            case BlockHost.HELPPREY.rawValue:
                openBrowserWith(URL(string:URLHelpPrey))
                decisionHandler(.cancel)
                return
            
                // Panel Prey
            case BlockHost.PANELPREY.rawValue:
                webView.evaluateJavaScript("var printBtn = document.getElementById('print'); printBtn.style.display='none';", completionHandler: nil)
                decisionHandler(.allow)
                return

                // Google Maps and image reports
            case BlockHost.S3AMAZON.rawValue:
                openBrowserWith(request.url)
                decisionHandler(.cancel)
                return
                
                // Default allow
            default:
                decisionHandler(.allow)
                return
            }
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        PreyLogger("Finish load web")
        
        // Hide ActivityIndicator
        DispatchQueue.main.async { self.actInd.stopAnimating() }
        
        // Hide ViewMap class
        webView.evaluateJavaScript("var viewMapBtn = document.getElementsByClassName('btn btn-block btn-border')[1]; viewMapBtn.style.display='none';", completionHandler: nil)
        
        // Hide addDeviceBtn
        webView.evaluateJavaScript("var addDeviceBtn = document.getElementsByClassName('btn btn-success pull-right')[0]; addDeviceBtn.style.display='none';", completionHandler: nil)
        
        // Hide accountPlans
        webView.evaluateJavaScript("var accountPlans = document.getElementById('account-plans'); accountPlans.style.display='none';", completionHandler: nil)
        
        // Hide print option
        webView.evaluateJavaScript("var printBtn = document.getElementById('print'); printBtn.style.display='none';", completionHandler: nil)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        PreyLogger("Error loading web")
        
        // Hide ActivityIndicator
        DispatchQueue.main.async { self.actInd.stopAnimating() }
        
        displayErrorAlert("Error loading web, please try again.".localized,
                          titleMessage:"We have a situation!".localized)
    }
}
