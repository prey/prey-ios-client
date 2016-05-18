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
            self.removeAtIndex(index)
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
                (subview as! UISlider).value = AVAudioSession.sharedInstance().outputVolume
                return slider
            }
        }
        return slider
    }
}