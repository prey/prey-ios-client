//
//  String+Misc.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public extension String {
    func unquote() -> String {
        var scalars = unicodeScalars
        if scalars.first == "\"" && scalars.last == "\"" && scalars.count >= 2 {
            scalars.removeFirst()
            scalars.removeLast()
            return String(scalars)
        }
        return self
    }
}

public extension UnicodeScalar {
    func asWhitespace() -> UInt8? {
        if value >= 9, value <= 13 {
            return UInt8(value)
        }
        if value == 32 {
            return UInt8(value)
        }
        return nil
    }
}
