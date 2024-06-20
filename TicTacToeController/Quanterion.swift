//
//  Quanterion.swift
//  TicTacToeController
//
//  Created by Mike Sanford (1540) on 5/31/24.
//

import simd

struct Quanterion: Codable, CustomStringConvertible, Sendable {
    let angle: Float
    let axisX: Float
    let axisY: Float
    let axisZ: Float

    init(rotation: simd_quatf) {
        angle = rotation.angle
        axisX = rotation.axis.x
        axisY = rotation.axis.y
        axisZ = rotation.axis.z
    }

    var rotation: simd_quatf {
        .init(angle: angle, axis: .init(x: axisX, y: axisY, z: axisZ))
    }

    public var description: String {
        "(w: \(angle), x: \(axisX), y: \(axisY), z: \(axisZ)"
    }
}
