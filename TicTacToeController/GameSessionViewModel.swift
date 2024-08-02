//
//  GameSessionViewModel.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 7/26/24.
//

import Combine
import TicTacToeEngine

@frozen
public enum GameOverState {
    case won
    case lost
    case tie
}

public struct GameMoveValue {
    public let mark: PlayerMarker
    public let location: GameLocationValue
}

@MainActor
public final class GameSessionViewModel: ObservableObject {
    @Published public private(set) var gameSession: GameSessionValue?

    @Published public private(set) var isGameSessionActive: Bool = false
    @Published public private(set) var isGameOver: Bool = false
    @Published public private(set) var currentTurn: PlayerMarker?
    @Published public private(set) var xPlayerName: String = .empty
    @Published public private(set) var oPlayerName: String = .empty
    @Published public private(set) var xWinCount: Int = .zero
    @Published public private(set) var oWinCount: Int = .zero
    @Published public private(set) var gameOverState: GameOverState?
    @Published public private(set) var canUndo: Bool = false
    @Published public private(set) var canReplay: Bool = false
    private var gameSubscribers: Set<AnyCancellable> = .empty

    func playGame(dimensions: GameboardDimensions, xPlayerType: PlayerType, oPlayerType: PlayerType) {
        switch dimensions {
        case .grid3:
            let rawGameSession = GameSession<Grid3Gameboard>(xPlayerType: xPlayerType, oPlayerType: oPlayerType)
            gameSession = .grid3(rawGameSession)
            setupPipelines(rawGameSession)
        case .cube4:
            let rawGameSession = GameSession<Cube4Gameboard>(xPlayerType: xPlayerType, oPlayerType: oPlayerType)
            gameSession = .cube4(rawGameSession)
            setupPipelines(rawGameSession)
        }
        isGameSessionActive = true
    }

    public var gameStatusText: String {
        return switch gameOverState {
        case .won:
            "You Won!!!"
        case .lost:
            "You lost"
        case .tie:
            "Tie Game"
        case nil:
            .empty
        }
    }

    public func undoLastHumanMove() {
        switch gameSession {
        case .grid3(let gameSession):
            gameSession.undoLastHumanMove()
        case .cube4(let gameSession):
            gameSession.undoLastHumanMove()
        case nil:
            break
        }
    }

    public var mostRecentMove: GameMoveValue? {
        switch gameSession {
        case .grid3(let gameSession):
            guard let move = gameSession.mostRecentMove else { return nil }
            return .init(mark: move.mark, location: .grid3(move.location))
        case .cube4(let gameSession):
            guard let move = gameSession.mostRecentMove else { return nil }
            return .init(mark: move.mark, location: .cube4(move.location))
        case nil:
            return nil
        }
    }

    public var currentPlayerHint: (any GameboardLocationProtocol)? {
        switch gameSession {
        case .grid3(let gameSession):
            gameSession.currentPlayerHint
        case .cube4(let gameSession):
            gameSession.currentPlayerHint
        case nil:
            nil
        }
    }

    public func dequeueEvent() -> GameEventValue? {
        switch gameSession {
        case nil:
            nil
        case .grid3(let gameSession):
            if let event = gameSession.dequeueEvent() {
                .grid3(event)
            } else {
                nil
            }
        case .cube4(let gameSession):
            if let event = gameSession.dequeueEvent() {
                .cube4(event)
            } else {
                nil
            }
        }
    }

    public func onCompletedEvent() {
        switch gameSession {
        case .grid3(let gameSession):
            gameSession.onCompletedEvent()
        case .cube4(let gameSession):
            gameSession.onCompletedEvent()
        case nil:
            break
        }
    }

    private func setupPipelines<Gameboard: GameboardProtocol>(_ gameSession: GameSession<Gameboard>) {
        gameSubscribers = .empty

        gameSession.$currentTurn
            .sink { [unowned self] in currentTurn = $0 }
            .store(in: &gameSubscribers)

        gameSession.$xPlayerName
            .sink { [unowned self] in xPlayerName = $0 }
            .store(in: &gameSubscribers)

        gameSession.$oPlayerName
            .sink { [unowned self] in oPlayerName = $0 }
            .store(in: &gameSubscribers)

        gameSession.$xWinCount
            .sink { [unowned self] in xWinCount = $0 }
            .store(in: &gameSubscribers)

        gameSession.$oWinCount
            .sink { [unowned self] in oWinCount = $0 }
            .store(in: &gameSubscribers)

        gameSession.$canUndo
            .sink { [unowned self] in canUndo = $0 }
            .store(in: &gameSubscribers)

        gameSession.$canReplay
            .sink { [unowned self] in canReplay = $0 }
            .store(in: &gameSubscribers)

        gameSession.$isGameOver
            .sink { [unowned self] in isGameOver = $0 }
            .store(in: &gameSubscribers)

        $isGameOver
            .sink { [unowned self] isGameOver in
                gameOverState = if isGameOver, let myself = gameSession.humanPlayer {
                    if let winningPlayer = gameSession.winningPlayer {
                        winningPlayer == myself ? .won : .lost
                    } else {
                        .tie
                    }
                } else {
                    nil
                }
            }
            .store(in: &gameSubscribers)
    }

    public func endGameSession() {
        gameSession = nil
        gameSubscribers = .empty
        currentTurn = nil
        xPlayerName = .empty
        oPlayerName = .empty
        xWinCount = .zero
        oWinCount = .zero
        isGameSessionActive = false
    }

    public func startNewGame() {
        gameSession?.reset()
    }
}
