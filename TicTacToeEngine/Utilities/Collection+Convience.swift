//
//  Collection+Convience.swift
//  TicTacSpatialCore
//
//  Created by Mike Sanford (1540) on 4/8/24.
//

import Foundation

public extension ExpressibleByArrayLiteral {
    static var empty: Self { [] }
}

public extension ExpressibleByDictionaryLiteral {
    static var empty: Self { [:] }
}

public extension ExpressibleByStringLiteral {
    static var empty: Self { "" }
}

public extension Collection {
    var isNotEmpty: Bool { !isEmpty }
}
