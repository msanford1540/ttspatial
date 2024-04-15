//
//  Entity+Animations.swift
//  TicTacSpatial
//
//  Created by Mike Sanford (1540) on 4/15/24.
//

import Foundation
import RealityKit

extension Entity {
    static let empty: Entity = .init()

    @MainActor func animateScale(to scale: SIMD3<Float>, duration: Duration = .seconds(1)) async {
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

    @MainActor func animateOpacity(to opacity: Float, duration: Duration = .seconds(1)) async {
        let fromOpacity: Float?
        if let opacityComponent = components[OpacityComponent.self] {
            fromOpacity = opacityComponent.opacity
        } else {
            fromOpacity = nil
        }
        let fromToAnimation = FromToByAnimation(
            from: fromOpacity,
            to: opacity,
            duration: TimeInterval(duration),
            bindTarget: .opacity
        )
        if let animation = try? AnimationResource.generate(with: fromToAnimation) {
            playAnimation(animation)
            try? await Task.sleep(for: duration)
        } else {
            components.set(OpacityComponent(opacity: opacity))
        }
    }
}

private extension TimeInterval {
    init(_ duration: Duration) {
        let (seconds, attoseconds) = duration.components
        let attosecondsInSeconds = Double(attoseconds) / Double(1_000_000_000_000_000_000)
        self = TimeInterval(seconds) + TimeInterval(attosecondsInSeconds)
    }
}
