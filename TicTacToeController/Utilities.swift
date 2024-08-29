//
//  Utilities.swift
//  TicTacToeController
//
//  Created by Mike Sanford (1540) on 5/14/24.
//

import Foundation
import TicTacToeEngine
import RealityKit
import SwiftUI

public extension GameboardLocationProtocol {
    var entityName: String {
        name.replacingOccurrences(of: "-", with: "_")
    }
}

public extension TimeInterval {
    init(_ duration: Duration) {
        let (seconds, attoseconds) = duration.components
        let attosecondsInSeconds = Double(attoseconds) / Double(1_000_000_000_000_000_000)
        self = TimeInterval(seconds) + TimeInterval(attosecondsInSeconds)
    }
}

public func deg2rad<FloatType: BinaryFloatingPoint>(_ degrees: FloatType) -> FloatType {
    degrees * FloatType.pi / 180
}

// swiftlint:disable identifier_name
public extension SIMD3<Float> {
    init(x: Float) {
        self.init(x: x, y: .zero, z: .zero)
    }

    init(y: Float) {
        self.init(x: .zero, y: y, z: .zero)
    }

    init(z: Float) {
        self.init(x: .zero, y: .zero, z: z)
    }

    init(x: Float, y: Float) {
        self.init(x: x, y: y, z: .zero)
    }
    // swiftlint:enable identifier_name
}

public extension simd_quatf {
    static let zero: simd_quatf = .init(angle: .zero, axis: .zero)
}

#if DEBUG
public enum Screenshot {
    case homeMenu
    case cube4Game
    case grid3Game
}
#endif
