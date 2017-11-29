//
//  PreyOnboarding.swift
//  Prey
//
//  Created by Javier Cala Uribe on 20/07/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit


// Tags for Background images
enum tagBgImage: Int {
    case restaurant = 200, dudeRoom, policeStation, girlRoom, street
}

protocol PreyOnboardingDelegate {
    func scrollDid(_ scrollView:UIScrollView)
}


class PreyOnboarding: UIView, UIScrollViewDelegate {
 
    // MARK: Properties

    var delegate    : PreyOnboardingDelegate?
    
    let numberPages :CGFloat = 7
    
    var scrollView = UIScrollView(frame:UIScreen.main.bounds)



    // MARK: Init
    
    func configInit() {
        
        // Config scrollView
        scrollView.contentSize      = CGSize(width: scrollView.frame.width*numberPages ,height: scrollView.frame.height)
        scrollView.maximumZoomScale = 1.0
        scrollView.minimumZoomScale = 1.0
        scrollView.clipsToBounds    = true
        scrollView.isPagingEnabled    = true
        scrollView.delegate         = self
        scrollView.showsHorizontalScrollIndicator = false
        
        addSubview(scrollView)
        
        // Config Pages
        for page in 0...6 {
            let pageView = PreyOnboardingPage(frame:CGRect(x: CGFloat(page)*scrollView.frame.width,y: 0,width: scrollView.frame.width,height: scrollView.frame.height))
            pageView.tag = page + 300
            pageView.configMessageForPage(page)
            pageView.configImagesForPage(page)
            scrollView.addSubview(pageView)
        }
        
        // Add background images
        addBackgroundImage(UIImage(named:"OnBgRestaurant")!, withTag:tagBgImage.restaurant.rawValue)
        addBackgroundImage(UIImage(named:"OnBgRoom")!, withTag:tagBgImage.dudeRoom.rawValue)
        addBackgroundImage(UIImage(named:"OnBgPolice")!, withTag:tagBgImage.policeStation.rawValue)
        addBackgroundImage(UIImage(named:"OnBgRoomGirl")!, withTag:tagBgImage.girlRoom.rawValue)
        addBackgroundImage(UIImage(named:"OnBgStreet")!, withTag:tagBgImage.street.rawValue)
    }
    
    
    // Add background images
    func addBackgroundImage(_ bgImg:UIImage, withTag:Int) {
        
        let fxiPhoneX:CGFloat   = IS_IPHONEX ? 1.20 : 1
        let fxiPhone4S:CGFloat  = IS_IPHONE4S ? 0.215 : 0.27
        let ratioBgImg          = CGFloat(167.0 / 320.0) // :: height / width from bgImages
        let heightScreen        = UIScreen.main.bounds.size.height
        let widthScreen         = UIScreen.main.bounds.size.width
        let bgFrame             = CGRect(x: 0,y: heightScreen*fxiPhone4S*fxiPhoneX, width: widthScreen, height: widthScreen*ratioBgImg)
        
        let bgImageView         = UIImageView(image:bgImg)
        bgImageView.frame       = bgFrame
        bgImageView.tag         = withTag
        bgImageView.alpha       = (withTag == tagBgImage.restaurant.rawValue) ? 1.0 : 0.0
        
        insertSubview(bgImageView, belowSubview:scrollView)
    }
    
    // MARK: Animations
    
    // Animate background image
    func animateBackgroundImage(_ currentBg:Int, nextBg:Int, indexRatio:CGFloat) {
        
        let currentBg:UIView    = self.viewWithTag(currentBg)!
        let nextBg:UIView       = self.viewWithTag(nextBg)!
        
        let ratioScreen         = CGFloat(frame.size.width * indexRatio)
        
        currentBg.alpha         = 1 - ((scrollView.contentOffset.x - ratioScreen)/frame.size.width)
        nextBg.alpha            = ((scrollView.contentOffset.x - ratioScreen)/frame.size.width)
    }
    
    
    // MARK: UIScrollViewDelegate
    
    // scrollViewDidScroll
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let frame               = UIScreen.main.applicationFrame
        let roundedValue        = round(scrollView.contentOffset.x / frame.size.width)
        let currentPage         = Int(roundedValue)
        
        if (2...3 ~= currentPage) {
            animateBackgroundImage(tagBgImage.restaurant.rawValue, nextBg:tagBgImage.dudeRoom.rawValue, indexRatio:2)
        }
        if (3...4 ~= currentPage) {
            animateBackgroundImage(tagBgImage.dudeRoom.rawValue, nextBg:tagBgImage.policeStation.rawValue, indexRatio:3)
        }
        if (4...5 ~= currentPage) {
            animateBackgroundImage(tagBgImage.policeStation.rawValue, nextBg:tagBgImage.girlRoom.rawValue, indexRatio:4)
        }
        if (5...6 ~= currentPage) {
            animateBackgroundImage(tagBgImage.girlRoom.rawValue, nextBg:tagBgImage.street.rawValue, indexRatio:5)
        }
        
        if (scrollView.contentOffset.x == 3*frame.size.width) {
            let pageView: PreyOnboardingPage = viewWithTag(303) as! PreyOnboardingPage
            pageView.animateImageForPage3()
        }
        
        
        // send to delegate
        delegate?.scrollDid(scrollView)
    }
}
