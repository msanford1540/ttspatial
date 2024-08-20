//
//  GameboardController3D4.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 6/22/24.
//

import TicTacToeEngine

@MainActor public final class Cube4GameboardController: GameboardController<Cube4Gameboard> {
    override func addWinningLine(_ line: Cube4WinningLine) {
        guard lineEntities[line] == nil else {
            assertionFailure("expected entity")
            return
        }
        let rotation: SIMD3<Float>
        var position: SIMD3<Float> = .init()
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
            rotation = .init(y: isBackslash ? 33 : 147)
            position.y = yPos.rowOffset
        case .xDiagonal(let xPos, let isBackslash):
            rotation = .init(x: isBackslash ? 147 : 33)
            position.x = xPos.rowOffset
        case .crossDiagonal(let isFront, let isBackslash):
            rotation = .init(x: isBackslash ? 33 : 147, y: isFront ? 147 : 33, z: -5)
            position.z = .zero
        }
        let newLine = lineTemplateEntity.clone(recursive: true)
        newLine.isEnabled = true
        if !line.type.hasDepth {
            position.z += 0.05
        }
        newLine.position = position
        let scale = line.type.scale
        newLine.transform.scale = .init(x: 1.3, y: 1.3)
        newLine.transform.setRotationAngles(rotation.x, rotation.y, rotation.z)
        lineEntities[line] = newLine
        places.parent?.addChild(newLine)
        Task {
            await newLine.animateScale(to: .init(x: 1.3, y: 1.3, z: scale), duration: .drawLineDuration)
        }
    }
}

private let allRowOffset: Float = 0.3

private extension Horizontal4Position {
    var rowOffset: Float {
        switch self {
        case .left: -allRowOffset * 1.5
        case .middleLeft: -allRowOffset * 0.5
        case .middleRight: allRowOffset * 0.5
        case .right: allRowOffset * 1.5
        }
    }
}

private extension Vertical4Position {
    var rowOffset: Float {
        switch self {
        case .top: allRowOffset * 1.5
        case .middleTop: allRowOffset * 0.5
        case .middleBottom: -allRowOffset * 0.5
        case .bottom: -allRowOffset * 1.5
        }
    }
}

private extension Depth4Position {
    var rowOffset: Float {
        switch self {
        case .front: allRowOffset * 2.25
        case .middleFront: allRowOffset * 0.75
        case .middleBack: -allRowOffset * 0.75
        case .back: -allRowOffset * 2.25
        }
    }
}

private extension Cube4WinningLine {
    var type: WinningLineType {
        switch self {
        case .horizontal, .vertical: .straight(hasDepth: false)
        case .depth: .straight(hasDepth: true)
        case .xDiagonal, .yDiagonal: .diagonal(hasDepth: true)
        case .zDiagonal: .diagonal(hasDepth: false)
        case .crossDiagonal: .crossDiagonal
        }
    }
}
