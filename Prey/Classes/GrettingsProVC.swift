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
    
    @IBOutlet weak var titleTxtLbl     : UILabel!
    @IBOutlet weak var messagetxtbl    : UILabel!
    @IBOutlet weak var okBtn           : UIButton!


    // MARK: Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
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
        okBtn.setTitle("Go back to preferences".localized, forState:.Normal)
    }
    
    // MARK: Functions
    
    // Go to Settings
    @IBAction func goToSettings(sender: UIButton) {
        
        // Get SharedApplication delegate
        guard let appWindow = UIApplication.sharedApplication().delegate?.window else {
            print("error with sharedApplication")
            return
        }

        // Set controller to rootViewController
        let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController

        navigationController.dismissViewControllerAnimated(true, completion:{() in

            navigationController.popViewControllerAnimated(true)
            
            if let controller:SettingsVC = navigationController.visibleViewController as? SettingsVC{
                controller.tableView.reloadData()
            }
        })
    }
}