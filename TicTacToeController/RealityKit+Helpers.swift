//
//  RealityKit+Helpers.swift
//  TicTacToeController
//
//  Created by Mike Sanford (1540) on 5/31/24.
//

import RealityKit

public extension Entity {
    static let empty: Entity = .init()

    @MainActor func animateScale(to scale: SIMD3<Float>, duration: Duration) async {
        var transform = self.transform
        transform.scale = scale
        if let animation = try? AnimationResource.generate(
            with: FromToByAnimation(to: transform, duration: TimeInterval(duration), bindTarget: .transform)
        ) {
            playAnimation(animation)
            try? await Task.sleep(for: duration)
        } else {
            self.transform = transform
        }
    }
}

public extension Transform {
    mutating func setRotationAngles(_ xDegrees: Float, _ yDegrees: Float, _ zDegrees: Float) {
        let xRotation = simd_quatf(angle: deg2rad(xDegrees), axis: .init(x: 1, y: 0, z: 0))
        let yRotation = simd_quatf(angle: deg2rad(yDegrees), axis: .init(x: 0, y: 1, z: 0))
        let zRotation = simd_quatf(angle: deg2rad(zDegrees), axis: .init(x: 0, y: 0, z: 1))
        self.rotation = zRotation * yRotation * xRotation
    }
}
