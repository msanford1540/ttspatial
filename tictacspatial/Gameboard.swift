//
//  Gameboard.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 4/2/24.
//

import SwiftUI
import RealityKit
import Combine

struct Gameboard: View {
    private class Entities {
        private(set) var places: Entity = .empty
        private(set) var xTemplateEntity: Entity = .empty
        private(set) var oTemplateEntity: Entity = .empty
        private(set) var lineTemplateEntity: Entity = .empty

        func setup(scene: Entity) {
            guard let places = scene.findEntity(named: "places"),
                  let xEntity = scene.findEntity(named: "marker_x"),
                  let oEntity = scene.findEntity(named: "marker_o"),
                  let lineEntity = scene.findEntity(named: "line_horizontal") else {
                fatalError("invalid scene")
            }
            
            self.places = places
            xTemplateEntity = xEntity
            xTemplateEntity.isEnabled = false
            oTemplateEntity = oEntity
            oTemplateEntity.isEnabled = false
            lineTemplateEntity = lineEntity
            lineTemplateEntity.isEnabled = false
        }
    }

    private class GameboardState {
        var xEntities: [GridLocation: Entity] = .empty
        var oEntities: [GridLocation: Entity] = .empty
        var lineEntities: [WinningLine: Entity] = .empty
        var blankEntities: [GridLocation: Entity] = .empty
        var subscribers: Set<AnyCancellable> = .empty
    }

    @ObservedObject private var gameSession: GameSession
    private let entities = Entities()
    private let state = GameboardState()
    private var isProcessingUpdate: Bool = false

    init(gameSession: GameSession) {
        self.gameSession = gameSession
    }

    var body: some View {
        RealityView { content, attachments in
            guard let scene = try? await Entity(named: "Scene", in: .main) else { return }
            content.add(scene)
            entities.setup(scene: scene)
            GridLocation.allCases.forEach { location in
                scene.findEntity(named: location.name).map {
                    $0.components.set([
                        OpacityComponent(opacity: 1),
                        HoverEffectComponent(),
                        location
                    ])
                    state.blankEntities[location] = $0
                }
            }

            if let controlsAttachment = attachments.entity(for: "controls") {
                controlsAttachment.position = [0, -0.55, 0.1]
                scene.addChild(controlsAttachment)
            }
        } update: { _, _  in
            updateNextGameEvent()
        } placeholder: {
            ProgressView()
        } attachments: {
            Attachment(id: "controls") {
                Dashboard(gameSession: gameSession)
            }
        }
        .gesture(TapGesture().targetedToAnyEntity()
            .onEnded { value in
                guard let location = value.entity.components[GridLocation.self] else { return }
                gameSession.mark(at: location)
            }
        )
    }

    private func updateNextGameEvent() {
        Task { @MainActor in
            guard let event = gameSession.dequeueEvent() else { return }
            switch event {
            case .move(let gameMove):
                try await onMove(gameMove)
            case .undo:
                break
            case .gameOver(let winningInfo):
                try await onGameOver(winningInfo)
            case .reset:
                try await onReset()
            }
            gameSession.onCompletedEvent()
        }
    }

    private func onReset() async throws {
        var didAnimate = false
        let animationDuration: Duration = .removeDuration
        (Array(state.xEntities.values) + Array(state.oEntities.values) + Array(state.lineEntities.values)).forEach { entity in
            didAnimate = true
            entity.animateOpacity(to: 0, duration: animationDuration) { entity.removeFromParent() }
        }
        state.xEntities = .empty
        state.oEntities = .empty
        state.lineEntities = .empty
        state.blankEntities.values.forEach {
            if $0.isEnabled, let opacityComponent = $0.components[OpacityComponent.self], opacityComponent.opacity >= (1 - .ulpOfOne) {
                return
            }
            didAnimate = true
            $0.isEnabled = true
            $0.animateOpacity(to: 1, duration: animationDuration)
        }
        if didAnimate {
            try await Task.sleep(for: animationDuration)
        }
    }

    private func onMove(_ gameMove: GameMove) async throws {
        let location = gameMove.location
        let mark = gameMove.playerID
        let animationDuration: Duration = .markDuration
        guard let blankEntity = state.blankEntities[location] else {
            assertionFailure("expected entity")
            return
        }
        let postion = blankEntity.position
        blankEntity.animateOpacity(to: 0, duration: animationDuration / 2) {
            blankEntity.isEnabled = false
        }
        let templateEntity = templateEntity(for: mark)
        let markedEntity = templateEntity.clone(recursive: true)
        markedEntity.position = postion
        markedEntity.isEnabled = true
        markedEntity.components.set([
            HoverEffectComponent(),
            OpacityComponent(opacity: 0)
        ])
        entities.places.addChild(markedEntity)
        markedEntity.animateOpacity(to: 1, duration: animationDuration)
        switch mark {
        case .x: state.xEntities[location] = markedEntity
        case .o: state.oEntities[location] = markedEntity
        }
        try await Task.sleep(for: animationDuration / 2)
    }

    private func onGameOver(_ winningInfo: WinningInfo?) async throws {
        winningInfo?.lines.forEach { addWinningLine($0) }

        let animationDuration: Duration = .markDuration
        var didAnimate = false
        state.blankEntities.values.forEach { entity in
            guard entity.isEnabled else { return }
            didAnimate = true
            entity.animateOpacity(to: 0, duration: animationDuration) {
                entity.isEnabled = false
            }
        }

        if didAnimate {
            try await Task.sleep(for: animationDuration)
        }
    }

    private func addWinningLine(_ line: WinningLine) {
        let rowOffset: Float = 0.30
        guard state.lineEntities[line] == nil else {
            assertionFailure("expected entity")
            return
        }
        let xRotationDegrees: Float
        let scale: Float
        var position: SIMD3<Float> = .init(x: 0, y: 0, z: 0.05)
        switch line {
        case .horizontal(let verticalPosition):
            xRotationDegrees = 0
            scale = 1.15
            switch verticalPosition {
            case .top: position.y = rowOffset
            case .middle: break
            case .bottom: position.y = -rowOffset
            }
        case .vertical(let horizontalPosition):
            xRotationDegrees = 90
            scale = 1.15
            switch horizontalPosition {
            case .left: position.x = -rowOffset
            case .middle: break
            case .right: position.x = rowOffset
            }
        case .diagonal(let isBackslash):
            xRotationDegrees = isBackslash ? 45 : 135
            scale = 1.33
        }
        let newLine = entities.lineTemplateEntity.clone(recursive: true)
        newLine.isEnabled = true
        newLine.position = position
        newLine.transform.scale = .init(x: 1, y: 1, z: 0)
        newLine.transform.setRotationAngles(xRotationDegrees, 90, 0)
        state.lineEntities[line] = newLine
        entities.places.parent?.addChild(newLine)
        newLine.animateScale(to: .init(x: 1, y: 1, z: scale), duration: .drawLineDuration)
    }

    private func templateEntity(for marker: PlayerMarker) -> Entity {
        switch marker {
        case .x: return entities.xTemplateEntity
        case .o: return entities.oTemplateEntity
        }
    }
}

#Preview(windowStyle: .volumetric) {
    Gameboard(gameSession: GameSession())
}

private extension Entity {
    static let empty: Entity = .init()

    var childrenCopy: [Entity] {
        children.reduce(into: []) { result, child in result.append(child) }
    }
}

extension GridLocation: Component {}

private extension GridLocation {
    var name: String {
        x == .middle && y == .middle
            ? x.name
            : "\(y.name)_\(x.name)"
    }
}

private extension GridLocation.HorizontalPosition {
    var name: String {
        switch self {
        case .left: return "left"
        case .middle: return "middle"
        case .right: return "right"
        }
    }
}

private extension GridLocation.VerticalPosition {
    var name: String {
        switch self {
        case .top: return "top"
        case .middle: return "middle"
        case .bottom: return "bottom"
        }
    }
}

private func deg2rad<FloatType: BinaryFloatingPoint>(_ degrees: FloatType) -> FloatType {
    degrees * FloatType.pi / 180
}

private extension Transform {
    mutating func setRotationAngles(_ xDegrees: Float, _ yDegrees: Float, _ zDegrees: Float) {
        let xRotation = simd_quatf(angle: deg2rad(xDegrees), axis: .init(x: 1, y: 0, z: 0))
        let yRotation = simd_quatf(angle: deg2rad(yDegrees), axis: .init(x: 0, y: 1, z: 0))
        let zRotation = simd_quatf(angle: deg2rad(zDegrees), axis: .init(x: 0, y: 0, z: 1))
        self.rotation = zRotation * yRotation * xRotation
    }
}

private extension Entity {
    func animateScale(to scale: SIMD3<Float>, duration: Duration = .seconds(1), completion: (@Sendable () -> Void)? = nil) {
        var transform = self.transform
        transform.scale = scale
        if let animation = try? AnimationResource.generate(
            with: FromToByAnimation(to: transform, duration: TimeInterval(duration), bindTarget: .transform)
        ) {
            playAnimation(animation)
            if let completion {
                Task { @MainActor in
                    try await Task.sleep(for: duration)
                    completion()
                }
            }
        } else {
            self.transform = transform
            completion?()
        }
    }

    func animateOpacity(to opacity: Float, duration: Duration = .seconds(1), completion: (() -> Void)? = nil) {
        let fromOpacity: Float?
        if let opacityComponent = components[OpacityComponent.self] {
            fromOpacity = opacityComponent.opacity
        } else {
            fromOpacity = nil
        }
        if let animation = try? AnimationResource.generate(
            with: FromToByAnimation(from: fromOpacity, to: opacity, duration: TimeInterval(duration), bindTarget: .opacity)
        ) {
            playAnimation(animation)
            if let completion {
                Task { @MainActor in
                    try await Task.sleep(for: duration)
                    completion()
                }
            }
        } else {
            components.set(OpacityComponent(opacity: opacity))
            completion?()
        }
    }
}

private extension Duration {
    static let removeDuration: Duration = .milliseconds(250)
    static let markDuration: Duration = .milliseconds(250)
    static let drawLineDuration: Duration = .milliseconds(500)
}

extension TimeInterval {
    init(_ duration: Duration) {
        let (seconds, attoseconds) = duration.components
        let attosecondsInSeconds = Double(attoseconds) / Double(1_000_000_000_000_000_000)
        self = TimeInterval(seconds) + TimeInterval(attosecondsInSeconds)
    }
}
