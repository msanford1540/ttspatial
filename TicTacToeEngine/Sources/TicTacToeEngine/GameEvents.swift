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

@frozen
public enum GameMessageType<Snapshot: GameboardSnapshotProtocol>: Codable, Sendable, CustomStringConvertible {
    case snapshot(Snapshot)
    case move(GameMove<Snapshot.Location>)
}

public extension GameMessageType {
    var description: String {
        switch self {
        case .snapshot(let gameSnapshot): "(snapshot: \(gameSnapshot))"
        case .move(let gameMove): "(move: \(gameMove))"
        }
    }
}

public struct Handshake: Sendable, Codable, CustomStringConvertible {
    let participantID: UUID
    let timestamp: Date

    public init(participantID: UUID) {
        self.participantID = participantID
        self.timestamp = .now
    }

    public var description: String {
        "participantID: \(participantID)), timestamp: \(timestamp)"
    }
}

public struct GameMessage<Snapshot: GameboardSnapshotProtocol>: Sendable, Codable {
    let id: UUID
    let type: GameMessageType<Snapshot>
}

public struct GameMove<GameboardLocation: GameboardLocationProtocol>: Sendable, Codable, CustomStringConvertible {
    public let location: GameboardLocation
    public let mark: PlayerMarker

    public init(location: GameboardLocation, mark: PlayerMarker) {
        self.location = location
        self.mark = mark
    }

    public var description: String {
        "player: \(mark), location: \(location)"
    }
}

@frozen
public enum GameEventValue: Sendable, Codable, CustomStringConvertible {
    case grid3(GameEvent<Grid3Gameboard>)
    case cube4(GameEvent<Cube4Gameboard>)

    public var description: String {
        switch self {
        case .grid3(let gameEvent):
            gameEvent.description
        case .cube4(let gameEvent):
            gameEvent.description
        }
    }
}

public enum GameEvent<Gameboard: GameboardProtocol>: Sendable, Codable, CustomStringConvertible {
    case move(GameMove<Gameboard.Location>)
    case undo(GameMove<Gameboard.Location>)
    case gameOver(WinningInfo<Gameboard.WinningLine>?)
    case reset(Gameboard?)

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

public struct GameStateUpdate<Gameboard: GameboardProtocol>: Hashable, Sendable, Codable {
    public let id: UUID
    public let event: GameEvent<Gameboard>
    public let currentTurn: PlayerMarker?

    init(event: GameEvent<Gameboard>, currentTurn: PlayerMarker?) {
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

public struct GameOverInfo<WinningLine: WinningLineProtocol>: Equatable, Sendable, CustomStringConvertible {
    public let isGameOver: Bool
    public let winningInfo: WinningInfo<WinningLine>?

    public init(isGameOver: Bool, winningInfo: WinningInfo<WinningLine>?) {
        self.isGameOver = isGameOver
        self.winningInfo = winningInfo
    }

    public var description: String {
        "isGameOver: \(isGameOver), winningInfo: \(winningInfo.map(\.description) ?? .nil)"
    }
}
