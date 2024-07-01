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

    public var opponent: PlayerMarker {
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

public struct WinningInfo<WinningLine: WinningLineProtocol>: Equatable, Sendable, Codable, CustomStringConvertible {
    public let player: PlayerMarker
    public let lines: Set<WinningLine>

    public var description: String {
        "(winner: \(player), lines: \(lines))"
    }
}

public enum GameMessageType<Snapshot: GameboardSnapshotProtocol>: Codable, Sendable, CustomStringConvertible {
    case snapshot(Snapshot)
    case move(GameMove<Snapshot.Location>)
}

public extension GameMessageType {
    var description: String {
        switch self {
        case .snapshot(let gameSnapshot): "(snapshot: \(gameSnapshot))"
        case .move(let gameMove): "(move: \(gameMove)"
        }
    }
}

public struct GameMessage<Snapshot: GameboardSnapshotProtocol>: Sendable, Codable {
    let id: UUID
    let type: GameMessageType<Snapshot>
}

public struct GameMove<GameboardLocation: GameboardLocationProtocol>: Sendable, Codable {
    public let location: GameboardLocation
    public let mark: PlayerMarker

    public init(location: GameboardLocation, mark: PlayerMarker) {
        self.location = location
        self.mark = mark
    }
}

@frozen
public enum GameEventValue: Sendable, Codable, CustomStringConvertible {
    case square3(GameEvent<GridWinningLine, GridLocation>)
    case cube4(GameEvent<CubeFourWinningLine, CubeFourLocation>)

    public var description: String {
        switch self {
        case .square3(let gameEvent):
            gameEvent.description
        case .cube4(let gameEvent):
            gameEvent.description
        }
    }
}

public enum GameEvent<WinningLine: WinningLineProtocol, GameboardLocation: GameboardLocationProtocol>: Sendable, Codable, CustomStringConvertible {
    case move(GameMove<GameboardLocation>)
    case undo(GameboardLocation)
    case gameOver(WinningInfo<WinningLine>?)
    case reset

    public var description: String {
        switch self {
        case .move(let gameMove):
            "move: \(gameMove)"
        case .undo(let gameMove):
            "undo: \(gameMove)"
        case .gameOver:
            "gameOver"
        case .reset:
            "reset"
        }
    }
}

public struct GameStateUpdate<WinningLine: WinningLineProtocol, GameboardLocation: GameboardLocationProtocol>: Hashable, Sendable, Codable {
    public let id: UUID
    public let event: GameEvent<WinningLine, GameboardLocation>
    public let currentTurn: PlayerMarker?

    init(event: GameEvent<WinningLine, GameboardLocation>, currentTurn: PlayerMarker?) {
        self.id = UUID()
        self.event = event
        self.currentTurn = currentTurn
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
