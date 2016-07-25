//
//  PreyOnboardingPage.swift
//  Prey
//
//  Created by Javier Cala Uribe on 20/07/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

// Tags for feature images
enum tagFeatureImage: Int {
    case snapshot = 1100
}

class PreyOnboardingPage: UIView {

    
    // MARK: Properties

    var messageLbl = UILabel()
    
    
    // MARK: Config view

    // Config images for pages
    func configImagesForPage(numberPage:Int) {

        let imageView = UIImageView()
        
        switch numberPage {

            // Page 0
        case 0: imageView.image = UIImage(named:"OnAshley1")
        imageView.frame = IS_IPAD ? CGRectMake(260,300,340,406) : CGRectMake(130,130,170,203)

            // Page 1
        case 1: imageView.image = UIImage(named:"OnDude")
        imageView.frame = IS_IPAD ? CGRectMake(260,275,340,402) : CGRectMake(130,120,170,201)

            // Page 2
        case 2: imageView.image = UIImage(named:"OnAshley2")
        imageView.frame = IS_IPAD ? CGRectMake(220,185,340,492) : CGRectMake(110,80,170,246)

            // Page 3
        case 3: imageView.image = UIImage(named:"OnDude2")
        imageView.frame = IS_IPAD ? CGRectMake(80,362,340,316)  : CGRectMake(40,160,170,158)

            // Page 4
        case 4: imageView.image = UIImage(named:"OnPolice1")
        imageView.frame = IS_IPAD ? CGRectMake(494,430,260,252) : CGRectMake(180,190,130,126)
        animateImageForPage4()
            
            // Page 5
        case 5: imageView.image = UIImage(named:"OnAshley4")
        imageView.frame = IS_IPAD ? CGRectMake(240,239,300,438) : CGRectMake(120,98,150,219)

            // Page 6
        case 6: imageView.image = UIImage(named:"OnAshley5")
        imageView.frame = IS_IPAD ? CGRectMake(200,277,400,400) : CGRectMake(100,118,200,200)
            
            
        default: break
        }
        
        addSubview(imageView)
    }
    
    // Animate images for Page 3
    func animateImageForPage3() {
        
        // Return if feature images exist
        guard viewWithTag(tagFeatureImage.snapshot.rawValue) == nil else {
            return
        }
        
        // Define scale to transform feature images
        let initScaleImg:CGAffineTransform = CGAffineTransformMakeScale(0.01,0.01)
        let endScaleImg :CGAffineTransform = CGAffineTransformMakeScale(1.0,1.0)
        
        // Feature: Snapshot
        let featSnap            = UIImageView(image:UIImage(named:"OnFeatSnapshot"))
        featSnap.frame          = IS_IPAD ? CGRectMake(260,120,200,214) : CGRectMake(130,80,100,107)
        featSnap.transform      = initScaleImg
        featSnap.tag            = tagFeatureImage.snapshot.rawValue
        addSubview(featSnap)
        animateFeatureImagesForPage3(featSnap, withDelay:0, toScale:endScaleImg)

        // Feature: Geo
        let featGeo             = UIImageView(image:UIImage(named:"OnFeatGeo"))
        featGeo.frame           = IS_IPAD ? CGRectMake(440,240,200,226) : CGRectMake(220,140,100,113)
        featGeo.transform       = initScaleImg
        addSubview(featGeo)
        animateFeatureImagesForPage3(featGeo, withDelay:1.0, toScale:endScaleImg)
        
        // Feature: Report
        let featReport          = UIImageView(image:UIImage(named:"OnFeatReport"))
        featReport.frame        = IS_IPAD ? CGRectMake(420,460,200,226) : CGRectMake(210,250,100,113)
        featReport.transform    = initScaleImg
        addSubview(featReport)
        animateFeatureImagesForPage3(featReport, withDelay:2.0, toScale:endScaleImg)
    }
    
    // Animate features images for Page 3
    func animateFeatureImagesForPage3(image:UIImageView, withDelay:NSTimeInterval, toScale:CGAffineTransform) {
        UIView.animateWithDuration(1.0, delay:withDelay, options:.BeginFromCurrentState , animations:{() in
            image.transform = toScale
            }, completion:nil)
    }
    
    // Animate images for Page 4
    func animateImageForPage4() {
        
        // Police 2
        let police2Img      = UIImageView(image:UIImage(named:"OnPolice2"))
        police2Img.frame    = IS_IPAD ? CGRectMake(440,320,300,304) : CGRectMake(180,140,150,152)
        addSubview(police2Img)
        
        // Ashley
        let ashleyImg       = UIImageView(image:UIImage(named:"OnAshley3"))
        ashleyImg.frame     = IS_IPAD ? CGRectMake(40,283,260,394) : CGRectMake(20,120,130,197)
        addSubview(ashleyImg)
    }
    
    // Config message for pages
    func configMessageForPage(numberPage:Int) {
        
        let tagPage = 500 + numberPage
        
        switch numberPage {
            
        case 0: addMessage("Ashley uses Prey on all her devices: her Macbook, her iPhone and iPad. But one day, she was at the wrong place at the wrong time and someone stole her tablet.".localized, withTag:tagPage)
            
        case 1: addMessage("Meet Steve, he steals objects left unattended.".localized, withTag:tagPage)
            
        case 2: addMessage("Losing a device means losing precious data, memories, information and some really expensive equipment.".localized, withTag:tagPage)
            
        case 3: addMessage("Without him knowing it, Prey is silently capturing pictures, location, and sending the legitimate owner complete reports.\nAshley can also use Prey to remotely lock her device down and wipe her sensitive data.".localized, withTag:tagPage)
            
        case 4: addMessage("Good thing Ashley has PREY activated! She just got the reports from her stolen device, so now the police has accurate evidence to work with.".localized, withTag:tagPage)
            
        case 5: addMessage("With the detailed reports on the missing device, Ashley had more worries, she got her device back.".localized, withTag:tagPage)
            
        case 6: addMessage("Don\'t wait for the worst to happen to take action. Sign up, enter your registration details and set up Prey on your phone.".localized, withTag:tagPage)
            
        default: break
        }
    }
    
    // Add message
    func addMessage(message:String, withTag:Int) {

        let screenSize              = UIScreen.mainScreen().bounds
        let messagePosY:CGFloat     = IS_IPAD ? 0.675 : 0.63
        let fontSize:CGFloat        = IS_IPAD ? 24 : 14
        let rectLbl                 = CGRectMake(screenSize.size.width*0.05, screenSize.size.height*messagePosY,
                                                 screenSize.size.width*0.9, screenSize.size.height*0.2)        
        messageLbl.frame            = rectLbl
        messageLbl.font             = UIFont(name:fontTitilliumRegular, size:fontSize)
        messageLbl.textAlignment    = .Center
        messageLbl.numberOfLines    = 6
        messageLbl.textColor        = UIColor(red:235.0/255.0, green:235.0/255.0, blue:235.0/255.0, alpha:1.0)
        messageLbl.backgroundColor  = .clearColor()
        messageLbl.alpha            = 1.0
        messageLbl.text             = message
        messageLbl.tag              = withTag
        
        addSubview(messageLbl)
    }
}
