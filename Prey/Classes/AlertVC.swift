//
//  AlertVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 29/06/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import UIKit

class AlertVC: UIViewController {
    
    // MARK: Properties

    @IBOutlet var messageLbl           : UILabel!
    @IBOutlet var subtitleLbl          : UILabel!

    var messageToShow = ""
    
    
    // MARK: Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // View title for GAnalytics
       // self.screenName = "Alert"
        
        // Set message
        messageLbl.text = messageToShow
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
}
