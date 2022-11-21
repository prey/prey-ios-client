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
        guard let appWindow = UIApplication.shared.delegate?.window else {
            PreyLogger("error with sharedApplication")
            return
        }
        let mainStoryboard: UIStoryboard    = UIStoryboard(name:StoryboardIdVC.PreyStoryBoard.rawValue, bundle: nil)
        let resultController = mainStoryboard.instantiateViewController(withIdentifier: StoryboardIdVC.homeWeb.rawValue)
        let rootVC: UINavigationController  = mainStoryboard.instantiateViewController(withIdentifier: StoryboardIdVC.navigation.rawValue) as! UINavigationController
        rootVC.setViewControllers([resultController], animated: false)
        appWindow?.rootViewController = rootVC
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
        }
    }

}
