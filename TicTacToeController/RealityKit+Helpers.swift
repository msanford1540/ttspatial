//
//  RealityKit+Helpers.swift
//  TicTacToeController
//
//  Created by Mike Sanford (1540) on 5/31/24.
//

import RealityKit

private let defaultDuration: Duration = .seconds(1)
private let minInputOpacity: Float = 0.02

public extension Entity {
    static let empty: Entity = .init()
    fileprivate static let manager = AnimationManager()

    var opacity: Float {
        get {
            components[OpacityComponent.self]?.opacity ?? 1
        }
        set {
            components[OpacityComponent.self] = OpacityComponent(opacity: newValue)
        }
    }

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

    var isOpacityAnimating: Bool {
        Self.manager.isOpacityAnimationPlaying(for: self)
    }

    @MainActor func animateOpacity(to opacity: Float, duration: Duration? = nil) async {
        if let opacityComponent = components[OpacityComponent.self], opacityComponent.opacity == opacity {
            return
        }
        if isOpacityAnimating {
            return
        }

        let animationDuration = duration ?? defaultDuration
        let fromToAnimation = FromToByAnimation(
            from: components[OpacityComponent.self]?.opacity,
            to: opacity,
            duration: .init(animationDuration),
            bindTarget: .opacity
        )

        if let animation = try? AnimationResource.generate(with: fromToAnimation) {
            let controller = playAnimation(animation)
            Self.manager.addOpacityAnimation(controller)
            try? await Task.sleep(for: animationDuration)
        } else {
            components.set(OpacityComponent(opacity: opacity))
        }
    }

    @MainActor func animateOpacityToMinInput(duration: Duration? = nil) async {
        await animateOpacity(to: minInputOpacity, duration: duration)
    }

    var isRotationAnimating: Bool {
        Self.manager.isRotationAnimationPlaying(for: self)
    }

    func animateRotation(to rotation: simd_quatf = .init(), duration: Duration? = nil) async {
        let animationDuration = duration ?? defaultDuration
        var newTransform = transform
        newTransform.rotation = rotation
        let fromToAnimation = FromToByAnimation(
            to: newTransform,
            duration: .init(animationDuration),
            bindTarget: .transform
        )
        if let animation = try? AnimationResource.generate(with: fromToAnimation) {
            let controller = playAnimation(animation)
            Self.manager.addRotationAnimation(controller)
            try? await Task.sleep(for: animationDuration)
        } else {
            transform.rotation = rotation
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

@MainActor
private final class AnimationManager {
    private final class ValueHolder {
        weak var value: AnimationPlaybackController?

        init(_ value: AnimationPlaybackController) {
            self.value = value
        }
    }

    private var opacityAnimations: [ValueHolder] = .empty
    private var rotationAnimations: [ValueHolder] = .empty

    func isOpacityAnimationPlaying(for entity: Entity) -> Bool {
        opacityAnimations.contains { $0.value?.entity === entity }
    }

    func addOpacityAnimation(_ animationController: AnimationPlaybackController) {
        drain()
        opacityAnimations.append(.init(animationController))
    }

    func isRotationAnimationPlaying(for entity: Entity) -> Bool {
        rotationAnimations.contains { $0.value?.entity === entity }
    }

    func addRotationAnimation(_ animationController: AnimationPlaybackController) {
        drain()
        rotationAnimations.append(.init(animationController))
    }

    private func drain() {
        opacityAnimations = opacityAnimations.filter { $0.value != nil }
    }
}
