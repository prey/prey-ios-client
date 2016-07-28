//
//  WelcomeVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 19/11/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit

class WelcomeVC: GAITrackedViewController, PreyOnboardingDelegate {

    
    // MARK: Properties
    
    @IBOutlet weak var bgImage     : UIImageView!
    @IBOutlet weak var pageControl : UIPageControl!

    @IBOutlet weak var nextPageBtn : UIButton!
    @IBOutlet weak var backPageBtn : UIButton!

    @IBOutlet weak var signUpBtn   : UIButton!
    @IBOutlet weak var logInBtn    : UIButton!
    
    let preyOnboarding = PreyOnboarding(frame:UIScreen.mainScreen().bounds)
    
    
    // MARK: Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // View title for GAnalytics
        self.screenName = "Onboarding"
        
        // Config PreyOnboarding
        preyOnboarding.configInit()
        preyOnboarding.delegate = self
        
        // First load
        backPageBtn.alpha = 0
        
        // Config texts
        configureTextButton()
        
        self.view.insertSubview(preyOnboarding, aboveSubview:bgImage)
    }
    
    // Configure texts
    func configureTextButton() {
        signUpBtn.setTitle("SIGN UP".localized, forState:.Normal)
        logInBtn.setTitle("already have an account?".localized, forState:.Normal)
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
    
    // MARK: PreyOnboardingDelegate
    
    func scrollDid(scrollView:UIScrollView) {
        let frame               = UIScreen.mainScreen().applicationFrame
        let roundedValue        = round(scrollView.contentOffset.x / frame.size.width)
        pageControl.currentPage = Int(roundedValue)

        // Config PageBtn
        switch pageControl.currentPage {
        
        case 0:     backPageBtn.alpha = 0
        
        case 1...5: backPageBtn.alpha = 1.0
                    nextPageBtn.alpha = 1.0
        
        case 6:     backPageBtn.alpha = 0
                    nextPageBtn.alpha = 0
        default:    break
        }
    }
    
    
    // MARK: Actions

    // Change page slide
    @IBAction func changePageSlide(sender: UIPageControl) {
        var frameScroll         = preyOnboarding.scrollView.frame
        frameScroll.origin.x    = frameScroll.size.width * CGFloat(pageControl.currentPage)
        preyOnboarding.scrollView.scrollRectToVisible(frameScroll, animated:true)
    }
    
    // Show next page
    @IBAction func showNextPage(sender: UIButton) {
        var scrollViewFrame = preyOnboarding.scrollView.frame
        scrollViewFrame.origin.x = scrollViewFrame.size.width * CGFloat(pageControl.currentPage + 1) // +1 page
        preyOnboarding.scrollView.scrollRectToVisible(scrollViewFrame, animated:true)
    }

    // Show back page
    @IBAction func showBackPage(sender: UIButton) {
        var scrollViewFrame = preyOnboarding.scrollView.frame
        scrollViewFrame.origin.x = scrollViewFrame.size.width * CGFloat(pageControl.currentPage - 1) // -1 page
        preyOnboarding.scrollView.scrollRectToVisible(scrollViewFrame, animated:true)
    }
    
    // Show SignUp view
    @IBAction func showSignUpVC(sender: UIButton) {
        
        // Get SharedApplication delegate
        guard let appWindow = UIApplication.sharedApplication().delegate?.window else {
            PreyLogger("error with sharedApplication")
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
            PreyLogger("error with sharedApplication")
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

