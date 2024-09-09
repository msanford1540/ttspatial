//
//  Localized.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 9/3/24.
//

public enum Localized {}

private class BundleFinder {}
extension Bundle {
    static let module = Bundle(for: BundleFinder.self)
}
