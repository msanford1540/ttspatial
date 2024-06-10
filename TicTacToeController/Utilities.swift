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

public extension simd_quatf {
    init(translation: CGSize) {
        // Calculate rotation angle
        let hypot = hypot(translation.width, translation.height)
        let rotation = Angle(degrees: hypot)
        // Calculate rotation axis
        let axisX = Float(translation.height / hypot)
        let axisY = Float(translation.width / hypot)
        let rotationAxis = SIMD3<Float>(x: axisX, y: axisY, z: .zero)
        self.init(angle: Float(rotation.radians), axis: rotationAxis)
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
