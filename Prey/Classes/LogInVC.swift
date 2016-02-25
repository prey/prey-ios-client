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
        let recognizer = UITapGestureRecognizer(target: self, action:Selector("dismissKeyboard:"))
        view.addGestureRecognizer(recognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Listen for changes to keyboard visibility so that we can adjust the text view accordingly.
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "handleKeyboardWillShowNotification:", name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "handleKeyboardWillHideNotification:", name: UIKeyboardWillHideNotification, object: nil)
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
        print("email:\(emailTextField.text)  password:\(passwordTextField.text)")
        
        /*
        if (countElements(passwordTextField.text) < 6)
        {
            var alert = UIAlertController(title:NSLocalizedString("We have a situation!", comment:""),
                                        message:NSLocalizedString("Password must be at least 6 characters", comment:""),
                                 preferredStyle:UIAlertControllerStyle.Alert)
            
            alert.addAction(UIAlertAction(title:NSLocalizedString("OK", comment:""),
                style:UIAlertActionStyle.Default, handler:nil))
            self.presentViewController(alert, animated:true, completion:nil)
            
            passwordTextField.becomeFirstResponder()
            
            return
        }

        PreyHTTPClient.manager.request(.GET, "http://httpbin.org/get", parameters: ["foo": "bar"])
            .response { (request, response, data, error) in
                print(request)
                print(response)
                print(error)
        }
        */
    }
}


/*
if (![email.text isMatchedByRegex:strEmailMatchstring]){
    UIAlertView *objAlert = [[UIAlertView alloc] initWithTitle:@"Error!" message:NSLocalizedString(@"Enter a valid e-mail address",nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Try Again",nil),nil];
    [objAlert show];
    
    [email becomeFirstResponder];
    return;
}

[self hideKeyboard];

HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
HUD.delegate = self;
HUD.labelText = NSLocalizedString(@"Attaching device...",nil);

[User allocWithEmail:[email text] password:[password text]
withBlock:^(User *user, NSError *error)
{
if (!error) // User Login
{
[Device newDeviceForApiKey:user
withBlock:^(User *user, Device *dev, NSError *error)
{
[MBProgressHUD hideHUDForView:self.navigationController.view animated:NO];

if (!error) // Device created
{
PreyConfig *config = [PreyConfig initWithUser:user andDevice:dev];
if (config != nil)
{
NSString *txtCongrats = NSLocalizedString(@"Congratulations! You have successfully associated this iOS device with your Prey account.",nil);
[(PreyAppDelegate*)[UIApplication sharedApplication].delegate registerForRemoteNotifications];
[self performSelectorOnMainThread:@selector(showCongratsView:) withObject:txtCongrats waitUntilDone:NO];
}
}
}]; // End Block Device
}
else
[MBProgressHUD hideHUDForView:self.navigationController.view animated:NO];
}]; // End Block User

*/
