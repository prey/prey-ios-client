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
    func configImagesForPage(_ numberPage:Int) {

        let posY, posX , imageWidth, imageHeight  : CGFloat
        let imageView   = UIImageView()
        let frame       = UIScreen.main.applicationFrame
        
        switch numberPage {
            
        case 0: // Page 0
        imageView.image = UIImage(named:"OnAshley1")
        posY            = frame.size.height*0.23
        posX            = frame.size.width*0.30
        imageWidth      = frame.size.width*0.5125
        imageHeight     = frame.size.height*0.3574
        imageView.frame = IS_IPAD ? CGRect(x: 260,y: 300,width: 340,height: 406) : CGRect(x: posX,y: posY,width: imageWidth,height: imageHeight)
            
        case 1: // Page 1
        imageView.image = UIImage(named:"OnDude")
        posY            = frame.size.height*0.208
        posX            = frame.size.width*0.30
        imageWidth      = frame.size.width*0.5125
        imageHeight     = frame.size.height*0.3574
        imageView.frame = IS_IPAD ? CGRect(x: 260,y: 275,width: 340,height: 402) : CGRect(x: posX,y: posY,width: imageWidth,height: imageHeight)
            
        case 2: // Page 2
        imageView.image = UIImage(named:"OnAshley2")
        posY            = frame.size.height*0.130
        posX            = frame.size.width*0.30
        imageWidth      = frame.size.width*0.5125
        imageHeight     = frame.size.height*0.4330
        imageView.frame = IS_IPAD ? CGRect(x: 220,y: 185,width: 340,height: 492) : CGRect(x: posX,y: posY,width: imageWidth,height: imageHeight)
            
        case 3: // Page 3
        imageView.image = UIImage(named:"OnDude2")
        posY            = frame.size.height*0.285
        posX            = frame.size.width*0.065
        imageWidth      = frame.size.width*0.5125
        imageHeight     = frame.size.height*0.2781
        imageView.frame = IS_IPAD ? CGRect(x: 80,y: 362,width: 340,height: 316)  : CGRect(x: posX,y: posY,width: imageWidth,height: imageHeight)
            
        case 4: // Page 4
        imageView.image = UIImage(named:"OnPolice1")
        posY            = frame.size.height*0.3445
        posX            = frame.size.width*0.5625
        imageWidth      = frame.size.width*0.40625
        imageHeight     = frame.size.height*0.2218
        imageView.frame = IS_IPAD ? CGRect(x: 494,y: 430,width: 260,height: 252) : CGRect(x: posX,y: posY,width: imageWidth,height: imageHeight)
        animateImageForPage4()
            
        case 5: // Page 5
        imageView.image = UIImage(named:"OnAshley4")
        posY            = frame.size.height*0.180
        posX            = frame.size.width*0.275
        imageWidth      = frame.size.width*0.4687
        imageHeight     = frame.size.height*0.3855
        imageView.frame = IS_IPAD ? CGRect(x: 240,y: 239,width: 300,height: 438) : CGRect(x: posX,y: posY,width: imageWidth,height: imageHeight)
            
        case 6: // Page 6
        imageView.image = UIImage(named:"OnAshley5")
        posY            = frame.size.height*0.212
        posX            = frame.size.width*0.210
        imageWidth      = frame.size.width*0.625
        imageHeight     = frame.size.height*0.3521
        imageView.frame = IS_IPAD ? CGRect(x: 200,y: 277,width: 400,height: 400) : CGRect(x: posX,y: posY,width: imageWidth,height: imageHeight)
            
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
        let initScaleImg:CGAffineTransform = CGAffineTransform(scaleX: 0.01,y: 0.01)
        let endScaleImg :CGAffineTransform = CGAffineTransform(scaleX: 1.0,y: 1.0)
        
        let posYiPhone4S:CGFloat           = IS_IPHONE4S ? 45 : 0
        
        // Feature: Snapshot
        let featSnap            = UIImageView(image:UIImage(named:"OnFeatSnapshot"))
        featSnap.frame          = IS_IPAD ? CGRect(x: 260,y: 120,width: 200,height: 214) : CGRect(x: 130,y: 80-posYiPhone4S,width: 100,height: 107)
        featSnap.transform      = initScaleImg
        featSnap.tag            = tagFeatureImage.snapshot.rawValue
        addSubview(featSnap)
        animateFeatureImagesForPage3(featSnap, withDelay:0, toScale:endScaleImg)

        // Feature: Geo
        let featGeo             = UIImageView(image:UIImage(named:"OnFeatGeo"))
        featGeo.frame           = IS_IPAD ? CGRect(x: 440,y: 240,width: 200,height: 226) : CGRect(x: 220,y: 140-posYiPhone4S,width: 100,height: 113)
        featGeo.transform       = initScaleImg
        addSubview(featGeo)
        animateFeatureImagesForPage3(featGeo, withDelay:1.0, toScale:endScaleImg)
        
        // Feature: Report
        let featReport          = UIImageView(image:UIImage(named:"OnFeatReport"))
        featReport.frame        = IS_IPAD ? CGRect(x: 420,y: 460,width: 200,height: 226) : CGRect(x: 210,y: 250-posYiPhone4S,width: 100,height: 113)
        featReport.transform    = initScaleImg
        addSubview(featReport)
        animateFeatureImagesForPage3(featReport, withDelay:2.0, toScale:endScaleImg)
    }
    
    // Animate features images for Page 3
    func animateFeatureImagesForPage3(_ image:UIImageView, withDelay:TimeInterval, toScale:CGAffineTransform) {
        UIView.animate(withDuration: 1.0, delay:withDelay, options:.beginFromCurrentState , animations:{() in
            image.transform = toScale
            }, completion:nil)
    }
    
    // Animate images for Page 4
    func animateImageForPage4() {
        
        var posY, posX , imageWidth, imageHeight  : CGFloat
        
        // Police 2
        let police2Img      = UIImageView(image:UIImage(named:"OnPolice2"))
        posY                = frame.size.height*0.2595
        posX                = frame.size.width*0.4725
        imageWidth          = frame.size.width*0.4687
        imageHeight         = frame.size.height*0.2676
        police2Img.frame    = IS_IPAD ? CGRect(x: 440,y: 320,width: 300,height: 304) : CGRect(x: posX,y: posY,width: imageWidth,height: imageHeight) //CGRectMake(180,140,150,152)
        addSubview(police2Img)
        
        // Ashley
        let ashleyImg       = UIImageView(image:UIImage(named:"OnAshley3"))
        posY                = frame.size.height*0.217445
        posX                = frame.size.width*0.0610625
        imageWidth          = frame.size.width*0.4062
        imageHeight         = frame.size.height*0.3468
        ashleyImg.frame     = IS_IPAD ? CGRect(x: 40,y: 283,width: 260,height: 394) : CGRect(x: posX,y: posY,width: imageWidth,height: imageHeight) //CGRectMake(20,120,130,197)
        addSubview(ashleyImg)
    }
    
    // Config message for pages
    func configMessageForPage(_ numberPage:Int) {
        
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
    func addMessage(_ message:String, withTag:Int) {

        let screenSize              = UIScreen.main.bounds
        let messagePosY:CGFloat     = IS_IPAD ? 0.675 : 0.63
        let fontSize:CGFloat        = IS_IPAD ? 24 : 14
        let rectLbl                 = CGRect(x: screenSize.size.width*0.05, y: screenSize.size.height*messagePosY,
                                                 width: screenSize.size.width*0.9, height: screenSize.size.height*0.2)        
        messageLbl.frame            = rectLbl
        messageLbl.font             = UIFont(name:fontTitilliumRegular, size:fontSize)
        messageLbl.textAlignment    = .center
        messageLbl.numberOfLines    = 6
        messageLbl.textColor        = UIColor(red:235.0/255.0, green:235.0/255.0, blue:235.0/255.0, alpha:1.0)
        messageLbl.backgroundColor  = .clear
        messageLbl.alpha            = 1.0
        messageLbl.text             = message
        messageLbl.tag              = withTag
        
        addSubview(messageLbl)
    }
}
