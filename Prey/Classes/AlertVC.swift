//
//  AlertVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 29/06/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import UIKit

class AlertVC: UIViewController {
    
    // MARK: Properties

    @IBOutlet var messageLbl           : UILabel!
    @IBOutlet var subtitleLbl          : UILabel!

    @IBOutlet var closeButton          : UIButton!
    var messageToShow = ""
    
    
    // MARK: Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // View title for GAnalytics
       // self.screenName = "Alert"
        
        // Set message
        messageLbl.text = messageToShow
        closeButton.setTitle("Close".localized, for:.normal)
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Hide navigationBar when appear this ViewController
        self.navigationController?.isNavigationBarHidden = false
    }
    
    @IBAction func closeButton(_ sender: UIButton) {
        PreyLogger("Alert close button tapped")
        
        // Create a background task for the transition
        var bgTask = UIBackgroundTaskIdentifier.invalid
        bgTask = UIApplication.shared.beginBackgroundTask {
            if bgTask != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(bgTask)
                bgTask = UIBackgroundTaskIdentifier.invalid
                PreyLogger("Alert close background task expired")
            }
        }
        
        PreyLogger("Started alert close background task: \(bgTask.rawValue)")
        
        // Get application delegate and window
        guard let appDelegate = UIApplication.shared.delegate,
              let appWindow = appDelegate.window else {
            PreyLogger("Error with sharedApplication or window")
            if bgTask != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(bgTask)
            }
            return
        }
        
        
        // Perform UI updates on the main thread with optimized performance
        DispatchQueue.main.async {
            // Set up homeWeb screen
            let mainStoryboard = UIStoryboard(name: StoryboardIdVC.PreyStoryBoard.rawValue, bundle: nil)
            
            // Check if camouflage mode is active, and use appropriate controller
            let homeControllerID = PreyConfig.sharedInstance.isCamouflageMode ?
            StoryboardIdVC.home.rawValue :
            StoryboardIdVC.homeWeb.rawValue
            
            if let resultController = mainStoryboard.instantiateViewController(withIdentifier: homeControllerID) as? UIViewController {
                let rootVC = mainStoryboard.instantiateViewController(withIdentifier: StoryboardIdVC.navigation.rawValue) as! UINavigationController
                rootVC.setViewControllers([resultController], animated: false)
                
                // Set the new root view controller - use optional chaining with unwrapped value
                appWindow?.rootViewController = rootVC
                appWindow?.makeKeyAndVisible()
                
                PreyLogger("Set new root view controller")
            } else {
                PreyLogger("Failed to instantiate home controller")
            }
        }
        
    }

}
