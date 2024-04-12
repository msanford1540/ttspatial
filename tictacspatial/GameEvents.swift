//
//  GameEvents.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 4/10/24.
//

import Foundation

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

struct GameStateUpdate: Hashable {
    private let id: UUID
    let event: GameEvent
    let currentTurn: PlayerMarker?

    init(_ event: GameEvent, _ currentTurn: PlayerMarker?) {
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
