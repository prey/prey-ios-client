//
//  WebViewVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 28/06/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

// Block host for Apple
enum BlockHost: String {
    case WORLDPAY   = "secure.worldpay.com"
    case HELPPREY   = "help.preyproject.com"
    case PANELPREY  = "panel.preyproject.com"
    case S3AMAZON   = "s3.amazonaws.com"
    case SRCGOOGLE  = "www.google.com"
}

class WebVC: GAITrackedViewController, UIWebViewDelegate {

    // MARK: Properties

    var webView     = UIWebView()

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
        webView                         = UIWebView(frame:rectView)
        webView.backgroundColor         = UIColor.black
        webView.delegate                = self
        webView.isMultipleTouchEnabled    = true
        webView.scalesPageToFit         = true
        
        let request                     = NSMutableURLRequest(url:url)
        request.timeoutInterval         = timeoutIntervalRequest
        
        // Set params to request
        if let params = withParameters {
            request.httpMethod          = Method.POST.rawValue
            request.httpBody            = params.data(using: String.Encoding.utf8)
        }
        
        // Load request
        DispatchQueue.main.async {
            self.webView.loadRequest(request as URLRequest)
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
    
    // MARK: UIWebViewDelegate
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        PreyLogger("Start load web")
        
        // Show ActivityIndicator
        DispatchQueue.main.async { self.actInd.startAnimating() }
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        PreyLogger("Should load request")
        
        if let host = request.url?.host {
            
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
                webView.stringByEvaluatingJavaScript(from: "var printBtn = document.getElementById('print'); printBtn.style.display='none';")
                return true

                // Google Maps and image reports
            case BlockHost.S3AMAZON.rawValue:
                openBrowserWith(request.url)
                return false
                
                // Default true
            default:
                return true
            }
        }
        
        return true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        PreyLogger("Finish load web")
        
        // Hide ActivityIndicator
        DispatchQueue.main.async { self.actInd.stopAnimating() }
        
        // Hide ViewMap class
        webView.stringByEvaluatingJavaScript(from: "var viewMapBtn = document.getElementsByClassName('btn btn-block btn-border')[1]; viewMapBtn.style.display='none';")
        
        // Hide addDeviceBtn
        webView.stringByEvaluatingJavaScript(from: "var addDeviceBtn = document.getElementsByClassName('btn btn-success pull-right')[0]; addDeviceBtn.style.display='none';")
        
        // Hide accountPlans
        webView.stringByEvaluatingJavaScript(from: "var accountPlans = document.getElementById('account-plans'); accountPlans.style.display='none';")
        
        // Hide print option
        webView.stringByEvaluatingJavaScript(from: "var printBtn = document.getElementById('print'); printBtn.style.display='none';")
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        PreyLogger("Error loading web")
        
        // Hide ActivityIndicator
        DispatchQueue.main.async { self.actInd.stopAnimating() }
        
        displayErrorAlert("Error loading web, please try again.".localized,
                          titleMessage:"We have a situation!".localized)
    }
}
