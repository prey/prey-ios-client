//
//  LogInVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 20/11/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit

class LogInVC: UIViewController {

    // MARK: Properties
    @IBOutlet weak var addDeviceButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    
    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureTextButton()
        
        // Dismiss Keyboard on tap outside
        let recognizer = UITapGestureRecognizer(target: self, action:#selector(LogInVC.dismissKeyboard(_:)))
        view.addGestureRecognizer(recognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Listen for changes to keyboard visibility so that we can adjust the text view accordingly.
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(LogInVC.handleKeyboardWillShowNotification(_:)), name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(LogInVC.handleKeyboardWillHideNotification(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }

    
    // MARK: Configuration
    func configureTextButton() {
        //let buttonTitle = NSLocalizedString("Button", comment: "")
        //systemTextButton.setTitle(buttonTitle, forState: .Normal)
    }
    
    // MARK: Keyboard Event Notifications
    func handleKeyboardWillShowNotification(notification: NSNotification) {
        keyboardWillChangeFrameWithNotification(notification, showsKeyboard: true)
    }
    
    func handleKeyboardWillHideNotification(notification: NSNotification) {
        keyboardWillChangeFrameWithNotification(notification, showsKeyboard: false)
    }

    func dismissKeyboard(tapGesture: UITapGestureRecognizer) {
        // Dismiss keyboard if is inside from UIView
        if (CGRectContainsPoint(self.view.frame, tapGesture.locationInView(self.view))) {
            self.view.endEditing(true);
        }
    }


    // MARK: Convenience
    func keyboardWillChangeFrameWithNotification(notification: NSNotification, showsKeyboard: Bool) {
        let userInfo = notification.userInfo!
        
        let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        // Convert the keyboard frame from screen to view coordinates.
        let keyboardScreenBeginFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        let keyboardViewBeginFrame = view.convertRect(keyboardScreenBeginFrame, fromView: view.window)
        let keyboardViewEndFrame = view.convertRect(keyboardScreenEndFrame, fromView: view.window)
        let originDelta = keyboardViewEndFrame.origin.y - keyboardViewBeginFrame.origin.y
        
        self.view.center.y += originDelta
        
        view.setNeedsUpdateConstraints()
        
        UIView.animateWithDuration(animationDuration, delay: 0, options: .BeginFromCurrentState, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil)
    }

    // MARK: Actions
    @IBAction func addDeviceAction(sender: UIButton) {
        
        // Check password length
        if passwordTextField.text!.characters.count < 6 {
            displayErrorAlert("Password must be at least 6 characters".localized, titleMessage:"We have a situation!".localized)
            passwordTextField.becomeFirstResponder()
            return
        }

        // Check valid email
        if isInvalidEmail(emailTextField.text!, withPattern:emailRegExp) {
            displayErrorAlert("Enter a valid e-mail address".localized, titleMessage:"We have a situation!".localized)
            emailTextField.becomeFirstResponder()
            return
        }
        
        // Show ActivityIndicator
        let actInd              = UIActivityIndicatorView(activityIndicatorStyle:UIActivityIndicatorViewStyle.Gray)
        actInd.center           = self.view.center
        actInd.hidesWhenStopped = true
        self.view.addSubview(actInd)
        actInd.startAnimating()
        
        // LogIn to Panel Prey
        PreyUser.logInToPrey(emailTextField.text!, userPassword: passwordTextField.text!, onCompletion: {(isSuccess: Bool) in

            // LogIn Success
            if isSuccess {
                
                // Add Device to Panel Prey
                PreyDevice.addDeviceWith({(isSuccess: Bool) in
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        
                        // Add Device Success
                        if isSuccess {
                            if let resultController = self.storyboard!.instantiateViewControllerWithIdentifier("deviceSetUpStrbrd") as? DeviceSetUpVC {
                                self.presentViewController(resultController, animated: true, completion: nil)
                            }
                        }
                        else {
                            // Hide ActivityIndicator
                            actInd.stopAnimating()
                        }
                    }
                })
            } else {
                // Hide ActivityIndicator
                dispatch_async(dispatch_get_main_queue()) {
                    actInd.stopAnimating()
                }
            }
        })
    }
}
