//
//  StringExt.swift
//  Prey
//
//  Created by Javier Cala Uribe on 2/05/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

import Foundation

// Extension for NSLocalizedString
extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: "")
    }
}
