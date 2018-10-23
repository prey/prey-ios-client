//
//  SignUpVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 20/11/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit

class SignUpVC: UserRegister {

    // MARK: Properties
    
    @IBOutlet var checkBtnYearsOld      : UIButton!
    @IBOutlet var checkTxtYearsOld      : UIButton!
    @IBOutlet var checkBtnAgreeToS      : UIButton!
    @IBOutlet var checkTxtAgreeToS      : UIButton!
    
    // MARK: Init
    
    override func viewDidLoad() {
        
        // View title for GAnalytics
        self.screenName = "Sign Up"
        
        super.viewDidLoad()

        configureTextButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func configureTextButton() {
        
        subtitleView.text               = "prey account".localized
        titleView.text                  = "SIGN UP".localized
        nameTextField.placeholder       = "username".localized
        emailTextField.placeholder      = "email".localized
        passwordTextField.placeholder   = "password".localized
        
        addDeviceButton.setTitle("CREATE MY NEW ACCOUNT".localized, for:.normal)
        changeViewBtn.setTitle("already have an account?".localized, for:.normal)
        
        checkBtnYearsOld.setImage(UIImage(named:"CheckOff"), for: .normal)
        checkBtnYearsOld.setImage(UIImage(named:"CheckOn"), for: .selected)
        checkBtnAgreeToS.setImage(UIImage(named:"CheckOff"), for: .normal)
        checkBtnAgreeToS.setImage(UIImage(named:"CheckOn"), for: .selected)

        if let attributedYearsTitle = checkTxtYearsOld.attributedTitle(for: .normal) {
            let mutableAttributedTitle = NSMutableAttributedString(attributedString: attributedYearsTitle)
            mutableAttributedTitle.replaceCharacters(in: NSMakeRange(0, mutableAttributedTitle.length), with: "I confirm that I am over 16 years old".localized)
            checkTxtYearsOld.setAttributedTitle(mutableAttributedTitle, for: .normal)
        }
        
        if let attributedTitle = checkTxtAgreeToS.attributedTitle(for: .normal) {
            let mutableAttributedTitle = NSMutableAttributedString(attributedString: attributedTitle)
            mutableAttributedTitle.replaceCharacters(in: NSMakeRange(0, mutableAttributedTitle.length), with: "I have read and agree to the Terms and Conditions and Privacy Policy".localized)
            var range = ("I have read and agree to the Terms and Conditions and Privacy Policy".localized as NSString).range(of: "Terms and Conditions".localized)
            let txtColor = UIColor(red: 53/255.0, green: 120/255.0, blue: 187/255.0, alpha: 1.0)
            mutableAttributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: txtColor , range: (range))
            range = ("I have read and agree to the Terms and Conditions and Privacy Policy".localized as NSString).range(of: "Privacy Policy".localized)
            mutableAttributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: txtColor , range: (range))
            checkTxtAgreeToS.setAttributedTitle(mutableAttributedTitle, for: .normal)
        }
        
        addDeviceButton.isEnabled = false
        addDeviceButton.alpha = 0.5
    }
    
    // Send GAnalytics event
    func sendEventGAnalytics() {
        if let tracker = GAI.sharedInstance().defaultTracker {
            let params:NSObject = GAIDictionaryBuilder.createEvent(withCategory: "Acquisition", action:"Sign Up", label:"Sign Up", value:nil).build()
            tracker.send(params as! [NSObject : AnyObject])
        }
        // Send event to AppsFlyer
        AppsFlyerTracker.shared().trackEvent("sign_up", withValues: [AFEventParamDescription: "ios_signUp"])
    }
    
    // MARK: Actions
    
    // Check button touched
    @IBAction func checkButtonTouched(_ sender: UIButton) {
        
        if (sender == checkBtnYearsOld) || (sender == checkTxtYearsOld) {
            checkBtnYearsOld.isSelected = !checkBtnYearsOld.isSelected
        }

        if (sender == checkBtnAgreeToS) || (sender == checkTxtAgreeToS) {
            checkBtnAgreeToS.isSelected = !checkBtnAgreeToS.isSelected
        }

        if (checkBtnYearsOld.isSelected) && (checkBtnAgreeToS.isSelected) {
            addDeviceButton.isEnabled = true
            addDeviceButton.alpha = 1.0
        } else {
            addDeviceButton.isEnabled = false
            addDeviceButton.alpha = 0.5
        }
    }

    //
    @IBAction func showTermOfService(_ sender: UIButton) {
        let controller : UIViewController
        if #available(iOS 10.0, *) {
            controller       = WebKitVC(withURL:URL(string:URLTermsPrey)!, withParameters:nil, withTitle:"Terms of Service".localized)
        } else {
            controller       = WebVC(withURL:URL(string:URLTermsPrey)!, withParameters:nil, withTitle:"Terms of Service".localized)
        }
        self.present(controller, animated:true, completion:nil)
    }
    
    // Show SignIn view
    @IBAction func showSignInVC(_ sender: UIButton) {
        
        // Get SharedApplication delegate
        guard let appWindow = UIApplication.shared.delegate?.window else {
            PreyLogger("error with sharedApplication")
            return
        }
        
        // Get SignInVC from Storyboard
        let controller:UIViewController = self.storyboard!.instantiateViewController(withIdentifier: StoryboardIdVC.signIn.rawValue)
        
        // Set controller to rootViewController
        let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController
        
        let transition:CATransition = CATransition()
        transition.type = CATransitionType.fade
        navigationController.view.layer.add(transition, forKey: "")
        
        navigationController.setViewControllers([controller], animated: false)
    }
    
    // Add device action
    @IBAction override func addDeviceAction(_ sender: UIButton?) {

        // Check terms and conditions
        if (!checkBtnYearsOld.isSelected) || (!checkBtnAgreeToS.isSelected) {
            displayErrorAlert("You must accept the Terms & Conditions".localized,
                              titleMessage:"We have a situation!".localized,
                              returnToTextField: nameTextField)
            return
        }
        
        // Check name length
        if nameTextField.text!.count < 1 {
            displayErrorAlert("Name can't be blank".localized,
                              titleMessage:"We have a situation!".localized,
                              returnToTextField: nameTextField)
            return
        }
        
        // Check password length
        if passwordTextField.text!.count < 6 {
            displayErrorAlert("Password must be at least 6 characters".localized,
                              titleMessage:"We have a situation!".localized,
                              returnToTextField: passwordTextField)
            return
        }
        
        // Check valid email
        if isInvalidEmail(emailTextField.text!, withPattern:emailRegExp) {
            displayErrorAlert("Enter a valid e-mail address".localized,
                              titleMessage:"We have a situation!".localized,
                              returnToTextField: emailTextField)
            return
        }
        
        // Hide keyboard
        self.view.endEditing(true)
        
        // Show ActivityIndicator
        let actInd          = UIActivityIndicatorView(initInView: self.view, withText: "Creating account...".localized)
        self.view.addSubview(actInd)
        actInd.startAnimating()        
        
        // SignUp to Panel Prey
        PreyUser.signUpToPrey(nameTextField.text!, userEmail:emailTextField.text!, userPassword:passwordTextField.text!, onCompletion: {(isSuccess: Bool) in
            
            // LogIn isn't Success
            guard isSuccess else {
                // Hide ActivityIndicator
                DispatchQueue.main.async {
                    actInd.stopAnimating()
                }
                return
            }
            
            // Get Token for Control Panel
            PreyUser.getTokenFromPanel(self.emailTextField.text!, userPassword:self.passwordTextField.text!, onCompletion: {_ in })
            
            // Add Device to Panel Prey
            PreyDevice.addDeviceWith({(isSuccess: Bool) in
                
                DispatchQueue.main.async {
                    
                    // Add Device Success
                    guard isSuccess else {
                        // Hide ActivityIndicator
                        actInd.stopAnimating()
                        return
                    }
                    
                    if let resultController = self.storyboard!.instantiateViewController(withIdentifier: StoryboardIdVC.deviceSetUp.rawValue) as? DeviceSetUpVC {
                        self.sendEventGAnalytics()
                        resultController.messageTxt = "Account created! Remember to verify your account by opening your inbox and clicking on the link we sent to your email address.".localized
                        self.navigationController?.pushViewController(resultController, animated: true)
                    }
                }
            })
        })
    }
}
