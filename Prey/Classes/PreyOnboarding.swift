//
//  PreyOnboarding.swift
//  Prey
//
//  Created by Javier Cala Uribe on 20/07/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

protocol PreyOnboardingDelegate {
    func scrollDid(scrollView:UIScrollView)
}


class PreyOnboarding: UIView, UIScrollViewDelegate {
 
    // MARK: Properties

    var delegate    : PreyOnboardingDelegate?
    
    let numberPages :CGFloat = 7
    
    var scrollView = UIScrollView(frame:UIScreen.mainScreen().bounds)



    // MARK: Init
    
    func configScrollView() {
        
        // Config scrollView
        scrollView.backgroundColor  = UIColor.redColor()
        
        scrollView.contentSize      = CGSizeMake(scrollView.frame.width*numberPages ,scrollView.frame.height)
        scrollView.maximumZoomScale = 1.0
        scrollView.minimumZoomScale = 1.0
        scrollView.clipsToBounds    = true
        scrollView.pagingEnabled    = true
        scrollView.delegate         = self
        scrollView.showsHorizontalScrollIndicator = false
        
        self.addSubview(scrollView)
        
        // Config Pages
        for page in 0...6 {
            let pageView = PreyOnboardingPage(frame:CGRectMake(CGFloat(page)*scrollView.frame.width,0,scrollView.frame.width,scrollView.frame.height))
            pageView.tag = page + 300
            
            pageView.backgroundColor = (page % 2 == 0) ? UIColor.redColor() : UIColor.blueColor()
            
            scrollView.addSubview(pageView)
        }        
    }
    
    // MARK: UIScrollViewDelegate
    
    // scrollViewDidScroll
    func scrollViewDidScroll(scrollView: UIScrollView) {

        // send to delegate
        delegate?.scrollDid(scrollView)
    }
}