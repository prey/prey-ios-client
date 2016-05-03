//
//  DeviceSetUpVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 21/11/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit

class DeviceSetUpVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register device to Apple Push Notification Service
        PreyNotification.sharedInstance.registerForRemoteNotifications()        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool){
        // Hide navigationBar when appear this ViewController
        self.navigationController?.navigationBarHidden = true
        
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool){
        // Show navigationBar when disappear this ViewController
        self.navigationController?.navigationBarHidden = false
        
        super.viewDidDisappear(animated)
    }
}
