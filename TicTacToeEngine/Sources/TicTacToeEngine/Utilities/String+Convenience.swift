//
//  String+Convenience.swift
//  TicTacToeEngine
//
//  Created by Mike Sanford (1540) on 5/31/24.
//

import Foundation

public extension String {
    static let `nil` = "<nil>"
    static let space = " "
    static let newLine = "\n"

    var nonEmpty: String? {
        isEmpty ? nil : self
    }

    init(pretty: CustomStringConvertible?) {
        self.init(pretty?.description ?? Self.nil)
    }
}
