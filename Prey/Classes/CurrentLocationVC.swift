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
    
    @IBOutlet weak var mapLocationView    : MKMapView!

    // MARK: Init
    
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
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        let region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, mapRadius, mapRadius)
        mapLocationView.setRegion(region, animated:true)
    }
    
    // WillStartLoadingMap
    func mapViewWillStartLoadingMap(mapView: MKMapView) {
        PreyLogger("start loading map: \(mapView.userLocation.coordinate)")

        // Show ActivityIndicator
        actInd = UIActivityIndicatorView(initInView: self.view, withText:"Please wait".localized)
        self.view.addSubview(actInd)
        actInd.startAnimating()
    }

    // DidFinishLoadingMap
    func mapViewDidFinishLoadingMap(mapView: MKMapView) {
        PreyLogger("finish loading map: \(mapView.userLocation.coordinate)")

        // Hide ActivityIndicator
        actInd.stopAnimating()
    }
    
    // DidFailLoadingMap
    func mapViewDidFailLoadingMap(mapView: MKMapView, withError error: NSError) {
        PreyLogger("fail loading map")
        
        // Hide ActivityIndicator
        actInd.stopAnimating()
        
        displayErrorAlert("Error loading map, please try again.".localized,
                          titleMessage:"We have a situation!".localized)
    }
}