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

    var xEntities: [Gameboard.Location: Entity] = .empty
    var oEntities: [Gameboard.Location: Entity] = .empty
    var lineEntities: [Gameboard.WinningLine: Entity] = .empty
    var blankEntities: [Gameboard.Location: Entity] = .empty

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
            print("[debug]", "location: \(location.entityName)")
            if let entity = scene.findEntity(named: location.entityName) {
                blankEntities[location] = entity
                entity.components.set([
                    OpacityComponent(opacity: 1),
                    HoverEffectComponent(),
                    LocationComponent(location)
                ])
            } else {
                print("[debug]", "bad location: \(location.entityName)")
            }
        }
        print("[debug]", "count: \(blankEntities.count)")
    }

    public func updateUI(_ event: GameEvent<Gameboard.WinningLine, Gameboard.Location>) async throws {
        switch event {
        case .move(let gameMove):
            print("[debug]", "count2: \(blankEntities.count)")
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
            await blankEntity.animateOpacityToMinInput(duration: animationDuration / 2)
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
                await entity.animateOpacityToMinInput(duration: animationDuration)
            }
        }

        if didAnimate {
            try await Task.sleep(for: animationDuration)
        }
    }

    func addWinningLine(_ line: Gameboard.WinningLine) {
        assertionFailure("should never get here")
    }

    private func templateEntity(for marker: PlayerMarker) -> Entity {
        switch marker {
        case .x: xTemplateEntity
        case .o: oTemplateEntity
        }
    }
}

extension Duration {
    static let removeDuration: Duration = .milliseconds(250)
    static let markDuration: Duration = .milliseconds(250)
    static let drawLineDuration: Duration = .milliseconds(500)
}

public struct LocationComponent: Component {
    public let location: any GameboardLocationProtocol

    init(_ location: any GameboardLocationProtocol) {
        self.location = location
    }
}

private let allRowOffset: Float = 0.3
extension HorizontalPosition {
    var rowOffset: Float {
        switch self {
        case .left: -allRowOffset
        case .middle: .zero
        case .right: allRowOffset
        }
    }
}

extension VerticalPosition {
    var rowOffset: Float {
        switch self {
        case .top: allRowOffset
        case .middle: .zero
        case .bottom: -allRowOffset
        }
    }
}

extension DepthPosition {
    var rowOffset: Float {
        switch self {
        case .front: allRowOffset
        case .middle: .zero
        case .back: -allRowOffset
        }
    }
}

enum WinningLineType {
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
