//
//  SignUpVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 20/11/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit

class SignUpVC: UIViewController {

    // MARK: Properties
    @IBOutlet weak var addDeviceButton: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    @IBAction func addDeviceAction(sender: UIButton) {
        
        PreyUser.signUpToPrey(nameTextField.text!, userEmail:emailTextField.text!, userPassword:passwordTextField.text!, onCompletion: {(isSuccess: Bool?) in
            print("Done: signUp")
        })
   
    }
}
