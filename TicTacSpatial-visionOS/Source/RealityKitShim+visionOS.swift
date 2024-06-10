//
//  Entity+Animations.swift
//  TicTacSpatial
//
//  Created by Mike Sanford (1540) on 4/15/24.
//

import RealityKit
import TicTacToeController

final class RealityKitShimVisionOS: RealityKitShim {
    let minInputOpacity: Float = 0.02

    @MainActor func animate(entity: Entity, toOpacity opacity: Float, duration: Duration) async {
        let fromOpacity: Float?

        if let opacityComponent = entity.components[OpacityComponent.self] {
            fromOpacity = opacityComponent.opacity
        } else {
            fromOpacity = nil
        }

        let fromToAnimation = FromToByAnimation(
            from: fromOpacity,
            to: opacity,
            duration: .init(duration),
            bindTarget: .opacity
        )

        if let animation = try? AnimationResource.generate(with: fromToAnimation) {
            entity.playAnimation(animation)
            try? await Task.sleep(for: duration)
        } else {
            entity.components.set(OpacityComponent(opacity: opacity))
        }
    }
}
