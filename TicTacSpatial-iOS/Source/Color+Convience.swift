//
//  Color+Convience.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 7/3/24.
//

import UIKit
import SwiftUI

extension UIColor {
    static func panel(for colorScheme: ColorScheme) -> UIColor {
        switch colorScheme {
        case .light: .init(white: 0.875, alpha: 1)
        case .dark: .init(white: 0.125, alpha: 1)
        @unknown default: .init(white: 0.875, alpha: 1)
        }
    }
}

extension Color {
    static func panel(for colorScheme: ColorScheme) -> Color {
        .init(uiColor: .panel(for: colorScheme))
    }
}
