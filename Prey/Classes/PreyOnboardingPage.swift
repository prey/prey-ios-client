//
//  PreyOnboardingPage.swift
//  Prey
//
//  Created by Javier Cala Uribe on 20/07/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import UIKit

class PreyOnboardingPage: UIView {

    
    // MARK: Properties

    var messageLbl = UILabel()
    
    
    // MARK: Config view
    
    // Add message
    func addMessage(message:String, withTag:Int) {
        
        FIXME() // adjust posY screens
        
        let screenSize              = UIScreen.mainScreen().bounds
        
        let fontSize:CGFloat        = IS_IPAD ? 24 : 14
        let rectLbl                 = CGRectMake(screenSize.size.width*0.05, screenSize.size.height*0.67,
                                                 screenSize.size.width*0.9, screenSize.size.height*0.20)
        
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
