//
//  ReportExample.swift
//  Prey
//
//  Created by Javier Cala Uribe on 25/06/19.
//  Copyright © 2019 Prey, Inc. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import WebKit

class ReportExample: NSObject, WKUIDelegate, WKNavigationDelegate, PhotoServiceDelegate, LocationServiceDelegate {

    // MARK: Properties

    static let sharedInstance = ReportExample()
    override fileprivate init() {
    }

    var reportData      = NSMutableDictionary()
    var reportLocation  = ReportLocation()
    var reportPhoto : ReportPhoto = {
        if #available(iOS 10.0, *) {
            return ReportPhotoiOS10()
        } else {
            return ReportPhotoiOS8()
        }
    }()

    // MARK: Functions
    
    // Run report example
    func runReportExample(_ webView: WKWebView) {
        webView.uiDelegate              = self
        webView.navigationDelegate      = self

        reportPhoto.waitForRequest = true
        reportPhoto.delegate = self
        reportPhoto.startSession()
        
        reportLocation.waitForRequest = true
        reportLocation.delegate = self
        reportLocation.startLocation()
        
        addWifiInfo()
    }
    
    // Show report example
    func showReportExample() {
        if !reportPhoto.waitForRequest && !reportLocation.waitForRequest {
            DispatchQueue.main.async {
                guard let appWindow = UIApplication.shared.delegate?.window else {
                    PreyLogger("error with sharedApplication")
                    return
                }
                let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController
                if let homeWebVC:HomeWebVC = navigationController.topViewController as? HomeWebVC {
                    homeWebVC.loadViewOnWebView("report")
                    homeWebVC.webView.reload()
                }
            }
        }
    }
    
    // Add wifi info
    func addWifiInfo() {
        
        if let networkInfo = ReportWifi.getNetworkInfo() {
            
            guard let ssidNetwork = networkInfo["SSID"] as? String else {
                PreyLogger("Error get wifi info: SSID")
                return
            }
            
            guard let bssidNetwork = networkInfo["BSSID"] as? String else {
                PreyLogger("Error get wifi info: BSSID")
                return
            }
            
            let params:[String: String] = [
                "ssid"          : ssidNetwork,
                "mac_address"   : bssidNetwork]
            
            // Save network info to reportData
            reportData.addEntries(from: params)
        }
    }
    
    // MARK: ReportPhoto Delegate
    
    // Photos received
    func photoReceived(_ photos:NSMutableDictionary) {
        PreyLogger("get photos")
        reportPhoto.stopSession()
        reportPhoto.removeObserver()
        reportPhoto.waitForRequest = false
        showReportExample()
    }
    
    // MARK: ReportLocation Delegate
    
    // Location received
    func locationReceived(_ location:[CLLocation]) {
        if let loc = location.first {
            let params:[String : Any] = [
                kReportLocation.LONGITURE.rawValue    : loc.coordinate.longitude,
                kReportLocation.LATITUDE.rawValue     : loc.coordinate.latitude,
                kReportLocation.ALTITUDE.rawValue     : loc.altitude,
                kReportLocation.ACCURACY.rawValue     : loc.horizontalAccuracy]
            
            reportData.addEntries(from: params)
        }
        reportLocation.waitForRequest = false
        reportLocation.stopLocation()
        showReportExample()
    }

    // MARK: WKUIDelegate
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        PreyLogger("Start:: load WKWebView")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        PreyLogger("Should:: load request: WKWebView")
        return decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        PreyLogger("Finish:: load WKWebView")
        DispatchQueue.main.async {
            self.loadDataFromReport(webView)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        PreyLogger("Error loading WKWebView")
        returnDelegateToMainWebView()
    }
    
    func evaluateJS(_ view: WKWebView, code: String) {
        DispatchQueue.main.async {
            view.evaluateJavaScript(code, completionHandler:nil)
        }
    }
    
    func loadDataFromReport(_ webView: WKWebView) {
        
        if reportPhoto.photoArray.count == 0 {
            if let imgtheft = UIImage(named:"Theft"), let imgData = imgtheft.pngData() {
                let imageITData = imgData.base64EncodedString()
                evaluateJS(webView, code:"var photoBack = document.getElementById('imgBack'); photoBack.src=\"data:image/png;base64,\(imageITData)\";")
            }
        } else {
            for (key, value) in reportPhoto.photoArray {
                guard let img = value as? UIImage else {
                    return
                }
                let imgId = ((key as! String) == "picture") ? "imgFront" : "imgBack"
                if let imgData = img.pngData() {
                    let imageITData = imgData.base64EncodedString()
                    evaluateJS(webView, code:"var photoBack = document.getElementById('\(imgId)'); photoBack.src=\"data:image/png;base64,\(imageITData)\";")
                }
            }
        }
        
        evaluateJS(webView, code:"document.getElementById('model').innerHTML='\(UIDevice.current.deviceModel)'")
        
        if let latData = reportData[kReportLocation.LATITUDE.rawValue] as? NSNumber, let lngData = reportData[kReportLocation.LONGITURE.rawValue] as? NSNumber {
            evaluateJS(webView, code:"document.getElementById('lat').innerHTML='\(latData)'")
            evaluateJS(webView, code:"document.getElementById('lng').innerHTML='\(lngData)'")
            
            addMapView(webView, coord: CLLocationCoordinate2D(latitude: latData as! Double, longitude: lngData as! Double))
        } else {
            addMapView(webView, coord: CLLocationCoordinate2D(latitude: 37.78583400, longitude: -122.40641700))
        }
        
        returnDelegateToMainWebView()
    }
    
    func addMapView(_ webView: WKWebView, coord:CLLocationCoordinate2D) {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: coord, latitudinalMeters: 550, longitudinalMeters: 550)
        options.size = CGSize(width: 350, height: 300)
        
        let bgQueue = DispatchQueue.global(qos: .background)
        let snapShotter = MKMapSnapshotter(options: options)
        snapShotter.start(with: bgQueue, completionHandler: { (snapshot, error) in
            DispatchQueue.main.async {
                guard error == nil else {
                    return
                }
                if let snapShotImage = snapshot?.image {
                    if let imgMapData = snapShotImage.pngData() {
                        let imageMapData = imgMapData.base64EncodedString()
                        self.evaluateJS(webView, code:"var photoBack = document.getElementById('imgMap'); photoBack.src=\"data:image/png;base64,\(imageMapData)\";")
                    }
                }
            }
        })
    }
    
    func returnDelegateToMainWebView() {
        // Hide ActivityIndicator
        DispatchQueue.main.async {
            guard let appWindow = UIApplication.shared.delegate?.window else {
                PreyLogger("error with sharedApplication")
                return
            }
            let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController
            if let homeWebVC:HomeWebVC = navigationController.topViewController as? HomeWebVC {
                homeWebVC.actInd.stopAnimating()
                homeWebVC.webView.uiDelegate              = homeWebVC
                homeWebVC.webView.navigationDelegate      = homeWebVC
            }
        }
    }
}


