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
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}

// Extension for Alarm action
extension MPVolumeView {
    var volumeSlider:UISlider {
        self.showsRouteButton = false
        self.showsVolumeSlider = false
        self.isHidden = true
        var slider = UISlider()
        for subview in self.subviews {
            if subview.isKind(of: UISlider.self){
                slider = subview as! UISlider
                slider.isContinuous = false
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
        self.init(style:.white)
        self.hidesWhenStopped       = true
        self.transform              = CGAffineTransform(scaleX: 2, y: 2)
        self.center                 = CGPoint(x: view.center.x, y: view.center.y - self.frame.width)
        
        // Set background
        let centerX                 = self.frame.width*3/4
        let bgRect                  = CGRect(x: -centerX, y: -self.frame.width/2, width: self.frame.width*2, height: self.frame.width*2)
        let bgView                  = UIView(frame:bgRect)
        bgView.backgroundColor      = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        bgView.clipsToBounds        = true
        bgView.layer.cornerRadius   = 10
        self.insertSubview(bgView, at: 0)

        // Set Message
        let msgRect                 = CGRect(x: -centerX, y: self.frame.width/2, width: self.frame.width*2, height: self.frame.width/2)
        let messageLbl              = UILabel(frame: msgRect)
        messageLbl.text             = text
        messageLbl.textColor        = UIColor.white
        messageLbl.font             = UIFont(name: "Helvetica-Bold", size: 7)
        messageLbl.textAlignment    = .center
        self.insertSubview(messageLbl, at: 1)
    }
}

// Extension for Send Report Data
extension NSMutableData {
    
    /// Append string to NSMutableData
    ///
    /// Rather than littering my code with calls to `dataUsingEncoding` to convert strings to NSData, and then add that data to the NSMutableData, this wraps it in a nice convenient little extension to NSMutableData. This converts using UTF-8.
    ///
    /// - parameter string:       The string to be added to the `NSMutableData`.
    
    func appendString(_ string: String) {
        if let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true) {
            append(data)
        }
    }
}
