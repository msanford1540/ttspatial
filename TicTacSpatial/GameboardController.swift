//
//  GameboardController.swift
//  TicTacSpatial
//
//  Created by Mike Sanford (1540) on 4/15/24.
//

import RealityKit

@MainActor class GameboardController {
    private(set) var places: Entity = .empty
    private(set) var xTemplateEntity: Entity = .empty
    private(set) var oTemplateEntity: Entity = .empty
    private(set) var lineTemplateEntity: Entity = .empty

    private var xEntities: [GridLocation: Entity] = .empty
    private var oEntities: [GridLocation: Entity] = .empty
    private var lineEntities: [WinningLine: Entity] = .empty
    private var blankEntities: [GridLocation: Entity] = .empty

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

        GridLocation.allCases.forEach { location in
            scene.findEntity(named: location.name).map {
                $0.components.set([
                    OpacityComponent(opacity: 1),
                    HoverEffectComponent(),
                    location
                ])
                blankEntities[location] = $0
            }
        }
    }

    func updateUI(_ event: GameEvent) async throws {
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
    }

    func onMove(_ gameMove: GameMove) async throws {
        let location = gameMove.location
        let mark = gameMove.playerID
        let animationDuration: Duration = .markDuration
        guard let blankEntity = blankEntities[location] else {
            assertionFailure("expected entity")
            return
        }
        let postion = blankEntity.position
        Task {
            await blankEntity.animateOpacity(to: 0, duration: animationDuration / 2)
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
        places.addChild(markedEntity)
        Task {
            await markedEntity.animateOpacity(to: 1, duration: animationDuration)
        }
        switch mark {
        case .x: xEntities[location] = markedEntity
        case .o: oEntities[location] = markedEntity
        }
        try await Task.sleep(for: animationDuration / 2)
    }

    func onReset() async throws {
        var didAnimate = false
        let animationDuration: Duration = .removeDuration
        let entities = Array(xEntities.values) + Array(oEntities.values) + Array(lineEntities.values)
        entities.forEach { entity in
            didAnimate = true
            Task {
                await entity.animateOpacity(to: 0, duration: animationDuration)
                entity.removeFromParent()
            }
        }
        xEntities = .empty
        oEntities = .empty
        lineEntities = .empty
        blankEntities.values.forEach { entity in
            let opacity = entity.components[OpacityComponent.self]?.opacity
            if entity.isEnabled, let opacity, opacity >= (1 - Float.ulpOfOne) {
                return
            }
            didAnimate = true
            entity.isEnabled = true
            Task {
                await entity.animateOpacity(to: 1, duration: animationDuration)
            }
        }
        if didAnimate {
            try await Task.sleep(for: animationDuration)
        }
    }

    func onGameOver(_ winningInfo: WinningInfo?) async throws {
        winningInfo?.lines.forEach { addWinningLine($0) }

        let animationDuration: Duration = .markDuration
        var didAnimate = false
        blankEntities.values.forEach { entity in
            guard entity.isEnabled else { return }
            didAnimate = true
            Task {
                await entity.animateOpacity(to: 0, duration: animationDuration)
                entity.isEnabled = false
            }
        }

        if didAnimate {
            try await Task.sleep(for: animationDuration)
        }
    }

    private func addWinningLine(_ line: WinningLine) {
        let rowOffset: Float = 0.30
        guard lineEntities[line] == nil else {
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
        let newLine = lineTemplateEntity.clone(recursive: true)
        newLine.isEnabled = true
        newLine.position = position
        newLine.transform.scale = .init(x: 1, y: 1, z: 0)
        newLine.transform.setRotationAngles(xRotationDegrees, 90, 0)
        lineEntities[line] = newLine
        places.parent?.addChild(newLine)
        Task {
            await newLine.animateScale(to: .init(x: 1, y: 1, z: scale), duration: .drawLineDuration)
        }
    }

    private func templateEntity(for marker: PlayerMarker) -> Entity {
        switch marker {
        case .x: xTemplateEntity
        case .o: oTemplateEntity
        }
    }
}

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

private extension Duration {
    static let removeDuration: Duration = .milliseconds(250)
    static let markDuration: Duration = .milliseconds(250)
    static let drawLineDuration: Duration = .milliseconds(500)
}
