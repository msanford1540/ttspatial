//
//  Utilities.swift
//  TicTacSpatial
//
//  Created by Mike Sanford (1540) on 4/8/24.
//

import Foundation

extension ExpressibleByArrayLiteral {
    static var empty: Self { [] }
}

extension ExpressibleByDictionaryLiteral {
    static var empty: Self { [:] }
}

extension ExpressibleByStringLiteral {
    static var empty: Self { "" }
}

extension Collection {
    var isNotEmpty: Bool { !isEmpty }
}
