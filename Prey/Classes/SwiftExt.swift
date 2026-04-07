//
//  SwiftExt.swift
//  Prey
//
//  Created by Javier Cala Uribe on 2/05/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import Foundation
import MediaPlayer

/// Extension for NSLocalizedString
extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}

/// Extension for UIActivityIndicatorView
extension UIActivityIndicatorView {
    convenience init(initInView view: UIView, withText text: String) {
        // Config ActivityIndicator
        self.init(style: .medium)
        hidesWhenStopped = true
        transform = CGAffineTransform(scaleX: 2, y: 2)
        center = CGPoint(x: view.center.x, y: view.center.y - frame.width)

        // Set background
        let centerX = frame.width * 3 / 4
        let bgRect = CGRect(x: -centerX, y: -frame.width / 2, width: frame.width * 2, height: frame.width * 2)
        let bgView = UIView(frame: bgRect)
        bgView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        bgView.clipsToBounds = true
        bgView.layer.cornerRadius = 10
        insertSubview(bgView, at: 0)

        // Set Message
        let msgRect = CGRect(x: -centerX, y: frame.width / 2, width: frame.width * 2, height: frame.width / 2)
        let messageLbl = UILabel(frame: msgRect)
        messageLbl.text = text
        messageLbl.textColor = UIColor.white
        messageLbl.font = UIFont(name: "Helvetica-Bold", size: 7)
        messageLbl.textAlignment = .center
        insertSubview(messageLbl, at: 1)
    }
}

extension String {
    func boolValue() -> Bool {
        return NSString(string: self).boolValue
    }
}
