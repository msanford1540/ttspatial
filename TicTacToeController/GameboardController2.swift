//
//  GameboardController2.swift
//  TicTacToeController
//
//  Created by Mike Sanford (1540) on 5/31/24.
//

import Foundation
import RealityKit
import SwiftUI
import TicTacToeEngine

@MainActor public class GameboardController<Gameboard: GameboardProtocol> {
    public private(set) var scene: Entity = .empty
    fileprivate(set) var places: Entity = .empty
    fileprivate(set) var xTemplateEntity: Entity = .empty
    fileprivate(set) var oTemplateEntity: Entity = .empty
    fileprivate(set) var lineTemplateEntity: Entity = .empty

    fileprivate var xEntities: [Gameboard.Location: Entity] = .empty
    fileprivate var oEntities: [Gameboard.Location: Entity] = .empty
    fileprivate var lineEntities: [Gameboard.WinningLine: Entity] = .empty
    fileprivate var blankEntities: [Gameboard.Location: Entity] = .empty

    public init() {}

    public func setup(scene: Entity) {
        guard let places = scene.findEntity(named: "places"),
              let xEntity = scene.findEntity(named: "marker_x"),
              let oEntity = scene.findEntity(named: "marker_o"),
              let lineEntity = scene.findEntity(named: "line_horizontal") else {
            fatalError("invalid scene")
        }
        self.scene = scene
        self.places = places
        xTemplateEntity = xEntity
        xTemplateEntity.isEnabled = false
        oTemplateEntity = oEntity
        oTemplateEntity.isEnabled = false
        lineTemplateEntity = lineEntity
        lineTemplateEntity.isEnabled = false

        Gameboard.Location.allCases.forEach { location in
#if os(visionOS)
            guard let locationComponent = location as? Component else {
                assertionFailure("expected location conform to Component")
                return
            }
#endif
            scene.findEntity(named: location.entityName).map {
                blankEntities[location] = $0
#if os(visionOS)
                $0.components.set([
                    OpacityComponent(opacity: 1),
                    HoverEffectComponent(),
                    locationComponent
                ])
#endif
            }
        }
    }

    public func updateUI(_ event: GameEvent<Gameboard.WinningLine, Gameboard.Location>) async throws {
        switch event {
        case .move(let gameMove):
            try await onMove(gameMove)
        case .undo:
            break
        case .gameOver(let winningInfo):
            try await onGameOver(winningInfo)
        case .reset:
            try await onReset()
        @unknown default:
            assertionFailure("unknown game event type")
        }
    }

    func onMove(_ gameMove: GameMove<Gameboard.Location>) async throws {
        let location = gameMove.location
        let mark = gameMove.mark
        let animationDuration: Duration = .markDuration
        guard let blankEntity = blankEntities[location] else {
            assertionFailure("expected entity")
            return
        }
        let postion = blankEntity.position
        Task {
            await blankEntity.animateToMinInputOpacity(duration: animationDuration / 2)
        }
        let templateEntity = templateEntity(for: mark)
        let markedEntity = templateEntity.clone(recursive: true)
        markedEntity.position = postion
        markedEntity.isEnabled = true
        places.addChild(markedEntity)
#if os(visionOS)
        markedEntity.components.set(OpacityComponent(opacity: .zero))
        Task {
            await markedEntity.animateOpacity(to: 1, duration: animationDuration)
        }
#endif
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
                await entity.animateOpacity(to: .zero, duration: animationDuration)
                entity.removeFromParent()
            }
        }
        xEntities = .empty
        oEntities = .empty
        lineEntities = .empty
        blankEntities.values.forEach { entity in
            didAnimate = true
            entity.isEnabled = true
            Task {
                await entity.animateOpacity(to: 0.8, duration: animationDuration)
            }
        }
        if didAnimate {
            try await Task.sleep(for: animationDuration)
        }
    }

    func onGameOver(_ winningInfo: WinningInfo<Gameboard.WinningLine>?) async throws {
        winningInfo?.lines.forEach { addWinningLine($0) }

        let animationDuration: Duration = .markDuration
        var didAnimate = false
        blankEntities.values.forEach { entity in
            guard entity.isEnabled else { return }
            didAnimate = true
            Task {
                await entity.animateToMinInputOpacity(duration: animationDuration)
            }
        }

        if didAnimate {
            try await Task.sleep(for: animationDuration)
        }
    }

    fileprivate func addWinningLine(_ line: Gameboard.WinningLine) {
        assertionFailure("should never get here")
    }

    private func templateEntity(for marker: PlayerMarker) -> Entity {
        switch marker {
        case .x: xTemplateEntity
        case .o: oTemplateEntity
        }
    }
}

@MainActor public final class GameboardController2D: GameboardController<GridGameboard> {
    fileprivate override func addWinningLine(_ line: GridWinningLine) {
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
}

@MainActor public final class GameboardController3D: GameboardController<CubeGameboard> {
    fileprivate override func addWinningLine(_ line: CubeWinningLine) {
        guard lineEntities[line] == nil else {
            assertionFailure("expected entity")
            return
        }
        let rotation: SIMD3<Float>
        var position: SIMD3<Float> = .init(x: 0, y: 0, z: 0.05)
        switch line {
        case .horizontal(let yPos, let zPos):
            rotation = .init(y: 90)
            position.y = yPos.rowOffset
            position.z += zPos.rowOffset
        case .vertical(let xPos, let zPos):
            rotation = .init(x: 90)
            position.x = xPos.rowOffset
            position.z += zPos.rowOffset
        case .depth(let xPos, let yPos):
            rotation = .init()
            position.x = xPos.rowOffset
            position.y = yPos.rowOffset
        case .zDiagonal(let zPos, let isBackslash):
            rotation = .init(x: isBackslash ? 45 : 135, y: 90)
            position.z += zPos.rowOffset
        case .yDiagonal(let yPos, let isBackslash):
            rotation = .init(y: isBackslash ? 45 : 135)
            position.y = yPos.rowOffset
        case .xDiagonal(let xPos, let isBackslash):
            rotation = .init(x: isBackslash ? 135 : 45)
            position.x = xPos.rowOffset
        case .crossDiagonal(let isFront, let isBackslash):
            rotation = .init(x: isBackslash ? 45 : 140, y: isFront ? 140 : 45, z: -5)
            position.z = .zero
        }
        let newLine = lineTemplateEntity.clone(recursive: true)
        newLine.isEnabled = true
        newLine.position = position
        newLine.transform.scale = .init(x: 1, y: 1)
        newLine.transform.setRotationAngles(rotation.x, rotation.y, rotation.z)
        lineEntities[line] = newLine
        places.parent?.addChild(newLine)
        Task {
            await newLine.animateScale(to: .init(x: 1, y: 1, z: line.type.scale), duration: .drawLineDuration)
        }
    }
}

private extension Duration {
    static let removeDuration: Duration = .milliseconds(250)
    static let markDuration: Duration = .milliseconds(250)
    static let drawLineDuration: Duration = .milliseconds(500)
}

extension GridLocation: Component {}
extension CubeLocation: Component {}

private let allRowOffset: Float = 0.3
private extension HorizontalPosition {
    var rowOffset: Float {
        switch self {
        case .left: -allRowOffset
        case .middle: .zero
        case .right: allRowOffset
        }
    }
}

private extension VerticalPosition {
    var rowOffset: Float {
        switch self {
        case .top: allRowOffset
        case .middle: .zero
        case .bottom: -allRowOffset
        }
    }
}

private extension DepthPosition {
    var rowOffset: Float {
        switch self {
        case .front: allRowOffset
        case .middle: .zero
        case .back: -allRowOffset
        }
    }
}

private enum WinningLineType {
    case straight
    case diagonal
    case crossDiagonal

    var scale: Float {
        switch self {
        case .straight: 1.15
        case .diagonal: 1.35
        case .crossDiagonal: 1.65
        }
    }
}

private extension CubeWinningLine {
    var type: WinningLineType {
        switch self {
        case .horizontal, .vertical, .depth: .straight
        case .xDiagonal, .yDiagonal, .zDiagonal: .diagonal
        case .crossDiagonal: .crossDiagonal
        }
    }
}
