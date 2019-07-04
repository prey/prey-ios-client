//
//  WebKitVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 28/06/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class WebKitVC: GAITrackedViewController, WKUIDelegate, WKNavigationDelegate {

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
        let webConfiguration            = WKWebViewConfiguration()
        webView                         = WKWebView(frame:rectView, configuration:webConfiguration)
        webView.backgroundColor         = UIColor.black
        webView.uiDelegate              = self
        webView.navigationDelegate      = self
        webView.isMultipleTouchEnabled  = true
        webView.allowsBackForwardNavigationGestures = true
        
        var request                     = URLRequest(url:url)
        request.timeoutInterval         = timeoutIntervalRequest
        
        // Set params to request
        if let params = withParameters {
            sendRequestWithToken(params: params, request: request)
        } else {
            // Load request
            webView.load(request)
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

    // Send request with parameter to panel
    func sendRequestWithToken(params: String, request:URLRequest) {
        var req                 = request
        req.httpMethod          = Method.POST.rawValue
        req.httpBody            = params.data(using: String.Encoding.utf8)
        
        let sessionConfig       = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = ["User-Agent" : "Mozilla/5.0"]
        
        let session = URLSession(configuration: sessionConfig)
        let task    = session.dataTask(with: req) { (data, response, error) in
            
            guard error == nil, let resp = response, let urlResp = resp.url else {
                PreyLogger("Error loading WKWebView")
                // Hide ActivityIndicator
                DispatchQueue.main.async { self.actInd.stopAnimating() }
                displayErrorAlert("Error loading web, please try again.".localized,
                                  titleMessage:"We have a situation!".localized)
                return
            }
            
            //let info = String(data:data!, encoding:String.Encoding.utf8)
            //PreyLogger("response:\(response)")
            //PreyLogger("data:\(info)")
            
            let urlPanel        = URL(string: urlResp.absoluteString + "?webview")
            var panelRequest    = URLRequest(url: urlPanel!)
            let arrayHeader     = (response as! HTTPURLResponse).allHeaderFields as? [String:String]
            var cookiePanel     = ""
            for (key,value) in arrayHeader! {
                if key == "Set-Cookie" {
                    cookiePanel = value
                }
            }
            panelRequest.addValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
            panelRequest.setValue(cookiePanel, forHTTPHeaderField: "Cookie")
            panelRequest.timeoutInterval = timeoutIntervalRequest
            
            DispatchQueue.main.async {
                self.webView.load(panelRequest)
            }
        }
        task.resume()
    }
    
    
    // Close viewController
    @objc func cancel() {
        self.dismiss(animated: true, completion:nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // View title for GAnalytics
        self.screenName = titleView
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
        
    // Open URL from Safari
    func openBrowserWith(_ url:URL?) {
        if let urlRequest = url {
            UIApplication.shared.openURL(urlRequest)
        }
    }
    
    
    // MARK: WKUIDelegate
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        PreyLogger("Start load WKWebView")
        
        // Show ActivityIndicator
        DispatchQueue.main.async { self.actInd.startAnimating() }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        PreyLogger("Should load request: WKWebView:\(navigationAction.request)")
        
        let mainRequest = navigationAction.request
        
        if let host = mainRequest.url?.host {
            
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
                webView.evaluateJavaScript("var printBtn = document.getElementById('print'); printBtn.style.display='none';", completionHandler:nil)
                decisionHandler(.allow)
                return

                // Google Maps and image reports
            case BlockHost.S3AMAZON.rawValue, BlockHost.SRCGOOGLE.rawValue:
                openBrowserWith(mainRequest.url)
                decisionHandler(.cancel)
                return
                
                // Default true
            default:
                PreyLogger("Ok")
                //decisionHandler(.allow)
            }
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        PreyLogger("Finish load WKWebView")
        
        // Hide ActivityIndicator
        DispatchQueue.main.async { self.actInd.stopAnimating() }

        // Hide ViewMap class
        webView.evaluateJavaScript("var viewMapBtn = document.getElementsByClassName('btn btn-block btn-border')[1]; viewMapBtn.style.display='none';", completionHandler:nil)
        
        // Hide addDeviceBtn
        webView.evaluateJavaScript("var addDeviceBtn = document.getElementsByClassName('btn btn-success pull-right')[0]; addDeviceBtn.style.display='none';", completionHandler:nil)
        
        // Hide accountPlans
        webView.evaluateJavaScript("var accountPlans = document.getElementById('account-plans'); accountPlans.style.display='none';", completionHandler:nil)
        
        // Hide print option
        webView.evaluateJavaScript("var printBtn = document.getElementById('print'); printBtn.style.display='none';", completionHandler:nil)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        PreyLogger("Error loading WKWebView")
        
        // Hide ActivityIndicator
        DispatchQueue.main.async { self.actInd.stopAnimating() }
        
        displayErrorAlert("Error loading web, please try again.".localized,
                          titleMessage:"We have a situation!".localized)
    }
}
