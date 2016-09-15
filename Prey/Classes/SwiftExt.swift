//
//  SwiftExt.swift
//  Prey
//
//  Created by Javier Cala Uribe on 2/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation
import MediaPlayer

// Extension for NSLocalizedString
extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: "")
    }
}

// Extension for PreyModule
extension Array where Element : Equatable {
    // Remove first collection element that is equal to the given `object`:
    mutating func removeObject(object : Generator.Element) {
        if let index = self.indexOf(object) {
            if (0...self.count-1 ~= index) {
                self.removeAtIndex(index)
            }
        }
    }
}

// Extension for Alarm action
extension MPVolumeView {
    var volumeSlider:UISlider {
        self.showsRouteButton = false
        self.showsVolumeSlider = false
        self.hidden = true
        var slider = UISlider()
        for subview in self.subviews {
            if subview.isKindOfClass(UISlider){
                slider = subview as! UISlider
                slider.continuous = false
                slider.value = AVAudioSession.sharedInstance().outputVolume
                return slider
            }
        }
        return slider
    }
}

// Extension for UIActivityIndicatorView
extension UIActivityIndicatorView {
    
    convenience init(initInView view: UIView, withText text:String) {
        
        // Config ActivityIndicator
        self.init(activityIndicatorStyle:.White)
        self.hidesWhenStopped       = true
        self.transform              = CGAffineTransformMakeScale(2, 2)
        self.center                 = CGPointMake(view.center.x, view.center.y - self.frame.width)
        
        // Set background
        let centerX                 = self.frame.width*3/4
        let bgRect                  = CGRectMake(-centerX, -self.frame.width/2, self.frame.width*2, self.frame.width*2)
        let bgView                  = UIView(frame:bgRect)
        bgView.backgroundColor      = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.3)
        bgView.clipsToBounds        = true
        bgView.layer.cornerRadius   = 10
        self.insertSubview(bgView, atIndex: 0)

        // Set Message
        let msgRect                 = CGRectMake(-centerX, self.frame.width/2, self.frame.width*2, self.frame.width/2)
        let messageLbl              = UILabel(frame: msgRect)
        messageLbl.text             = text
        messageLbl.textColor        = UIColor.whiteColor()
        messageLbl.font             = UIFont(name: "Helvetica-Bold", size: 7)
        messageLbl.textAlignment    = .Center
        self.insertSubview(messageLbl, atIndex: 1)
    }
}

// Extension for Send Report Data
extension NSMutableData {
    
    /// Append string to NSMutableData
    ///
    /// Rather than littering my code with calls to `dataUsingEncoding` to convert strings to NSData, and then add that data to the NSMutableData, this wraps it in a nice convenient little extension to NSMutableData. This converts using UTF-8.
    ///
    /// - parameter string:       The string to be added to the `NSMutableData`.
    
    func appendString(string: String) {
        if let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) {
            appendData(data)
        }
    }
}