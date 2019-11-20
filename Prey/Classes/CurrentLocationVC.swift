//
//  CurrentLocationVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 13/07/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreLocation

class CurrentLocationVC: GAITrackedViewController, MKMapViewDelegate {

    
    // MARK: Properties
    
    let mapRadius   :Double = 200
    
    var actInd      : UIActivityIndicatorView!
    
    @IBOutlet var mapLocationView    : MKMapView!

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
        
        // View title for GAnalytics
        self.screenName = "Device Map"
        
        // Set title
        self.title = "Current Location".localized
        
        // Config MapView
        mapLocationView.showsUserLocation = true
    }
    
    
    // MARK:MKMapViewDelegate
    
    // DidUpdateUserLocation
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let region = MKCoordinateRegion.init(center: userLocation.coordinate, latitudinalMeters: mapRadius, longitudinalMeters: mapRadius)
        mapLocationView.setRegion(region, animated:true)
    }
    
    // WillStartLoadingMap
    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        PreyLogger("start loading map")

        // Show ActivityIndicator
        actInd = UIActivityIndicatorView(initInView: self.view, withText:"Please wait".localized)
        self.view.addSubview(actInd)
        actInd.startAnimating()
    }

    // DidFinishLoadingMap
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        PreyLogger("finish loading map")

        // Hide ActivityIndicator
        actInd.stopAnimating()
    }
    
    // DidFailLoadingMap
    func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
        PreyLogger("fail loading map")
        
        // Hide ActivityIndicator
        actInd.stopAnimating()
        
        displayErrorAlert("Error loading map, please try again.".localized,
                          titleMessage:"We have a situation!".localized)
    }
}
