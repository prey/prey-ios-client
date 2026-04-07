//
//  HomeVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 27/11/14.
//  Copyright (c) 2014 Prey, Inc. All rights reserved.
//

import UIKit

class HomeVC: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {
    // MARK: Properties

    @IBOutlet var titleLbl: UILabel!
    @IBOutlet var subtitleLbl: UILabel!
    @IBOutlet var shieldImg: UIImageView!
    @IBOutlet var camouflageImg: UIImageView!
    @IBOutlet var passwordInput: UITextField!
    @IBOutlet var loginBtn: UIButton!
    @IBOutlet var forgotBtn: UIButton!

    @IBOutlet var accountImg: UIImageView!
    @IBOutlet var accountSbtLbl: UILabel!
    @IBOutlet var accountTlLbl: UILabel!
    @IBOutlet var accountBtn: UIButton!
    @IBOutlet var settingsImg: UIImageView!
    @IBOutlet var settingsSbtLbl: UILabel!
    @IBOutlet var settingsTlLbl: UILabel!
    @IBOutlet var settingsBtn: UIButton!

    var hidePasswordInput = false

    // MARK: Init

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        // View title for GAnalytics
        // self.screenName = "Login"

        // Dismiss Keyboard on tap outside
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
        view.addGestureRecognizer(recognizer)

        // Config init
        hidePasswordInputOption(hidePasswordInput)

        // Config texts
        configureTexts()
    }

    func configureTexts() {
        loginBtn.setTitle("Log In".localized, for: .normal)
        forgotBtn.setTitle("Forgot your password?".localized, for: .normal)

        passwordInput.placeholder = "Type in your password".localized
        subtitleLbl.text = "current device status".localized
        accountTlLbl.text = "PREY ACCOUNT".localized
        accountSbtLbl.text = "REMOTE CONTROL FROM YOUR".localized
        settingsTlLbl.text = "PREY SETTINGS".localized
        settingsSbtLbl.text = "CONFIGURE".localized
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Hide navigationBar when appear this ViewController
        navigationController?.isNavigationBarHidden = true

        // Listen for changes to keyboard visibility so that we can adjust the text view accordingly.
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(HomeVC.handleKeyboardWillShowNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(HomeVC.handleKeyboardWillHideNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Hide navigationBar when appear this ViewController
        navigationController?.isNavigationBarHidden = false

        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    /// Hide password input
    func hidePasswordInputOption(_ value: Bool) {
        // Input subview
        changeHiddenFor(view: passwordInput, value: value)
        changeHiddenFor(view: loginBtn, value: value)
        changeHiddenFor(view: forgotBtn, value: value)

        // Menu subview
        changeHiddenFor(view: accountImg, value: !value)
        changeHiddenFor(view: accountSbtLbl, value: !value)
        changeHiddenFor(view: accountTlLbl, value: !value)
        changeHiddenFor(view: accountBtn, value: !value)
        changeHiddenFor(view: settingsImg, value: !value)
        changeHiddenFor(view: settingsSbtLbl, value: !value)
        changeHiddenFor(view: settingsTlLbl, value: !value)
        changeHiddenFor(view: settingsBtn, value: !value)
    }

    /// Set hidden object
    func changeHiddenFor(view: UIView!, value: Bool) {
        if view != nil {
            view.isHidden = value
        }
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
        if view.frame.contains(tapGesture.location(in: view)) {
            view.endEditing(true)
        }
    }

    func keyboardWillChangeFrameWithNotification(_ notification: Notification, showsKeyboard _: Bool) {
        let userInfo = (notification as NSNotification).userInfo!

        let animationDuration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue

        // Convert the keyboard frame from screen to view coordinates.
        let keyboardScreenBeginFrame = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue

        let keyboardViewBeginFrame = view.convert(keyboardScreenBeginFrame, from: view.window)
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        let originDelta = keyboardViewEndFrame.origin.y - keyboardViewBeginFrame.origin.y

        view.center.y += originDelta

        view.setNeedsUpdateConstraints()

        UIView.animate(withDuration: animationDuration, delay: 0, options: .beginFromCurrentState, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTage = textField.tag + 1

        // Try to find next responder
        let nextResponder = textField.superview?.viewWithTag(nextTage)

        if nextResponder == nil {
            checkPassword(nil)
        }
        return false
    }

    // MARK: Functions

    /// Send GAnalytics event
    func sendEventGAnalytics() {
//        if let tracker = GAI.sharedInstance().defaultTracker {
//
//            let dimensionValue = PreyConfig.sharedInstance.isPro ? "Pro" : "Free"
//            tracker.set(GAIFields.customDimension(for: 1), value:dimensionValue)
//
//            let params:NSObject = GAIDictionaryBuilder.createEvent(withCategory: "UserActivity", action:"Log In", label:"Log In", value:nil).build()
//            tracker.send(params as! [NSObject : AnyObject])
//        }
    }

    /// Go to Settings
    @IBAction func goToSettings(_: UIButton) {
        if let resultController = storyboard!.instantiateViewController(withIdentifier: StoryboardIdVC.settings.rawValue) as? SettingsVC {
            navigationController?.pushViewController(resultController, animated: true)
        }
    }

    /// Go to Control Panel
    @IBAction func goToControlPanel(_: UIButton) {
        if let token = PreyConfig.sharedInstance.tokenPanel {
            let params = String(format: "token=%@", token)
            let controller: UIViewController

            if #available(iOS 10.0, *) {
                controller = WebKitVC(withURL: URL(string: URLSessionPanel)!, withParameters: params, withTitle: "Control Panel Web")
            } else {
                controller = WebVC(withURL: URL(string: URLSessionPanel)!, withParameters: params, withTitle: "Control Panel Web")
            }
            if #available(iOS 13, *) { controller.modalPresentationStyle = .fullScreen }
            present(controller, animated: true, completion: nil)
        } else {
            displayErrorAlert("Error, retry later.".localized,
                              titleMessage: "We have a situation!".localized)
        }
    }

    /// Run web forgot
    @IBAction func runWebForgot(_: UIButton) {
        let controller: UIViewController
        if #available(iOS 10.0, *) {
            controller = WebKitVC(withURL: URL(string: URLForgotPanel)!, withParameters: nil, withTitle: "Forgot Password Web")
        } else {
            controller = WebVC(withURL: URL(string: URLForgotPanel)!, withParameters: nil, withTitle: "Forgot Password Web")
        }
        if #available(iOS 13, *) { controller.modalPresentationStyle = .fullScreen }
        present(controller, animated: true, completion: nil)
    }

    /// Check password
    @IBAction func checkPassword(_: UIButton?) {
        // Check password length
        guard let pwdInput = passwordInput.text else {
            displayErrorAlert("Password must be at least 6 characters".localized,
                              titleMessage: "We have a situation!".localized)
            return
        }
        if pwdInput.count < 6 {
            displayErrorAlert("Password must be at least 6 characters".localized,
                              titleMessage: "We have a situation!".localized)
            return
        }

        // Hide keyboard
        view.endEditing(true)

        // Show ActivityIndicator
        let actInd = UIActivityIndicatorView(initInView: view, withText: "Please wait".localized)
        view.addSubview(actInd)
        actInd.startAnimating()

        // Check userApiKey length
        guard let userApiKey = PreyConfig.sharedInstance.userApiKey else {
            displayErrorAlert("Wrong password. Try again.".localized,
                              titleMessage: "We have a situation!".localized)
            return
        }

        // Get Token for Control Panel
        PreyUser.getTokenFromPanel(userApiKey, userPassword: pwdInput, onCompletion: { (isSuccess: Bool) in
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
