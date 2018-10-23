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
    
    @IBOutlet var bgImage     : UIImageView!
    @IBOutlet var pageControl : UIPageControl!

    @IBOutlet var nextPageBtn : UIButton!
    @IBOutlet var backPageBtn : UIButton!

    @IBOutlet var signUpBtn   : UIButton!
    @IBOutlet var logInBtn    : UIButton!
    
    let preyOnboarding = PreyOnboarding(frame:UIScreen.main.bounds)
    
    
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
        signUpBtn.setTitle("SIGN UP".localized, for:.normal)
        logInBtn.setTitle("already have an account?".localized, for:.normal)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool){
        // Hide navigationBar when appear this ViewController
        self.navigationController?.isNavigationBarHidden = true

        super.viewWillAppear(animated)
    }
    
    // MARK: PreyOnboardingDelegate
    
    func scrollDid(_ scrollView:UIScrollView) {
        let frame               = UIScreen.main.applicationFrame
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
    @IBAction func changePageSlide(_ sender: UIPageControl) {
        var frameScroll         = preyOnboarding.scrollView.frame
        frameScroll.origin.x    = frameScroll.size.width * CGFloat(pageControl.currentPage)
        preyOnboarding.scrollView.scrollRectToVisible(frameScroll, animated:true)
    }
    
    // Show next page
    @IBAction func showNextPage(_ sender: UIButton) {
        var scrollViewFrame = preyOnboarding.scrollView.frame
        scrollViewFrame.origin.x = scrollViewFrame.size.width * CGFloat(pageControl.currentPage + 1) // +1 page
        preyOnboarding.scrollView.scrollRectToVisible(scrollViewFrame, animated:true)
    }

    // Show back page
    @IBAction func showBackPage(_ sender: UIButton) {
        var scrollViewFrame = preyOnboarding.scrollView.frame
        scrollViewFrame.origin.x = scrollViewFrame.size.width * CGFloat(pageControl.currentPage - 1) // -1 page
        preyOnboarding.scrollView.scrollRectToVisible(scrollViewFrame, animated:true)
    }
    
    // Show SignUp view
    @IBAction func showSignUpVC(_ sender: UIButton) {
        
        // Get SharedApplication delegate
        guard let appWindow = UIApplication.shared.delegate?.window else {
            PreyLogger("error with sharedApplication")
            return
        }
        
        // Get SignUpVC from Storyboard
        let controller:UIViewController = self.storyboard!.instantiateViewController(withIdentifier: StoryboardIdVC.signUp.rawValue)
        // Set controller to rootViewController
        let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController
        
        let transition:CATransition = CATransition()
        transition.type = CATransitionType.fade
        navigationController.view.layer.add(transition, forKey: "")
        
        navigationController.setViewControllers([controller], animated: false)
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
}

