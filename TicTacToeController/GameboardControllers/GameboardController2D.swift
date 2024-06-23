//
//  GameboardController2D.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 6/22/24.
//

import TicTacToeEngine

@MainActor public final class GameboardController2D: GameboardController<GridGameboard> {
    override func addWinningLine(_ line: GridWinningLine) {
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
