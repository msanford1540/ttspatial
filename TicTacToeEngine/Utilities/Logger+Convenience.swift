//
//  Logger+Convenience.swift
//  TicTacToeEngine
//
//  Created by Mike Sanford (1540) on 5/31/24.
//

import Foundation
import OSLog

private let subsystem: String = Bundle.main.bundleIdentifier!

public extension Logger {
    init(category: String) {
        self.init(subsystem: subsystem, category: category)
    }
}
