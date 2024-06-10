//
//  GameSession.swift
//  TicTacSpatialCore
//
//  Created by Mike Sanford (1540) on 4/8/24.
//

import Foundation
import Combine

@frozen
public enum PlayerType {
    case bot(BotType)
    case remote
    case human
}

@MainActor
public final class GameSession<Gameboard: GameboardProtocol>: ObservableObject {
    enum Player {
        case bot(BaseBot<Gameboard.Snapshot>)
        case remote
        case human

        init(playerType: PlayerType) {
            self = switch playerType {
            case .bot: .bot(EasyBot<Gameboard.Snapshot>())
            case .remote: .remote
            case .human: .human
            }
        }

        var isHuman: Bool {
            if case .human = self { true } else { false }
        }

        var description: String {
            switch self {
            case .bot: "bot"
            case .remote: "remote"
            case .human: "human"
            }
        }
    }

    @Published public private(set) var xWinCount: Int = 0
    @Published public private(set) var oWinCount: Int = 0
    @Published public private(set) var xPlayerName: String = .empty
    @Published public private(set) var oPlayerName: String = .empty
    @Published public private(set) var processingEventID: UUID?
    @Published public private(set) var currentTurn: PlayerMarker?
    private var pendingGameEvent: GameEvent<Gameboard.WinningLine, Gameboard.Location>?

    private var queue = Queue<GameStateUpdate<Gameboard.WinningLine, Gameboard.Location>>()
    private var gameEngine: GameEngine<Gameboard>
    private var startingPlayer: PlayerMarker = .x
    @Published private var xPlayer: Player
    @Published private var oPlayer: Player

    public init(xPlayerType: PlayerType, oPlayerType: PlayerType) {
        xPlayer = Player(playerType: xPlayerType)
        oPlayer = Player(playerType: oPlayerType)
        currentTurn = startingPlayer
        gameEngine = GameEngine(gameboard: Gameboard(), startingPlayer: startingPlayer)
        setupPipelines()
        startNewGame()
    }

    private func setupPipelines() {
        $xPlayer
            .map(\.playerName)
            .assign(to: &$xPlayerName)
        $oPlayer
            .map(\.playerName)
            .assign(to: &$oPlayerName)
    }

    public func setHumanPlayer(_ mark: PlayerMarker) {
        switch mark {
        case .x: xPlayer = .human
        case .o: oPlayer = .human
        }
    }

    public func setRemotePlayer(_ mark: PlayerMarker) {
        switch mark {
        case .x: xPlayer = .remote
        case .o: oPlayer = .remote
        }
    }

    public var snapshot: Gameboard.Snapshot {
        gameEngine.snapshot
    }

    public var isHumanTurn: Bool {
        guard let currentTurn else { return false }
        return player(for: currentTurn).isHuman
    }

    /// Only called from a human Player
    public func mark(at location: Gameboard.Location) async {
        guard let currentTurn = gameEngine.currentTurn, player(for: currentTurn).isHuman else { return }
        gameEngine.markCurrentPlayer(at: location)
        await performBotMoveIfNeeded()
    }

    private func player(for mark: PlayerMarker) -> Player {
        switch mark {
        case .x: xPlayer
        case .o: oPlayer
        }
    }

    private func performBotMoveIfNeeded() async {
        let snapshot = gameEngine.snapshot
        guard let currentTurn = snapshot.currentTurn,
              case .bot(let bot) = player(for: currentTurn),
              let moveLocation = bot.move(for: snapshot) else { return }
        try? await Task.sleep(for: .seconds(1))
        gameEngine.markCurrentPlayer(at: moveLocation)
    }

    public func handleMessage(_ message: GameMessageType<Gameboard.Snapshot>) {
        switch message {
        case .snapshot(let gameSnapshot):
            gameEngine = .init(snapshot: gameSnapshot)
            startNewGame()
        case .move(let gameMove):
            gameEngine.markCurrentPlayer(at: gameMove.location)
        }
    }

    public func reset() {
        startingPlayer = startingPlayer.opponent
        gameEngine = .init(gameboard: Gameboard(), startingPlayer: startingPlayer)
        startNewGame()
    }

    private func startNewGame() {
        observeGameEngineUpdates()
        Task {
            await performBotMoveIfNeeded()
        }
    }

    public func dequeueEvent() -> GameEvent<Gameboard.WinningLine, Gameboard.Location>? {
        guard let pendingGameEvent else { return nil }
        self.pendingGameEvent = nil
        return pendingGameEvent
    }

    public func onCompletedEvent() {
        assert(pendingGameEvent == nil)
        if let nextUpdate = queue.dequeue() {
            processGameState(with: nextUpdate)
        } else {
            processingEventID = nil
        }
    }

    private func onGameStateUpdate(_ update: GameStateUpdate<Gameboard.WinningLine, Gameboard.Location>) {
        if processingEventID == nil {
            processGameState(with: update)
        } else {
            queue.enqueue(update)
        }
    }

    private func observeGameEngineUpdates() {
        Task {
            for await update in gameEngine.updateStream {
                onGameStateUpdate(update)
            }
        }
    }

    private func processGameState(with update: GameStateUpdate<Gameboard.WinningLine, Gameboard.Location>) {
        processingEventID = update.id
        pendingGameEvent = update.event
        currentTurn = update.currentTurn

        if let winningPlayer = update.event.winningInfo?.player {
            switch winningPlayer {
            case .x: xWinCount += 1
            case .o: oWinCount += 1
            }
        }
    }
}

private extension GameEvent {
    var winningInfo: WinningInfo<WinningLine>? {
        switch self {
        case .move, .undo, .reset: nil
        case .gameOver(let winningInfo): winningInfo
        }
    }
}

private extension GameSession.Player {
    var playerName: String {
        switch self {
        case .bot(let bot): bot.name
        case .remote: "Friend"
        case .human: "Me"
        }
    }
}
