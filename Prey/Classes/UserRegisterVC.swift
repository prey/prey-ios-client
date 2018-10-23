//
//  UserRegisterVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 16/06/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

class UserRegister: GAITrackedViewController, UITextFieldDelegate {

    
    // MARK: Properties
    
    @IBOutlet var subtitleView     : UILabel!
    @IBOutlet var titleView        : UILabel!
    @IBOutlet var changeViewBtn    : UIButton!
    @IBOutlet var addDeviceButton  : UIButton!
    @IBOutlet var nameTextField    : UITextField!
    @IBOutlet var emailTextField   : UITextField!
    @IBOutlet var passwordTextField: UITextField!
    
    
    // MARK: Init
    
    // Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Dismiss Keyboard on tap outside
        let recognizer = UITapGestureRecognizer(target: self, action:#selector(self.dismissKeyboard(_:)))
        view.addGestureRecognizer(recognizer)
        
        // Config delegate UITextField
        for view in self.view.subviews {
            if view is UITextField {
                (view as! UITextField).delegate = self
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigationBar when appear this ViewController
        self.navigationController?.isNavigationBarHidden = true
        
        // Listen for changes to keyboard visibility so that we can adjust the text view accordingly.
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(UserRegister.handleKeyboardWillShowNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(UserRegister.handleKeyboardWillHideNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    // MARK: Keyboard Event Notifications
    
    @objc func handleKeyboardWillShowNotification(_ notification: Notification) {
        keyboardWillChangeFrameWithNotification(notification, showsKeyboard: true)
    }
    
    @objc func handleKeyboardWillHideNotification(_ notification: Notification) {
        keyboardWillChangeFrameWithNotification(notification, showsKeyboard: false)
    }
    
    @objc func dismissKeyboard(_ tapGesture: UITapGestureRecognizer) {
        // Dismiss keyboard if is inside from UIView
        if (self.view.frame.contains(tapGesture.location(in: self.view))) {
            self.view.endEditing(true);
        }
    }
    
    func keyboardWillChangeFrameWithNotification(_ notification: Notification, showsKeyboard: Bool) {
        let userInfo = (notification as NSNotification).userInfo!
        
        let animationDuration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        // Convert the keyboard frame from screen to view coordinates.
        let keyboardScreenBeginFrame = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
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
        
        let nextTage=textField.tag+1;
        // Try to find next responder
        if let nextResponder = textField.superview?.viewWithTag(nextTage) as UIResponder? {
            nextResponder.becomeFirstResponder()
        } else {
            addDeviceAction(nil)
        }
        return false // We do not want UITextField to insert line-breaks.
    }
    
    // Add device action
    @IBAction func addDeviceAction(_ sender: UIButton?) {}

    // Display error alert
    func displayErrorAlert(_ alertMessage: String, titleMessage:String, returnToTextField:UITextField) {
        
        if #available(iOS 8.0, *) {
            
            let alert = UIAlertController(title:titleMessage, message:alertMessage, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title:"OK".localized, style: UIAlertAction.Style.default, handler: nil))
            
            // Get SharedApplication delegate
            guard let appWindow = UIApplication.shared.delegate?.window else {
                PreyLogger("error with sharedApplication")
                return
            }
            // Set controller to rootViewController
            let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController
            navigationController.present(alert, animated: true, completion: { returnToTextField.becomeFirstResponder() })
            
        } else {
            let alert       = UIAlertView()
            alert.title     = titleMessage
            alert.message   = alertMessage
            alert.addButton(withTitle: "OK".localized)
            alert.show()
        }
    }
}
