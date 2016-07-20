//
//  WelcomeVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 19/11/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit

class WelcomeVC: UIViewController{

    
    // MARK: Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool){
        // Hide navigationBar when appear this ViewController
        self.navigationController?.navigationBarHidden = true

        super.viewWillAppear(animated)
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
    
    // Show SignIn view
    @IBAction func showSignInVC(sender: UIButton) {
        
        // Get SharedApplication delegate
        guard let appWindow = UIApplication.sharedApplication().delegate?.window else {
            print("error with sharedApplication")
            return
        }
        
        // Get SignInVC from Storyboard
        if let controller:UIViewController = self.storyboard!.instantiateViewControllerWithIdentifier(StoryboardIdVC.signIn.rawValue) {
            
            // Set controller to rootViewController
            let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController
            
            let transition:CATransition = CATransition()
            transition.type = kCATransitionFade
            navigationController.view.layer.addAnimation(transition, forKey: "")
            
            navigationController.setViewControllers([controller], animated: false)
        }
    }
}

