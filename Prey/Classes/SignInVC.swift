//
//  SignInVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 20/11/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit

class SignInVC: UserRegister {

    
    // MARK: Init
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureTextButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()        
    }
    
    func configureTextButton() {
        
        subtitleView.text               = "prey account".localized
        titleView.text                  = "SIGN IN".localized
        emailTextField.placeholder      = "email".localized
        passwordTextField.placeholder   = "password".localized
        
        addDeviceButton.setTitle("ACCESS TO MY ACCOUNT".localized, forState:.Normal)
        changeViewBtn.setTitle("don’t have an account?".localized, forState:.Normal)
    }
    
    
    // MARK: Actions

    // Show SignUp view
    @IBAction func showSignUpVC(sender: UIButton) {
    
        // Get SharedApplication delegate
        guard let appWindow = UIApplication.sharedApplication().delegate?.window else {
            print("error with sharedApplication")
            return
        }

        // Get SignUpVC from Storyboard
        if let controller:UIViewController = self.storyboard!.instantiateViewControllerWithIdentifier(StoryboardIdVC.signUp.rawValue) {
            
            // Set controller to rootViewController
            let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController
            
            let transition:CATransition = CATransition()
            transition.type = kCATransitionFade
            navigationController.view.layer.addAnimation(transition, forKey: "")
            
            navigationController.setViewControllers([controller], animated: false)
        }
    }

    // Add device action    
    @IBAction override func addDeviceAction(sender: UIButton?) {
        
        // Check valid email
        if isInvalidEmail(emailTextField.text!, withPattern:emailRegExp) {
            displayErrorAlert("Enter a valid e-mail address".localized,
                              titleMessage:"We have a situation!".localized,
                              returnToTextField: emailTextField)
            return
        }

        // Check password length
        if passwordTextField.text!.characters.count < 6 {
            displayErrorAlert("Password must be at least 6 characters".localized,
                              titleMessage:"We have a situation!".localized,
                              returnToTextField: passwordTextField)
            return
        }
        
        // Hide keyboard
        self.view.endEditing(true)

        // Show ActivityIndicator
        let actInd          = UIActivityIndicatorView(initInView: self.view, withText: "Attaching device...".localized)
        self.view.addSubview(actInd)
        actInd.startAnimating()

        // LogIn to Panel Prey
        PreyUser.logInToPrey(emailTextField.text!, userPassword: passwordTextField.text!, onCompletion: {(isSuccess: Bool) in

            // LogIn isn't Success
            guard isSuccess else {
                // Hide ActivityIndicator
                dispatch_async(dispatch_get_main_queue()) {
                     actInd.stopAnimating()
                }
                return
            }
            
            // Get Token for Control Panel
            PreyUser.getTokenFromPanel(self.emailTextField.text!, userPassword:self.passwordTextField.text!, onCompletion: {_ in })
            
            // Add Device to Panel Prey
            PreyDevice.addDeviceWith({(isSuccess: Bool) in
                
                dispatch_async(dispatch_get_main_queue()) {
                    // AddDevice isn't success
                    guard isSuccess else {
                        // Hide ActivityIndicator
                         actInd.stopAnimating()
                        return
                    }
                    
                    // Add Device Success
                    if let resultController = self.storyboard!.instantiateViewControllerWithIdentifier(StoryboardIdVC.deviceSetUp.rawValue) as? DeviceSetUpVC {

                        resultController.messageTxt = "Congratulations! You have successfully associated this iOS device with your Prey account.".localized
                        self.navigationController?.pushViewController(resultController, animated: true)
                    }
                }
            })
        })
    }
}
