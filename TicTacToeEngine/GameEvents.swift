//
//  GameEvents.swift
//  TicTacSpatialCore
//
//  Created by Mike Sanford (1540) on 4/10/24.
//

import Foundation

@frozen
public enum PlayerMarker: Codable, CustomStringConvertible {
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

    public var description: String {
        switch self {
        case .x: return "X"
        case .o: return "O"
        }
    }
}

public struct GridLocation: Hashable, Sendable, Codable, CustomStringConvertible {
    @frozen public enum VerticalPosition: Sendable, Codable, CaseIterable, CustomStringConvertible {
        case top, middle, bottom

        public var description: String {
            switch self {
            case .top: return "top"
            case .middle: return "middle"
            case .bottom: return "bottom"
            }
        }
    }

    @frozen public enum HorizontalPosition: Sendable, Codable, CaseIterable, CustomStringConvertible {
        case left, middle, right

        public var description: String {
            switch self {
            case .left: return "left"
            case .middle: return "middle"
            case .right: return "right"
            }
        }
    }

    // swiftlint:disable identifier_name
    public let x: HorizontalPosition
    public let y: VerticalPosition

    init(_ y: VerticalPosition, _ x: HorizontalPosition) {
        self.x = x
        self.y = y
    }
    // swiftlint:enable identifier_name

    public var description: String {
        x == .middle && y == .middle ? "\(x)" : "\(y)-\(x)"
    }

    public static var allCases: Set<GridLocation> = {
        VerticalPosition.allCases.reduce(into: .init()) { result, vPos in
            HorizontalPosition.allCases.forEach { hPos in
                result.insert(.init(vPos, hPos))
            }
        }
    }()
}

@frozen
public enum WinningLine: Hashable, Sendable, Codable, CustomStringConvertible {
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

public struct WinningInfo: Equatable, Sendable, Codable, CustomStringConvertible {
    public let player: PlayerMarker
    public let lines: Set<WinningLine>

    public var description: String {
        "(winner: \(player), lines: \(lines))"
    }
}

public struct GameMove: Sendable, Codable {
    public let location: GridLocation
    public let mark: PlayerMarker
}

public enum GameEvent: Sendable, Codable {
    case move(GameMove)
    case undo(GameMove)
    case gameOver(WinningInfo?)
    case reset
}

public struct GameStateUpdate: Hashable, Sendable, Codable {
    public let id: UUID
    public let event: GameEvent
    public let currentTurn: PlayerMarker?

    init(event: GameEvent, currentTurn: PlayerMarker?) {
        self.id = UUID()
        self.event = event
        self.currentTurn = currentTurn
    }

    public static func == (lhs: GameStateUpdate, rhs: GameStateUpdate) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public extension GridLocation {
    var name: String {
        x == .middle && y == .middle
            ? x.name
            : "\(y.name)_\(x.name)"
    }
}

public extension GridLocation.HorizontalPosition {
    var name: String {
        switch self {
        case .left: return "left"
        case .middle: return "middle"
        case .right: return "right"
        }
    }
}

public extension GridLocation.VerticalPosition {
    var name: String {
        switch self {
        case .top: return "top"
        case .middle: return "middle"
        case .bottom: return "bottom"
        }
    }
}
