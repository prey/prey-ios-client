//
//  PurchasesVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 27/11/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit

class PurchasesVC: GAITrackedViewController {

    
    // MARK: Properties
    
    @IBOutlet var titleTxtLbl     : UILabel!
    @IBOutlet var messagetxtbl    : UILabel!
    @IBOutlet var planTxtLbl      : UILabel!
    @IBOutlet var buyBtn          : UIButton!
    
    
    // MARK: Init

    override func viewDidLoad() {
        super.viewDidLoad()

        // View title for GAnalytics
        self.screenName = "Upgrade to Pro II"        
        
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
        let numberFormatter                 = NumberFormatter()
        numberFormatter.formatterBehavior   = .behavior10_4
        numberFormatter.numberStyle         = .currency

        if let product = PreyStoreManager.sharedInstance.purchasableObjects.first {

            numberFormatter.locale  = product.priceLocale
            let formattedString     = NSString(format:"%@", numberFormatter.string(from: product.price)!) as String
            
            buyBtn.setTitle(formattedString, for:.normal)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: Functions
    
    // Buy Subscription
    @IBAction func buySubscription(_ sender: UIButton) {

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
            onComplete:{(productId:String, receiptData:Data) -> Void in
                // Success
                DispatchQueue.main.async {
                    actInd.stopAnimating()
                    
                    // Send event to AppsFlyer
                    AppsFlyerTracker.shared().trackEvent(AFEventPurchase, withValues: [AFEventParamCurrency : "USD", AFEventParamRevenue: 54.99 ])
                    
                    // Update isPro in PreyConfig
                    PreyConfig.sharedInstance.isPro = true
                    PreyConfig.sharedInstance.saveValues()
                    
                    // Show GrettingsProVC
                    self.showGrettingsProVC()
                }
            }, onCancelled: {() -> Void in
                // Cancelled
                DispatchQueue.main.async {
                    actInd.stopAnimating()
                    displayErrorAlert("Canceled transaction, please try again.".localized,
                        titleMessage:"Information".localized)
                }
        })
    }
    
    // Show GrettingsProVC
    func showGrettingsProVC() {
        if let resultController = self.storyboard!.instantiateViewController(withIdentifier: StoryboardIdVC.grettings.rawValue) as? GrettingsProVC {
            self.navigationController?.present(resultController, animated: true, completion:nil)
        }
    }
}


