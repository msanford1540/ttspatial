//
//  GameboardController3D.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 6/24/24.
//

import TicTacToeEngine

@MainActor public final class CubeGameboardController: GameboardController<CubeGameboard> {
    override func addWinningLine(_ line: CubeWinningLine) {
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

private extension CubeWinningLine {
    var type: WinningLineType {
        switch self {
        case .horizontal, .vertical, .depth: .straight
        case .xDiagonal, .yDiagonal, .zDiagonal: .diagonal
        case .crossDiagonal: .crossDiagonal
        }
    }
}
