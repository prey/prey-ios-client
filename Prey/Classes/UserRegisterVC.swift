//
//  UserRegisterVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 16/06/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

class UserRegister: UIViewController, UITextFieldDelegate {

    
    // MARK: Properties
    
    @IBOutlet weak var subtitleView     : UILabel!
    @IBOutlet weak var titleView        : UILabel!
    @IBOutlet weak var changeViewBtn    : UIButton!
    @IBOutlet weak var addDeviceButton  : UIButton!
    @IBOutlet weak var nameTextField    : UITextField!
    @IBOutlet weak var emailTextField   : UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    // MARK: Init
    
    // Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Dismiss Keyboard on tap outside
        let recognizer = UITapGestureRecognizer(target: self, action:#selector(self.dismissKeyboard(_:)))
        view.addGestureRecognizer(recognizer)
        
        // Config delegate UITextField
        for view in self.view.subviews {
            if view.isKindOfClass(UITextField) {
                (view as! UITextField).delegate = self
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigationBar when appear this ViewController
        self.navigationController?.navigationBarHidden = true
        
        // Listen for changes to keyboard visibility so that we can adjust the text view accordingly.
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(UserRegister.handleKeyboardWillShowNotification(_:)), name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(UserRegister.handleKeyboardWillHideNotification(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Show navigationBar when disappear this ViewController
        self.navigationController?.navigationBarHidden = false
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
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
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        let nextTage=textField.tag+1;
        // Try to find next responder
        let nextResponder=textField.superview?.viewWithTag(nextTage) as UIResponder!
        
        if (nextResponder != nil){
            nextResponder?.becomeFirstResponder()
        } else {
            addDeviceAction(nil)
        }
        return false // We do not want UITextField to insert line-breaks.
    }
    
    // Add device action
    @IBAction func addDeviceAction(sender: UIButton?) {}

}