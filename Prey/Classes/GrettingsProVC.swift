//
//  GrettingsProVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 18/07/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

class GrettingsProVC: UIViewController {
    

    // MARK: Properties
    
    @IBOutlet var titleTxtLbl     : UILabel!
    @IBOutlet var messagetxtbl    : UILabel!
    @IBOutlet var okBtn           : UIButton!


    // MARK: Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        // View title for GAnalytics
        //self.screenName = "Grettings Pro Accounts"
        
        // Set texts
        configureTexts()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureTexts() {
        messagetxtbl.text = "Thanks for your support. You've just gained access to all the Pro features, including private and direct support from us, the Prey Team.".localized
        titleTxtLbl.text  = "Congrats,\nyou're now Pro".localized
        okBtn.setTitle("Go back to preferences".localized, for:.normal)
    }
    
    // MARK: Functions
    
    // Go to Settings
    @IBAction func goToSettings(_ sender: UIButton) {
        
        // Get SharedApplication delegate
        guard let appWindow = UIApplication.shared.delegate?.window else {
            PreyLogger("error with sharedApplication")
            return
        }

        // Set controller to rootViewController
        let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController

        navigationController.dismiss(animated: true, completion:{() in

            navigationController.popViewController(animated: true)
            
            if let controller:SettingsVC = navigationController.visibleViewController as? SettingsVC{
                controller.tableView.reloadData()
            }
        })
    }
}
