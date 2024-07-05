//
//  Color+Convience.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 7/3/24.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
typealias DarwinColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias DarwinColor = NSColor
#endif

extension DarwinColor {
    static func panel(for colorScheme: ColorScheme) -> DarwinColor {
        switch colorScheme {
        case .light: .init(white: 0.875, alpha: 1)
        case .dark: .init(white: 0.125, alpha: 1)
        @unknown default: .init(white: 0.875, alpha: 1)
        }
    }
}

extension Color {
    static func panel(for colorScheme: ColorScheme) -> Color {
#if canImport(UIKit)
        .init(uiColor: .panel(for: colorScheme))
#elseif canImport(AppKit)
        .init(nsColor: .panel(for: colorScheme))
#endif
    }
}
