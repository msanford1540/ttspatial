//
//  GameSessionValue.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 7/26/24.
//

import Combine
import TicTacToeEngine

public enum GameSessionValue {
    case square3(GameSession<GridGameboard>)
    case cube4(GameSession<CubeFourGameboard>)
}

public enum GameLocationValue {
    case square3(GridLocation)
    case cube4(CubeFourLocation)
}

@MainActor
public extension GameSessionValue {
    var xPlayerType: PlayerType {
        switch self {
        case .square3(let gameSession): gameSession.xPlayerType
        case .cube4(let gameSession): gameSession.xPlayerType
        }
    }

    var oPlayerType: PlayerType {
        switch self {
        case .square3(let gameSession): gameSession.oPlayerType
        case .cube4(let gameSession): gameSession.oPlayerType
        }
    }

    func setSnapshot<Snapshot: GameboardSnapshotProtocol>(_ snapshot: Snapshot) {
        switch self {
        case .square3(let gameSession):
            guard let gameSnapshot = snapshot as? GridGameboardSnapshot else {
                assertionFailure("gameboard/snapshot type mismatch")
                return
            }
            gameSession.setSnapshot(gameSnapshot)
        case .cube4(let gameSession):
            guard let gameSnapshot = snapshot as? CubeFourGameboardSnapshot else {
                assertionFailure("gameboard/snapshot type mismatch")
                return
            }
            gameSession.setSnapshot(gameSnapshot)
        }
    }

    var isHumanVersusBot: Bool {
        switch self {
        case .square3(let gameSession):
            gameSession.isHumanVersusBot
        case .cube4(let gameSession):
            gameSession.isHumanVersusBot
        }
    }

    var isRemoteGame: Bool {
        switch self {
        case .square3(let gameSession):
            gameSession.isRemoteGame
        case .cube4(let gameSession):
            gameSession.isRemoteGame
        }
    }

    var isGameOverPublisher: Published<Bool>.Publisher {
        switch self {
        case .square3(let gameSession):
            gameSession.$isGameOver
        case .cube4(let gameSession):
            gameSession.$isGameOver
        }
    }
}

@MainActor
extension GameSessionValue {
    var isHumanTurn: Bool {
        switch self {
        case .square3(let gameSession):
            gameSession.isHumanTurn
        case .cube4(let gameSession):
            gameSession.isHumanTurn
        }
    }

    func setHumanPlayer(_ mark: PlayerMarker) {
        switch self {
        case .square3(let gameSession):
            gameSession.setHumanPlayer(mark)
        case .cube4(let gameSession):
            gameSession.setHumanPlayer(mark)
        }
    }

    func setRemotePlayer(_ mark: PlayerMarker) {
        switch self {
        case .square3(let gameSession):
            gameSession.setRemotePlayer(mark)
        case .cube4(let gameSession):
            gameSession.setRemotePlayer(mark)
        }
    }

    func startNewRemoteGameIfNeeded() {
        switch self {
        case .square3(let gameSession):
            gameSession.startNewRemoteGameIfNeeded()
        case .cube4(let gameSession):
            gameSession.startNewRemoteGameIfNeeded()
        }
    }

    func reset(startingPlayer: PlayerMarker? = nil) {
        switch self {
        case .square3(let gameSession):
            gameSession.reset(startingPlayer: startingPlayer)
        case .cube4(let gameSession):
            gameSession.reset(startingPlayer: startingPlayer)
        }
    }

    func mark(at location: any GameboardLocationProtocol) async {
        switch self {
        case .square3(let gameSession):
            guard let gameboardLocation = location as? GridLocation else { return }
            await gameSession.mark(at: gameboardLocation)
        case .cube4(let gameSession):
            guard let gameboardLocation = location as? CubeFourLocation else { return }
            await gameSession.mark(at: gameboardLocation)
        }
    }
}
