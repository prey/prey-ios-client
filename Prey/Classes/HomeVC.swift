//
//  HomeVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 27/11/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit

class HomeVC: GAITrackedViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {

    
    // MARK: Properties
    
    @IBOutlet var titleLbl             : UILabel!
    @IBOutlet var subtitleLbl          : UILabel!
    @IBOutlet var shieldImg            : UIImageView!
    @IBOutlet var camouflageImg        : UIImageView!
    @IBOutlet var passwordInput        : UITextField!
    @IBOutlet var loginBtn             : UIButton!
    @IBOutlet var forgotBtn            : UIButton!
    
    @IBOutlet var accountImg           : UIImageView!
    @IBOutlet var accountSbtLbl        : UILabel!
    @IBOutlet var accountTlLbl         : UILabel!
    @IBOutlet var accountBtn           : UIButton!
    @IBOutlet var settingsImg          : UIImageView!
    @IBOutlet var settingsSbtLbl       : UILabel!
    @IBOutlet var settingsTlLbl        : UILabel!
    @IBOutlet var settingsBtn          : UIButton!
    
    @IBOutlet var tourImg              : UIImageView!
    @IBOutlet var tourBtn              : UIButton!
    
    var hidePasswordInput = false
    
    // MARK: Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // View title for GAnalytics
        self.screenName = "Login"        
        
        // Dismiss Keyboard on tap outside
        let recognizer = UITapGestureRecognizer(target: self, action:#selector(self.dismissKeyboard(_:)))
        view.addGestureRecognizer(recognizer)
        
        // Config init
        hidePasswordInputOption(hidePasswordInput)
        
        // Config Prey Tour
        configPreyTour()
        
        // Config texts
        configureTexts()
        
        // Check device auth
        checkDeviceAuth()
        
        // Check for Rate us
        PreyRateUs.sharedInstance.askForReview()
        
        // Check new version on App Store
        PreyConfig.sharedInstance.checkLastVersionOnStore()
        
        // Hide camouflage image
        configCamouflageMode(PreyConfig.sharedInstance.isCamouflageMode)
    }

    func configureTexts() {

        loginBtn.setTitle("Log In".localized, for:.normal)
        forgotBtn.setTitle("Forgot your password?".localized, for:.normal)
        
        passwordInput.placeholder   = "Type in your password".localized
        subtitleLbl.text            = "current device status".localized
        accountTlLbl.text           = "PREY ACCOUNT".localized
        accountSbtLbl.text          = "REMOTE CONTROL FROM YOUR".localized
        settingsTlLbl.text          = "PREY SETTINGS".localized
        settingsSbtLbl.text         = "CONFIGURE".localized
    }
    
    // Check device auth
    func checkDeviceAuth() {
        let isAllAuthAvailable  = DeviceAuth.sharedInstance.checkAllDeviceAuthorization()
        titleLbl.text    = isAllAuthAvailable ? "PROTECTED".localized.uppercased() : "NOT PROTECTED".localized.uppercased()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        
        // Hide navigationBar when appear this ViewController
        self.navigationController?.isNavigationBarHidden = true
        
        // Listen for changes to keyboard visibility so that we can adjust the text view accordingly.
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(HomeVC.handleKeyboardWillShowNotification(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(HomeVC.handleKeyboardWillHideNotification(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Hide navigationBar when appear this ViewController
        self.navigationController?.isNavigationBarHidden = false
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // Hide password input
    func hidePasswordInputOption(_ value:Bool) {
        // Input subview
        self.changeHiddenFor(view:self.passwordInput,   value:value)
        self.changeHiddenFor(view:self.loginBtn,        value:value)
        self.changeHiddenFor(view:self.forgotBtn,       value:value)
        
        // Menu subview
        self.changeHiddenFor(view:self.accountImg,      value:!value)
        self.changeHiddenFor(view:self.accountSbtLbl,   value:!value)
        self.changeHiddenFor(view:self.accountTlLbl,    value:!value)
        self.changeHiddenFor(view:self.accountBtn,      value:!value)
        self.changeHiddenFor(view:self.settingsImg,     value:!value)
        self.changeHiddenFor(view:self.settingsSbtLbl,  value:!value)
        self.changeHiddenFor(view:self.settingsTlLbl,   value:!value)
        self.changeHiddenFor(view:self.settingsBtn,     value:!value)
        self.changeHiddenFor(view:self.tourImg,         value:!value)
        self.changeHiddenFor(view:self.tourBtn,         value:!value)
    }
    
    // Set hidden object
    func changeHiddenFor(view:UIView!, value:Bool) {
        if view != nil {
            view.isHidden = value
        }
    }
    
    // Set camouflageMode
    func configCamouflageMode(_ isCamouflage:Bool) {

        subtitleLbl.isHidden      = isCamouflage
        titleLbl.isHidden         = isCamouflage
        shieldImg.isHidden        = isCamouflage
        
        camouflageImg.isHidden    = !isCamouflage
    }
    
    // Config Prey Tour
    func configPreyTour() {
        
        if PreyConfig.sharedInstance.hideTourWeb {
            closePreyTour()
            return
        }
        
        // Add tap gesture to View
        let tap         = UITapGestureRecognizer(target:self, action:#selector(startPreyTour))
        tap.delegate    = self
        
        // Add tap to tourImg
        tourImg.isUserInteractionEnabled = true
        tourImg.addGestureRecognizer(tap)
        
        // Add target to tourBtn
        tourBtn.addTarget(self, action:#selector(closePreyTour), for:.touchUpInside)
        
        // Check language in tourImg
        let language:String = Locale.preferredLanguages[0] as String
        let languageES = (language as NSString).substring(to: 2)
        if languageES == "es" {
            tourImg.image = UIImage(named:"TourEs")
        }
    }
    
    // Start Prey Tour
    func startPreyTour() {

        let language:String = Locale.preferredLanguages[0] as String
        let languageES  = (language as NSString).substring(to: 2)
        
        let indexPage   = (languageES == "es") ? "index-es" : "index"
        let url         = URL(fileURLWithPath: Bundle.main.path(forResource: indexPage, ofType:"html", inDirectory:"PreyTourWeb")!)
        
        let controller : UIViewController
        if #available(iOS 10.0, *) {
            controller = WebKitVC(withURL:url, withParameters:nil, withTitle:"Prey Tour")
        } else {
            controller = WebVC(withURL:url, withParameters:nil, withTitle:"Prey Tour")
        }
        self.present(controller, animated:true, completion:nil)
    }
    
    // Close Prey Tour
    func closePreyTour() {
        tourImg.removeFromSuperview()
        tourBtn.removeFromSuperview()
    }
    
    // MARK: Keyboard Event Notifications
    
    func handleKeyboardWillShowNotification(_ notification: Notification) {
        keyboardWillChangeFrameWithNotification(notification, showsKeyboard: true)
    }
    
    func handleKeyboardWillHideNotification(_ notification: Notification) {
        keyboardWillChangeFrameWithNotification(notification, showsKeyboard: false)
    }
    
    func dismissKeyboard(_ tapGesture: UITapGestureRecognizer) {
        // Dismiss keyboard if is inside from UIView
        if (self.view.frame.contains(tapGesture.location(in: self.view))) {
            self.view.endEditing(true);
        }
    }
    
    func keyboardWillChangeFrameWithNotification(_ notification: Notification, showsKeyboard: Bool) {
        let userInfo = (notification as NSNotification).userInfo!
        
        let animationDuration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        // Convert the keyboard frame from screen to view coordinates.
        let keyboardScreenBeginFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let keyboardViewBeginFrame = view.convert(keyboardScreenBeginFrame, from: view.window)
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        let originDelta = keyboardViewEndFrame.origin.y - keyboardViewBeginFrame.origin.y
        
        self.view.center.y += originDelta
        
        view.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: .beginFromCurrentState, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        let nextTage = textField.tag + 1;

        // Try to find next responder
        let nextResponder = textField.superview?.viewWithTag(nextTage) as UIResponder!
        
        if (nextResponder == nil) {
            checkPassword(nil)
        }
        return false
    }
    
    // MARK: Functions
    
    // Send GAnalytics event
    func sendEventGAnalytics() {
        if let tracker = GAI.sharedInstance().defaultTracker {
            
            let dimensionValue = PreyConfig.sharedInstance.isPro ? "Pro" : "Free"
            tracker.set(GAIFields.customDimension(for: 1), value:dimensionValue)
            
            let params:NSObject = GAIDictionaryBuilder.createEvent(withCategory: "UserActivity", action:"Log In", label:"Log In", value:nil).build()
            tracker.send(params as! [NSObject : AnyObject])
        }
    }

    // Go to Settings
    @IBAction func goToSettings(_ sender: UIButton) {
        
        if let resultController = self.storyboard!.instantiateViewController(withIdentifier: StoryboardIdVC.settings.rawValue) as? SettingsVC {
            self.navigationController?.pushViewController(resultController, animated: true)
        }
    }
    
    // Go to Control Panel
    @IBAction func goToControlPanel(_ sender: UIButton) {

        if let token = PreyConfig.sharedInstance.tokenPanel {
            let params           = String(format:"token=%@", token)
            let controller : UIViewController

            if #available(iOS 10.0, *) {
                controller       = WebKitVC(withURL:URL(string:URLSessionPanel)!, withParameters:params, withTitle:"Control Panel Web")
            } else {
                controller       = WebVC(withURL:URL(string:URLSessionPanel)!, withParameters:params, withTitle:"Control Panel Web")
            }
            self.present(controller, animated:true, completion:nil)
            
        } else {
            displayErrorAlert("Error, retry later.".localized,
                              titleMessage:"We have a situation!".localized)
        }
    }
    
    // Run web forgot
    @IBAction func runWebForgot(_ sender: UIButton) {
        let controller : UIViewController
        if #available(iOS 10.0, *) {
            controller       = WebKitVC(withURL:URL(string:URLForgotPanel)!, withParameters:nil, withTitle:"Forgot Password Web")
        } else {
            controller       = WebVC(withURL:URL(string:URLForgotPanel)!, withParameters:nil, withTitle:"Forgot Password Web")
        }
        self.present(controller, animated:true, completion:nil)
    }
    
    // Check password
    @IBAction func checkPassword(_ sender: UIButton?) {
        
        // Check password length
        guard let pwdInput = passwordInput.text else {
            displayErrorAlert("Password must be at least 6 characters".localized,
                              titleMessage:"We have a situation!".localized)
            return
        }
        if pwdInput.characters.count < 6 {
            displayErrorAlert("Password must be at least 6 characters".localized,
                              titleMessage:"We have a situation!".localized)
            return
        }
        
        // Hide keyboard
        self.view.endEditing(true)
        
        // Show ActivityIndicator
        let actInd          = UIActivityIndicatorView(initInView: self.view, withText:"Please wait".localized)
        self.view.addSubview(actInd)
        actInd.startAnimating()

        
        // Get Token for Control Panel
        PreyUser.getTokenFromPanel(PreyConfig.sharedInstance.userApiKey!, userPassword:pwdInput, onCompletion:{(isSuccess: Bool) in

            // Hide ActivityIndicator
            DispatchQueue.main.async {
                actInd.stopAnimating()
             
                // Change inputView
                if isSuccess {
                    self.sendEventGAnalytics()
                    self.hidePasswordInputOption(true)
                }
            }
        })
    }
}
