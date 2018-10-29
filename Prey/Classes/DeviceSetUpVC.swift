//
//  DeviceSetUpVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 21/11/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit
import CoreLocation
import AVFoundation
import Contacts
import Photos

class DeviceSetUpVC: GAITrackedViewController {

    
    // MARK: Properties

    @IBOutlet var titleLbl    : UILabel!
    @IBOutlet var messageLbl  : UILabel!
    
    var messageTxt = ""

    // Location Service Auth
    let authLocation = CLLocationManager()

    
    // MARK: Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // View title for GAnalytics
        self.screenName = "Congratulations"
        
        configureTextButton()
        requestDeviceAuth()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool){
        // Hide navigationBar when appear this ViewController
        self.navigationController?.isNavigationBarHidden = true
        
        super.viewWillAppear(animated)
    }
    
    func configureTextButton() {
        titleLbl.text   = "Device set up!".localized.uppercased()
        messageLbl.text =  messageTxt
    }
    
    // MARK: Functions
    
    func requestDeviceAuth() {

        // Register device to Apple Push Notification Service
        PreyNotification.sharedInstance.registerForRemoteNotifications()

        // Location Service Auth
        authLocation.requestAlwaysAuthorization()
        
        // Camera Auth
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {(granted) in })
        
        // Files Retrieval Auth
        if PreyConfig.sharedInstance.isPro {
            if #available(iOS 9.0, *) {
                // Contacts Auth
                CNContactStore().requestAccess(for: .contacts, completionHandler: { (authorized: Bool, error: Error?) -> Void in })
                
                // Photo Auth
                PHPhotoLibrary.requestAuthorization({ authorization -> Void in })
            }
        }
    }
    
    // Ok pressed
    @IBAction func showHomeView(_ sender: UIButton) {
        
        // Check location aware action on device status
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyHTTPClient.sharedInstance.userRegisterToPrey(username, password:"x", params:nil, messageId:nil, httpMethod:Method.GET.rawValue, endPoint:statusDeviceEndpoint, onCompletion:PreyHTTPResponse.checkResponse(RequestType.statusDevice, preyAction:nil, onCompletion:{(isSuccess: Bool) in PreyLogger("Request check status") }))
        }
    
        // Get SharedApplication delegate
        guard let appWindow = UIApplication.shared.delegate?.window else {
            PreyLogger("error with sharedApplication")
            return
        }
        
        let resultController = self.storyboard!.instantiateViewController(withIdentifier: StoryboardIdVC.homeWeb.rawValue)
        // Set controller to rootViewController
        let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController
        
        let transition:CATransition = CATransition()
        transition.type             = CATransitionType.fade
        navigationController.view.layer.add(transition, forKey: "")
        navigationController.setViewControllers([resultController], animated: false)
    }
}
