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
    convenience init(withURL url: NSURL, withParameters:String?, withTitle:String) {
        
        self.init(nibName:nil, bundle:nil)
        
        self.titleView                  = withTitle

        self.view.backgroundColor       = UIColor.blackColor()
        
        let rectView                    = UIScreen.mainScreen().bounds
        
        // Config webView
        webView                         = UIWebView(frame:rectView)
        webView.backgroundColor         = UIColor.blackColor()
        webView.delegate                = self
        webView.multipleTouchEnabled    = true
        webView.scalesPageToFit         = true
        
        let request                     = NSMutableURLRequest(URL:url)
        
        // Set params to request
        if let params = withParameters {
            request.HTTPMethod          = Method.POST.rawValue
            request.HTTPBody            = params.dataUsingEncoding(NSUTF8StringEncoding)
        }
        
        // Load request
        webView.loadRequest(request)
        
        // Add webView to View
        self.view.addSubview(webView)

        self.actInd                     = UIActivityIndicatorView(initInView:self.view, withText:"Please wait".localized)
        webView.addSubview(actInd)
        
        // Config cancel button
        let ipadFc: CGFloat             = (IS_IPAD) ? 2 : 1
        let posX                        = rectView.size.width - 50*ipadFc
        let rectBtn                     = CGRectMake(posX, 7*ipadFc, 38*ipadFc, 34*ipadFc)
        let cancelButton                = UIButton(frame: rectBtn)
        cancelButton.backgroundColor    = UIColor.clearColor()
        cancelButton.setBackgroundImage(UIImage(named:"BtCloseOff"), forState:.Normal)
        cancelButton.setBackgroundImage(UIImage(named:"BtCloseOn"),  forState:.Highlighted)
        cancelButton.addTarget(self, action: #selector(cancel), forControlEvents:.TouchUpInside)
        self.view.addSubview(cancelButton)
    }
    
    // Close viewController
    func cancel() {
        self.dismissViewControllerAnimated(true, completion:nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // View title for GAnalytics
        self.screenName = titleView
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func closePreyTourWebView() {
        
        if let controller = self.presentingViewController as? UINavigationController {
            let homeVC = controller.topViewController as! HomeVC
            homeVC.closePreyTour()
        }
        
        PreyConfig.sharedInstance.hideTourWeb = true
        PreyConfig.sharedInstance.saveValues()
        cancel()
    }
    
    // Open URL from Safari
    func openBrowserWith(url:NSURL?) {
        if let urlRequest = url {
            UIApplication.sharedApplication().openURL(urlRequest)
        }
    }
    
    // MARK: UIWebViewDelegate
    
    func webViewDidStartLoad(webView: UIWebView) {
        PreyLogger("Start load web")
        
        // Show ActivityIndicator
        actInd.startAnimating()
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        PreyLogger("Should load request")
        
        if let host = request.URL?.host {
            
            switch host {
         
                // Worldpay
            case BlockHost.WORLDPAY.rawValue:
                displayErrorAlert("This service is not available from here. Please go to 'Manage Prey Settings' from the main menu in the app.".localized,
                                  titleMessage:"Information".localized)
                return false
                
                // Help Prey
            case BlockHost.HELPPREY.rawValue:
                openBrowserWith(NSURL(string:URLHelpPrey))
                return false
            
                // Panel Prey
            case BlockHost.PANELPREY.rawValue:
                webView.stringByEvaluatingJavaScriptFromString("var printBtn = document.getElementById('print'); printBtn.style.display='none';")
                return true

                // Google Maps and image reports
            case BlockHost.S3AMAZON.rawValue, BlockHost.SRCGOOGLE.rawValue:
                openBrowserWith(request.URL)
                return false
                
                // Default true
            default:
                return true
            }
        }
        
        // Check scheme for PreyTourWeb
        if request.URL?.scheme == "closewebview" {
            closePreyTourWebView()
            return false
        }
        
        return true
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        PreyLogger("Finish load web")
        
        // Hide ActivityIndicator
        actInd.stopAnimating()
        
        // Hide ViewMap class
        webView.stringByEvaluatingJavaScriptFromString("var viewMapBtn = document.getElementsByClassName('btn btn-block btn-border js-toggle-report-map')[1]; viewMapBtn.style.display='none';")
        
        // Hide addDeviceBtn
        webView.stringByEvaluatingJavaScriptFromString("var addDeviceBtn = document.getElementsByClassName('btn btn-success js-add-device pull-right')[0]; addDeviceBtn.style.display='none';")
        
        // Hide accountPlans
        webView.stringByEvaluatingJavaScriptFromString("var accountPlans = document.getElementById('account-plans'); accountPlans.style.display='none';")
        
        // Hide print option
        webView.stringByEvaluatingJavaScriptFromString("var printBtn = document.getElementById('print'); printBtn.style.display='none';")
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        PreyLogger("Error loading web")
        
        // Hide ActivityIndicator
        actInd.stopAnimating()
        
        displayErrorAlert("Error loading web, please try again.".localized,
                          titleMessage:"We have a situation!".localized)
    }
}