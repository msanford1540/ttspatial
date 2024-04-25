//
//  GameSession.swift
//  TicTacSpatialCore
//
//  Created by Mike Sanford (1540) on 4/8/24.
//

import Foundation
import Combine

@MainActor
public class GameSession: ObservableObject {
    enum Player: CustomStringConvertible {
        case bot(GameBotProtocol)
        case remote
        case human

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
    @Published public private(set) var eventID: UUID = .init()
    @Published public private(set) var currentTurn: PlayerMarker?
    @Published public private(set) var xPlayerName: String = .empty
    @Published public private(set) var oPlayerName: String = .empty
    private var pendingGameEvent: GameEvent?
    public private(set) var oppononetName: String = "Bot"

    private var queue = Queue<GameStateUpdate>()
    private var gameEngine: GameEngine
    private var startingPlayer: PlayerMarker = .x
    @Published private var xPlayer: Player = .human
    @Published private var oPlayer: Player = .bot(EasyBot())

    public init() {
        gameEngine = GameEngine(startingPlayer: startingPlayer)
        startNewGame()
        setupPipelines()
    }

    private func setupPipelines() {
        $xPlayer
            .map { [unowned self] player in playerName(for: player) }
            .assign(to: &$xPlayerName)

        $oPlayer
            .map { [unowned self] player in playerName(for: player) }
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

    private func playerName(for player: Player) -> String {
        switch player {
        case .bot(let bot): bot.name
        case .remote: "Friend"
        case .human: "me"
        }
    }

    public var snapshot: GameSnapshot {
        get async {
            await gameEngine.snapshot
        }
    }

    public var isHumanTurn: Bool {
        guard let currentTurn else { return false }
        return player(for: currentTurn).isHuman
    }

    /// Only called from a human Player
    public func mark(at location: GridLocation) {
        Task {
            guard let currentTurn = await gameEngine.currentTurn, player(for: currentTurn).isHuman else { return }
            print("[debug]", "xPlayer: \(xPlayer), oPlayer: \(oPlayer)")
            await gameEngine.mark(at: location)
            await performBotMoveIfNeeded()
        }
    }

    private func player(for mark: PlayerMarker) -> Player {
        switch mark {
        case .x: xPlayer
        case .o: oPlayer
        }
    }

    private func performBotMoveIfNeeded() async {
        let snapshot = await gameEngine.snapshot
        guard let currentTurn = snapshot.currentTurn,
              case .bot(let bot) = player(for: currentTurn),
              let moveLocation = bot.move(for: snapshot) else { return }
        try? await Task.sleep(for: .seconds(1))
        await gameEngine.mark(at: moveLocation)
    }

    public func handleMessage(_ message: GameMessageType) {
        switch message {
        case .snapshot(let gameSnapshot):
            gameEngine = .init(gameSnapshot: gameSnapshot)
            startNewGame()
        case .move(let gameMove):
            Task {
                await gameEngine.mark(at: gameMove.location)
            }
        }
    }

    public func reset() {
        startingPlayer = startingPlayer.opponent
        gameEngine = GameEngine(startingPlayer: startingPlayer)
        startNewGame()
    }

    private func startNewGame() {
        observeGameEngineUpdates()
        Task {
            await performBotMoveIfNeeded()
        }
    }

    public func dequeueEvent() -> GameEvent? {
        guard let pendingGameEvent else { return nil }
        self.pendingGameEvent = nil
        return pendingGameEvent
    }

    public func onCompletedEvent() {
        assert(pendingGameEvent == nil)
        guard let nextUpdate = queue.dequeue() else { return }
        updateGameState(with: nextUpdate)
    }

    private func onGameStateUpdate(_ update: GameStateUpdate) {
        if pendingGameEvent == nil {
            updateGameState(with: update)
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

    private func updateGameState(with update: GameStateUpdate) {
        eventID = update.id
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
    var winningInfo: WinningInfo? {
        switch self {
        case .move, .undo, .reset: nil
        case .gameOver(let winningInfo): winningInfo
        }
    }
}
