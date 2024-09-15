//
//  Localized+UI.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 9/3/24.
//

import TicTacToeEngine

#if canImport(UIKit)
import UIKit
typealias Application = UIApplication
#elseif canImport(AppKit)
import AppKit
typealias Application = NSApplication
#endif

public extension Localized {
    @MainActor static var isLayoutRightToLeft: Bool {
        Application.shared.userInterfaceLayoutDirection == .rightToLeft
    }
}

public extension Localized {
    // intentionally not localized given this is the name of the app
    static let appName = "Tic-Tac-Spatial"
}
