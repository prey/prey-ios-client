//
//  PurchasesVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 27/11/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit

class PurchasesVC: UIViewController {

    
    // MARK: Properties
    
    @IBOutlet weak var titleTxtLbl     : UILabel!
    @IBOutlet weak var messagetxtbl    : UILabel!
    @IBOutlet weak var planTxtLbl      : UILabel!
    @IBOutlet weak var buyBtn          : UIButton!
    
    
    // MARK: Init

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Upgrade to Pro".localized
        
        // Set texts
        configureTexts()
        
        // Config Buy button format
        if (PreyStoreManager.sharedInstance.purchasableObjects.count > 0) {
            configureBuyButton()
        }
    }

    // Set texts
    func configureTexts() {
        planTxtLbl.text     = "Personal Plan, 1 year".localized
        titleTxtLbl.text    = "FULL PROTECTION FOR YOUR DEVICES".localized
        messagetxtbl.text   = "100 reports per device \nUltra-fast frecuency for reports \nScan hardware for changes \nGeofencing for Home plans and over \nPriority support".localized
    }
    
    // Config button format
    func configureBuyButton() {

        // Currency Format
        let numberFormatter                 = NSNumberFormatter()
        numberFormatter.formatterBehavior   = .Behavior10_4
        numberFormatter.numberStyle         = .CurrencyStyle

        if let product = PreyStoreManager.sharedInstance.purchasableObjects.first {

            numberFormatter.locale  = product.priceLocale
            let formattedString     = NSString(format:"%@", numberFormatter.stringFromNumber(product.price)!) as String
            
            buyBtn.setTitle(formattedString, forState:.Normal)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: Functions
    
    // Buy Subscription
    @IBAction func buySubscription(sender: UIButton) {

        guard let product = PreyStoreManager.sharedInstance.purchasableObjects.first else {
            displayErrorAlert("Canceled transaction, please try again.".localized,
                              titleMessage:"Information".localized)
            return
        }

        // Show ActivityIndicator
        let actInd          = UIActivityIndicatorView(initInView:self.view, withText:"Please wait".localized)
        self.view.addSubview(actInd)
        actInd.startAnimating()

        // Request purchase to App Store
        PreyStoreManager.sharedInstance.buyFeature(product.productIdentifier,
            onComplete:{(productId:String, receiptData:NSData) -> Void in
                // Success
                dispatch_async(dispatch_get_main_queue()) {
                    actInd.stopAnimating()
                    
                    // Update isPro in PreyConfig
                    PreyConfig.sharedInstance.isPro = true
                    PreyConfig.sharedInstance.saveValues()
                    
                    // Show GrettingsProVC
                    self.showGrettingsProVC()
                }
            }, onCancelled: {() -> Void in
                // Cancelled
                dispatch_async(dispatch_get_main_queue()) {
                    actInd.stopAnimating()
                    displayErrorAlert("Canceled transaction, please try again.".localized,
                        titleMessage:"Information".localized)
                }
        })
    }
    
    // Show GrettingsProVC
    func showGrettingsProVC() {
        if let resultController = self.storyboard!.instantiateViewControllerWithIdentifier(StoryboardIdVC.grettings.rawValue) as? GrettingsProVC {
            self.navigationController?.presentViewController(resultController, animated: true, completion:nil)
        }
    }
}


