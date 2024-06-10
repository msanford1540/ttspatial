//
//  RealityKitShim+iOS.swift
//  TicTacSpatial-iOS
//
//  Created by Mike Sanford (1540) on 6/1/24.
//

import RealityKit
import TicTacToeController

final class RealityKitShimiOS: RealityKitShim {
    fileprivate(set) var animations: [Animation] = .empty
    private var animationTimer: Timer?

    @MainActor func onDisplayUpdate(_ now: TimeInterval) {
        animations.forEach {
            $0.onUpdate(now)
        }
        animations = animations
            .filter { !$0.isComplete }
        if animations.isEmpty {
            stopAnimationTimer()
        }
    }

    @MainActor private func startAnimationTimer() {
        guard animationTimer == nil else { return }
        animationTimer = .scheduledTimer(withTimeInterval: (1.0/60.0), repeats: true) { _ in
            Task { @MainActor in
                self.onDisplayUpdate(Date.now.timeIntervalSinceReferenceDate)
            }
        }
    }

    @MainActor private func stopAnimationTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    let minInputOpacity: Float = .zero

    @MainActor func animate(entity: Entity, toOpacity targetOpacity: Float, duration: Duration) async {
        let currentOpacity = entity.opacity
        guard (currentOpacity - targetOpacity).magnitude >= .ulpOfOne else { return }
        let animation: Animation
        if targetOpacity > currentOpacity {
            animation = FadeInAnimation(entity: entity, duration: .init(duration), targetOpacity: targetOpacity)
        } else {
            animation = FadeOutAnimation(entity: entity, duration: .init(duration), targetOpacity: targetOpacity)
        }
        animations.append(animation)
        startAnimationTimer()
        try? await Task.sleep(for: duration)
    }
}

private extension Entity {
    var opacity: Float {
        get {
            guard let modelComponent = components[ModelComponent.self] as? ModelComponent,
                  let material = modelComponent.materials.first as? SimpleMaterial else {
                return .zero
            }
            let color =  material.color.tint
            var alpha: CGFloat = .zero
            color.getRed(nil, green: nil, blue: nil, alpha: &alpha)
            return Float(alpha)
        }
        set {
            guard let modelComponent = components[ModelComponent.self] as? ModelComponent,
                  let material = modelComponent.materials.first as? SimpleMaterial else {
                return
            }
            components[ModelComponent.self] = ModelComponent(
                mesh: modelComponent.mesh,
                materials: [SimpleMaterial(color: .gray.withAlphaComponent(CGFloat(newValue)), isMetallic: false)]
            )
            let safeValue = max(0, min(1, newValue))
            let color = material.color.tint.withAlphaComponent(CGFloat(safeValue))
            components[ModelComponent.self] = ModelComponent(
                mesh: modelComponent.mesh,
                materials: [SimpleMaterial(color: color, isMetallic: false)]
            )
        }
    }
}

@MainActor
class Animation {
    fileprivate(set) weak var entity: Entity?
    fileprivate let duration: TimeInterval
    fileprivate let startTimestamp: TimeInterval
    fileprivate(set) var isComplete: Bool

    init(entity: Entity, duration: TimeInterval) {
        self.entity = entity
        self.duration = duration
        self.startTimestamp = Date.now.timeIntervalSinceReferenceDate
        self.isComplete = duration > .zero
    }

    func onUpdate(_ delta: TimeInterval) {
        fatalError()
    }
}

class OpacityAnimation: Animation {
    let sourceOpacity: Float
    let targetOpacity: Float
    let opacityDelta: Float

    init(entity: Entity, duration: TimeInterval, targetOpacity: Float) {
        self.targetOpacity = targetOpacity
        let currentOpacity = entity.opacity
        self.opacityDelta = (currentOpacity - targetOpacity).magnitude
        sourceOpacity = currentOpacity
        super.init(entity: entity, duration: duration)
        updateIsComplete(currentOpacity)
    }

    override func onUpdate(_ now: TimeInterval) {
        guard let entity, !isComplete else { return }
        let deltaDuration = now - startTimestamp
        let progress = deltaDuration / duration
        let opacity = opacityDelta * Float(progress)
        let newOpacity = onUpdate(progressOpacity: opacity)

        entity.opacity = newOpacity
        updateIsComplete(newOpacity)
    }

    private func updateIsComplete(_ newOpacity: Float) {
        isComplete = (newOpacity - targetOpacity).magnitude <= .ulpOfOne
    }

    func onUpdate(progressOpacity: Float) -> Float {
        fatalError()
    }
}

final class FadeOutAnimation: OpacityAnimation {
    override func onUpdate(progressOpacity: Float) -> Float {
        max(targetOpacity, sourceOpacity - progressOpacity)
    }
}

final class FadeInAnimation: OpacityAnimation {
    override func onUpdate(progressOpacity: Float) -> Float {
        min(targetOpacity, sourceOpacity + progressOpacity)
    }
}
