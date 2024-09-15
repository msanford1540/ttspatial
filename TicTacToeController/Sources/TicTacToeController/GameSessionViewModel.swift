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

    private func startGameSession<Gameboard: GameboardProtocol>(_ gameSession: GameSession<Gameboard>) {
        switch gameSession {
        case let grid3GameSession as GameSession<Grid3Gameboard>:
            self.gameSession = .grid3(grid3GameSession)
        case let cube4GameSession as GameSession<Cube4Gameboard>:
            self.gameSession = .cube4(cube4GameSession)
        default:
            fatalError("invalid game session type")
        }
        setupPipelines(gameSession)
        isGameSessionActive = true
    }

    func playGame(dimensions: GameboardDimensions, xPlayerType: PlayerType, oPlayerType: PlayerType) {
        switch dimensions {
        case .grid3:
            let grid3GameSession = GameSession<Grid3Gameboard>(xPlayerType: xPlayerType, oPlayerType: oPlayerType)
            startGameSession(grid3GameSession)
        case .cube4:
            let cube4GameSession = GameSession<Cube4Gameboard>(xPlayerType: xPlayerType, oPlayerType: oPlayerType)
            startGameSession(cube4GameSession)
        }
    }

    func showGame<Snapshot: GameboardSnapshotProtocol>(snapshot: Snapshot, xPlayerType: PlayerType, oPlayerType: PlayerType) {
        switch snapshot {
        case let grid3Snapshot as Grid3GameboardSnapshot:
            let grid3GameSession = GameSession<Grid3Gameboard>(xPlayerType: xPlayerType, oPlayerType: oPlayerType, snapshot: grid3Snapshot)
            startGameSession(grid3GameSession)
#if DEBUG
            grid3GameSession.allowUndoAndReplay()
#endif
        case let cube4Snapshot as Cube4GameboardSnapshot:
            let cube4GameSession = GameSession<Cube4Gameboard>(xPlayerType: xPlayerType, oPlayerType: oPlayerType, snapshot: cube4Snapshot)
            startGameSession(cube4GameSession)
#if DEBUG
            cube4GameSession.allowUndoAndReplay()
#endif
        default:
            fatalError("invalid snapshot type")
        }
    }

#if DEBUG
    func showGame(for screenshot: Screenshot) {
        switch screenshot {
        case .grid3Game:
            let snapshot = Grid3GameboardSnapshot(
                markers: [
                    .init(.bottom, .left): .x,
                    .init(.middle, .middle): .x,
                    .init(.middle, .right): .o,
                    .init(.top, .right): .o
                ],
                currentTurn: .x
            )
            showGame(snapshot: snapshot, xPlayerType: .human, oPlayerType: .bot(.medium))
        case .cube4Game:
            let snapshot = Cube4GameboardSnapshot(
                markers: [
                    .init(.bottom, .left, .front): .x,
                    .init(.bottom, .left, .middleFront): .x,
                    .init(.bottom, .left, .back): .x,
                    .init(.top, .right, .front): .x,
                    .init(.middleTop, .middleRight, .front): .o,
                    .init(.middleBottom, .middleLeft, .front): .o,
                    .init(.middleTop, .middleRight, .middleFront): .o,
                    .init(.bottom, .right, .front): .o
                ],
                currentTurn: .x
            )
            showGame(snapshot: snapshot, xPlayerType: .human, oPlayerType: .bot(.medium))
        default:
            break
        }
        xWinCount = 1
        oWinCount = 2
    }
#endif

    public var gameStatusText: String {
        return switch gameOverState {
        case .won:
            Localized.GameStatus.won
        case .lost:
            Localized.GameStatus.lost
        case .tie:
            Localized.GameStatus.tie
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
