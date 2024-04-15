//
//  GameEvents.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 4/10/24.
//

import Foundation

enum PlayerMarker: CustomStringConvertible {
    // swiftlint:disable identifier_name
    case x
    case o
    // swiftlint:enable identifier_name

    var opponent: PlayerMarker {
        switch self {
        case .x: return .o
        case .o: return .x
        }
    }

    var description: String {
        switch self {
        case .x: return "X"
        case .o: return "O"
        }
    }
}

struct GridLocation: Hashable, CustomStringConvertible {
    enum VerticalPosition: CaseIterable, CustomStringConvertible {
        case top, middle, bottom

        var description: String {
            switch self {
            case .top: return "top"
            case .middle: return "middle"
            case .bottom: return "bottom"
            }
        }
    }
    enum HorizontalPosition: CaseIterable, CustomStringConvertible {
        case left, middle, right

        var description: String {
            switch self {
            case .left: return "left"
            case .middle: return "middle"
            case .right: return "right"
            }
        }
    }

    // swiftlint:disable identifier_name
    let x: HorizontalPosition
    let y: VerticalPosition

    init(_ y: VerticalPosition, _ x: HorizontalPosition) {
        self.x = x
        self.y = y
    }
    // swiftlint:enable identifier_name

    var description: String {
        x == .middle && y == .middle ? "\(x)" : "\(y)-\(x)"
    }

    static var allCases: Set<GridLocation> = {
        VerticalPosition.allCases.reduce(into: .init()) { result, vPos in
            HorizontalPosition.allCases.forEach { hPos in
                result.insert(.init(vPos, hPos))
            }
        }
    }()
}

enum WinningLine: Hashable, CustomStringConvertible {
    case horizontal(GridLocation.VerticalPosition)
    case vertical(GridLocation.HorizontalPosition)
    case diagonal(isBackslash: Bool) // forwardslash: "/", backslash: "\"

    static var allCases: Set<WinningLine> = {
        let horizontalLines = GridLocation.VerticalPosition.allCases.map { Self.horizontal($0) }
        let verticalLines = GridLocation.HorizontalPosition.allCases.map { Self.vertical($0) }
        let diagonals = [Self.diagonal(isBackslash: true), .diagonal(isBackslash: false)]
        return Set(horizontalLines + verticalLines + diagonals)
    }()

    public var description: String {
        switch self {
        case .horizontal(let verticalPosition): return "horizontal-\(verticalPosition)"
        case .vertical(let horizontalPosition): return "vertical-\(horizontalPosition)"
        case .diagonal(let isBackslash): return "diagonal-\(isBackslash ? "backslash" : "forwardslash")"
        }
    }
}

struct WinningInfo: Equatable, CustomStringConvertible {
    let player: PlayerMarker
    let lines: Set<WinningLine>

    var description: String {
        "(winner: \(player), lines: \(lines))"
    }
}

enum StartingPlayerOption {
    case player(PlayerID)
    case alternate
}

struct GameConfig: Sendable {
    let meMarker: PlayerMarker
    let startingPlayer: StartingPlayerOption
}

enum PlayerID {
    case player1, player2
}

struct GameMove {
    let location: GridLocation
    let playerID: PlayerMarker
}

enum GameEvent {
    case move(GameMove)
    case undo(GameMove)
    case gameOver(WinningInfo?)
    case reset
}

struct GameStateUpdate: Hashable, Sendable {
    private let id: UUID
    let event: GameEvent
    let currentTurn: PlayerMarker?

    init(event: GameEvent, currentTurn: PlayerMarker?) {
        self.id = UUID()
        self.event = event
        self.currentTurn = currentTurn
    }

    static func == (lhs: GameStateUpdate, rhs: GameStateUpdate) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
