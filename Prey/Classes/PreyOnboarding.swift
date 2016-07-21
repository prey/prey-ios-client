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
    func scrollDid(scrollView:UIScrollView)
}


class PreyOnboarding: UIView, UIScrollViewDelegate {
 
    // MARK: Properties

    var delegate    : PreyOnboardingDelegate?
    
    let numberPages :CGFloat = 7
    
    var scrollView = UIScrollView(frame:UIScreen.mainScreen().bounds)



    // MARK: Init
    
    func configInit() {
        
        // Config scrollView
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
            configMessageForPage(page, withPage:pageView)
            scrollView.addSubview(pageView)
        }
        
        // Add background images
        addBackgroundImage(UIImage(named:"OnBgRestaurant")!, withTag:tagBgImage.restaurant.rawValue)
        addBackgroundImage(UIImage(named:"OnBgRoom")!, withTag:tagBgImage.dudeRoom.rawValue)
        addBackgroundImage(UIImage(named:"OnBgPolice")!, withTag:tagBgImage.policeStation.rawValue)
        addBackgroundImage(UIImage(named:"OnBgRoomGirl")!, withTag:tagBgImage.girlRoom.rawValue)
        addBackgroundImage(UIImage(named:"OnBgStreet")!, withTag:tagBgImage.street.rawValue)
    }
    
    // Config message for pages
    func configMessageForPage(numberPage:Int, withPage page:PreyOnboardingPage) {
        
        switch numberPage {

        case 0: page.addMessage("Ashley uses Prey on all her devices: her Macbook, her iPhone and iPad. But one day, she was at the wrong place at the wrong time and someone stole her tablet.".localized, withTag:500+numberPage)

        case 1: page.addMessage("Meet Steve, he steals objects left unattended.".localized, withTag:500+numberPage)

        case 2: page.addMessage("Losing a device means losing precious data, memories, information and some really expensive equipment.".localized, withTag:500+numberPage)

        case 3: page.addMessage("Without him knowing it, Prey is silently capturing pictures, location, and sending the legitimate owner complete reports.\nAshley can also use Prey to remotely lock her device down and wipe her sensitive data.".localized, withTag:500+numberPage)

        case 4: page.addMessage("Good thing Ashley has PREY activated! She just got the reports from her stolen device, so now the police has accurate evidence to work with.".localized, withTag:500+numberPage)

        case 5: page.addMessage("With the detailed reports on the missing device, Ashley had more worries, she got her device back.".localized, withTag:500+numberPage)

        case 6: page.addMessage("Don\'t wait for the worst to happen to take action. Sign up, enter your registration details and set up Prey on your phone.".localized, withTag:500+numberPage)
            
        default: break
        }
    }
    
    // Add background images
    func addBackgroundImage(bgImg:UIImage, withTag:Int) {
        
        let ratioBgImg      = CGFloat(167.0 / 320.0) // :: height / width from bgImages
        let heightScreen    = UIScreen.mainScreen().bounds.size.height
        let widthScreen     = UIScreen.mainScreen().bounds.size.width
        let bgFrame         = CGRectMake(0,heightScreen*0.27, widthScreen, widthScreen*ratioBgImg)
        
        let bgImageView     = UIImageView(image:bgImg)
        bgImageView.frame   = bgFrame
        bgImageView.tag     = withTag
        bgImageView.alpha   = (withTag == tagBgImage.restaurant.rawValue) ? 1.0 : 0.0
        
        self.insertSubview(bgImageView, atIndex:1)
    }
    
    // MARK: Animations
    
    // Animate background image
    func animateBackgroundImage(currentBg:Int, nextBg:Int, indexRatio:CGFloat) {
        
        let currentBg:UIView    = self.viewWithTag(currentBg)!
        let nextBg:UIView       = self.viewWithTag(nextBg)!
        
        let ratioScreen         = CGFloat(frame.size.width * indexRatio)
        
        currentBg.alpha         = 1 - ((scrollView.contentOffset.x - ratioScreen)/frame.size.width)
        nextBg.alpha            = ((scrollView.contentOffset.x - ratioScreen)/frame.size.width)
    }
    
    
    // MARK: UIScrollViewDelegate
    
    // scrollViewDidScroll
    func scrollViewDidScroll(scrollView: UIScrollView) {

        let frame               = UIScreen.mainScreen().applicationFrame
        let roundedValue        = round(scrollView.contentOffset.x / frame.size.width)
        let currentPage         = Int(roundedValue)
        
        switch currentPage {
        case 2,3: animateBackgroundImage(tagBgImage.restaurant.rawValue, nextBg:tagBgImage.dudeRoom.rawValue, indexRatio:2)
        case 3,4: animateBackgroundImage(tagBgImage.dudeRoom.rawValue, nextBg:tagBgImage.policeStation.rawValue, indexRatio:3)
        case 4,5: animateBackgroundImage(tagBgImage.policeStation.rawValue, nextBg:tagBgImage.girlRoom.rawValue, indexRatio:4)
        case 5,6: animateBackgroundImage(tagBgImage.girlRoom.rawValue, nextBg:tagBgImage.street.rawValue, indexRatio:5)
        default: break
        }
        
        
        
        
        // send to delegate
        delegate?.scrollDid(scrollView)
    }
}